#!/usr/bin/env python3
"""
Seed cliff-registry with new CLI/TUI candidates from GitHub.

End-to-end self-contained: search → evaluate → emit manifests into
apps/ → run lint → commit and push to main. The TUI's hotness algorithm
does the actual curation post-merge.

Design notes:
- One Search API call per run (OR'd query). With the recency filter,
  most runs return a small handful of repos and finish in seconds.
- The ledger is the source of truth for "what we've already looked at."
  Only TERMINAL verdicts (accepted, rejected) get recorded. Deferred
  candidates remain re-evaluable next run.
- See scripts/README.md for the ledger format and operator usage.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import subprocess
import sys
import tomllib
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


# Single OR-query covers ~95% of what the old five-query union did.
# The Search API accepts boolean OR between qualifiers like topic:.
SEARCH_QUERY = "topic:cli OR topic:tui OR topic:terminal"

# Minimal category-check terms. The hotness algorithm in cliff handles
# real curation; this list only catches things that are categorically
# wrong (not a CLI/TUI at all) so we don't pollute the registry index.
CATEGORY_DENY_TERMS = (
    "awesome list",
    "awesome-list",
    "boilerplate",
    "starter template",
    "agent skill",
    "mcp server",
    "prompt pack",
    "cookiecutter template",
)

CATEGORY_DENY_NAME_PATTERNS = (
    r"(^|/)awesome[-_]",
    r"(^|/)dotfiles?($|[-_])",
    r"(^|/)skills?($|[-_])",
)

# Phrases that strongly suggest "this is a library/framework, not a
# runnable app." We reject when the description LEADS with one of these
# (e.g. "A Python library for…"), but allow them mid-sentence so that
# "CLI for FooSDK" is not blocked.
LIBRARY_LEAD_TOKENS = (
    "library", "framework", "sdk", "toolkit", "crate", "package",
    "module", "bindings",
)

# Case-insensitive: descriptions where the LIBRARY/FRAMEWORK identity
# is stated outright. Catches "Rich is a Python library…", "A powerful
# little TUI framework", "Library for X", "Python toolkit for Y".
LIBRARY_LEAD_PATTERNS_CI = (
    r"^\s*\S+\s+is\s+(a|an|the)\s+[^.]{0,60}\b(" + "|".join(LIBRARY_LEAD_TOKENS) + r")\b",
    r"^\s*(a|an|the)\s+[^.]{0,60}\b(" + "|".join(LIBRARY_LEAD_TOKENS) + r")\b",
    r"^\s*(" + "|".join(LIBRARY_LEAD_TOKENS) + r")\s+(for|to)\b",
    r"^\s*(python|rust|go|golang|node|js|javascript|typescript|ruby|c\+\+)\s+("
        + "|".join(LIBRARY_LEAD_TOKENS) + r")\b",
    r"\bbindings?\s+for\b",
)

# Case-sensitive: "X components for ProperName" — catches "TUI
# components for Bubble Tea", "Style definitions for Foo". The capital
# letter on the target distinguishes "for Bubble Tea" (a project) from
# "for nice terminal layouts" (descriptive).
LIBRARY_LEAD_PATTERNS_CS = (
    r"^\s*\w+\s+(components?|primitives?|widgets?|helpers?|definitions?|utilities)\s+for\s+[A-Z]",
)


@dataclass
class Verdict:
    full_name: str
    decision: str  # "accepted" | "rejected" | "deferred"
    reason: str
    install_type: str = ""
    package: str = ""
    stars: int = 0
    language: str = ""
    description: str = ""
    html_url: str = ""
    default_branch: str = ""
    license_spdx: str = ""
    topics: list[str] = field(default_factory=list)


def collect_repos(
    min_stars: int,
    limit: int,
    pushed_since: str | None = None,
) -> list[dict[str, Any]]:
    """One paged search call against the OR'd query.

    Uses gh CLI (already authenticated in CI via GH_TOKEN). When
    pushed_since is set (YYYY-MM-DD), only repos pushed on or after that
    date are returned — the recency fast-path. Returns up to `limit` repos.
    """
    cmd = [
        "gh", "search", "repos", SEARCH_QUERY,
        "--limit", str(limit),
        "--sort", "stars",
        "--order", "desc",
        "--stars", f">={min_stars}",
        "--archived=false",
        "--include-forks=false",
        "--visibility", "public",
        "--json", "fullName,name,owner,url,description,stargazersCount,"
                  "language,createdAt,pushedAt,defaultBranch,license,"
                  "isArchived,isFork",
    ]
    if pushed_since:
        cmd += ["--updated", f">={pushed_since}"]

    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        err = proc.stderr.strip() or "gh search failed"
        if "rate limit" in err.lower() or "403" in err:
            print(f"warn: rate-limited on search; returning empty", file=sys.stderr)
            return []
        raise RuntimeError(err)

    items = json.loads(proc.stdout)
    out: list[dict[str, Any]] = []
    for item in items:
        if item.get("isArchived") or item.get("isFork"):
            continue
        if str(item.get("fullName", "")):
            out.append(item)
    return out


def looks_like_app(repo: dict[str, Any]) -> tuple[bool, str]:
    """Lightweight category check. Reject obvious non-apps; accept the rest.

    The bar is low on purpose — hotness in the TUI does the real curation.
    What we reject here is anything that is *categorically* not a runnable
    CLI/TUI: awesome-lists, libraries that describe themselves as such,
    AI agent meta-tooling, etc.
    """
    name = str(repo.get("name") or "")
    full = str(repo.get("fullName") or "").lower()
    desc = str(repo.get("description") or "")
    haystack = f"{full} {name} {desc}".lower()

    # Strip leading emoji/punctuation so library-lead patterns anchored
    # at ^ aren't fooled by descriptions like "✨ PTerm is a Go module…".
    desc_stripped = re.sub(r"^[^\w]+", "", desc)

    for term in CATEGORY_DENY_TERMS:
        if term in haystack:
            return False, f"category-deny:{term}"
    for pat in CATEGORY_DENY_NAME_PATTERNS:
        if re.search(pat, full, re.IGNORECASE):
            return False, f"name-pattern:{pat}"
    for pat in LIBRARY_LEAD_PATTERNS_CI:
        if re.search(pat, desc_stripped, re.IGNORECASE):
            return False, f"library-lead:{pat[:30]}"
    for pat in LIBRARY_LEAD_PATTERNS_CS:
        if re.search(pat, desc_stripped):
            return False, f"library-lead:{pat[:30]}"
    return True, ""


def suggest_install(repo: dict[str, Any]) -> tuple[str, str]:
    """Map repo language → install type + package string. 'unknown' is fine."""
    language = str(repo.get("language") or "").lower()
    full_name = str(repo.get("fullName") or "")
    name = str(repo.get("name") or "")
    if language == "go":
        return "go", f"github.com/{full_name}@latest"
    if language == "rust":
        return "cargo", name
    if language == "python":
        return "pipx", name
    if language in ("javascript", "typescript"):
        return "npm", name
    return "unknown", ""


_PACKAGE_CACHE: dict[tuple[str, str], bool] = {}


def package_published(install_type: str, package: str) -> bool:
    """HEAD-check the package registry. Cached. Conservative on errors."""
    if install_type == "go" or not package:
        return install_type == "go"
    key = (install_type, package.lower())
    if key in _PACKAGE_CACHE:
        return _PACKAGE_CACHE[key]
    urls = {
        "pipx": f"https://pypi.org/pypi/{package}/json",
        "npm": f"https://registry.npmjs.org/{package}",
        "cargo": f"https://crates.io/api/v1/crates/{package}",
    }
    url = urls.get(install_type)
    if not url:
        return False
    ok = False
    try:
        req = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(req, timeout=5.0) as resp:
            ok = 200 <= resp.status < 300
    except urllib.error.HTTPError as e:
        ok = 200 <= e.code < 300
    except Exception:
        ok = False
    _PACKAGE_CACHE[key] = ok
    return ok


def load_ledger(path: Path) -> tuple[dict[str, dict[str, Any]], str]:
    """Returns (entries, last_updated_at_iso). Entries keyed by full_name lower."""
    if not path.exists():
        return {}, ""
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        return {}, ""
    return raw.get("entries", {}) or {}, str(raw.get("updated_at") or "")


def write_ledger(path: Path, entries: dict[str, dict[str, Any]]) -> None:
    payload = {
        "version": 1,
        "updated_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "entries": entries,
    }
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def load_existing_homepages(apps_dir: Path) -> set[str]:
    """Pick up homepages already in the registry — belt and suspenders
    on top of the ledger."""
    homepages: set[str] = set()
    if not apps_dir.exists():
        return homepages
    for f in apps_dir.glob("*.toml"):
        try:
            data = tomllib.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        hp = str(data.get("homepage", "")).strip().lower()
        if hp:
            homepages.add(hp)
    return homepages


def slugify(name: str, owner: str, used: set[str]) -> str:
    base = re.sub(r"[^a-z0-9-]+", "-", name.lower()).strip("-") or "app"
    base = re.sub(r"-{2,}", "-", base)
    if base not in used:
        used.add(base)
        return base
    alt = re.sub(r"[^a-z0-9-]+", "-", f"{base}-{owner.lower()}").strip("-")
    if alt not in used:
        used.add(alt)
        return alt
    i = 2
    while f"{alt}-{i}" in used:
        i += 1
    final = f"{alt}-{i}"
    used.add(final)
    return final


def truncate_to_bytes(s: str, max_bytes: int = 120, ellipsis: str = "...") -> str:
    """Truncate s so its UTF-8 byte length is ≤ max_bytes.

    The registry lints `len(description)` in Go, which counts bytes,
    not runes. A description with even one emoji can pass a codepoint
    check but fail the byte check, so we must encode-truncate-decode.
    """
    if len(s.encode("utf-8")) <= max_bytes:
        return s
    budget = max_bytes - len(ellipsis.encode("utf-8"))
    encoded = s.encode("utf-8")[:budget]
    # Roll back into the start of any multibyte codepoint we may have
    # split. UTF-8 continuation bytes have the high bits 10xxxxxx.
    while encoded and (encoded[-1] & 0xC0) == 0x80:
        encoded = encoded[:-1]
    truncated = encoded.decode("utf-8", errors="ignore").rstrip(" .,;:-—")
    return truncated + ellipsis


def render_manifest(v: Verdict, slug: str) -> str:
    desc = v.description.replace('"', "'").replace("\n", " ").strip()
    desc = re.sub(r"\s+", " ", desc)
    desc = truncate_to_bytes(desc, 120)
    tags = sorted({t for t in v.topics if re.fullmatch(r"[a-z0-9-]+", t)})[:6]
    if "cli" not in tags and "tui" not in tags:
        tags.append("tui" if v.install_type == "go" and "tui" in v.description.lower() else "cli")
    tags_literal = ", ".join(f'"{t}"' for t in tags)
    license_line = f'license = "{v.license_spdx}"\n' if v.license_spdx else ""
    readme = f"https://raw.githubusercontent.com/{v.full_name}/{v.default_branch}/README.md"
    return (
        f'name = "{slug}"\n'
        f'description = "{desc}"\n'
        f'author = "{v.full_name.split("/")[0]}"\n'
        f'homepage = "{v.html_url}"\n'
        f'readme = "{readme}"\n'
        f"tags = [{tags_literal}]\n"
        f"{license_line}"
        "\n"
        "[[installs]]\n"
        f'type = "{v.install_type}"\n'
        f'package = "{v.package}"\n'
    )


def evaluate(
    repo: dict[str, Any],
    ledger: dict[str, dict[str, Any]],
    existing_homepages: set[str],
    verify_registry: bool,
) -> Verdict:
    full_name = str(repo.get("fullName") or "")
    full_lower = full_name.lower()
    homepage = str(repo.get("url") or "").strip()

    base = Verdict(
        full_name=full_name,
        decision="rejected",
        reason="",
        stars=int(repo.get("stargazersCount") or 0),
        language=str(repo.get("language") or ""),
        description=str(repo.get("description") or "").strip(),
        html_url=homepage,
        default_branch=str(repo.get("defaultBranch") or "main"),
        license_spdx=str((repo.get("license") or {}).get("key") or "").upper(),
        topics=[str(t).lower() for t in repo.get("topics") or []],
    )

    if full_lower in ledger:
        prev = ledger[full_lower]
        base.decision = "skipped"
        base.reason = f"in-ledger:{prev.get('decision', '?')}"
        return base

    if homepage and homepage.lower() in existing_homepages:
        base.decision = "skipped"
        base.reason = "already-in-registry"
        return base

    ok, why = looks_like_app(repo)
    if not ok:
        base.reason = why
        return base

    install_type, package = suggest_install(repo)
    base.install_type = install_type
    base.package = package

    if install_type == "unknown":
        base.reason = "no-install-mapping"
        return base

    if verify_registry and install_type != "go":
        if not package_published(install_type, package):
            base.reason = f"package-not-published:{install_type}:{package}"
            return base

    base.decision = "accepted"
    base.reason = "ok"
    return base


def run_lint(repo_root: Path) -> bool:
    """Shell out to `go run ./cmd/lint ./apps`. Returns True on pass."""
    proc = subprocess.run(
        ["go", "run", "./cmd/lint", "./apps"],
        cwd=repo_root, capture_output=True, text=True,
    )
    if proc.returncode != 0:
        sys.stdout.write(proc.stdout)
        sys.stderr.write(proc.stderr)
    return proc.returncode == 0


def git_commit_and_push(repo_root: Path, count: int, dry_push: bool = False) -> None:
    """Stage everything, commit with a generated message, push to main."""
    subprocess.run(["git", "add", "-A"], cwd=repo_root, check=True)
    msg = f"seed: {count} new app{'s' if count != 1 else ''} (auto)"
    subprocess.run(
        ["git", "-c", "user.name=cliff-seeder",
         "-c", "user.email=actions@github.com",
         "commit", "-m", msg],
        cwd=repo_root, check=True,
    )
    if dry_push:
        print(f"[dry-push] would: git push origin HEAD")
    else:
        subprocess.run(["git", "push", "origin", "HEAD"], cwd=repo_root, check=True)
    print(f"committed and pushed: {msg}")


def derive_pushed_since(ledger_updated_at: str, fallback_days: int = 365) -> str:
    """One day before the ledger's last update, in YYYY-MM-DD.

    Overlap is intentional: the ledger filter inside evaluate() catches
    anything we already saw, and an extra day of overlap protects
    against timezone edges and same-day double-runs.
    """
    if ledger_updated_at:
        try:
            ts = dt.datetime.fromisoformat(ledger_updated_at.replace("Z", "+00:00"))
            return (ts.date() - dt.timedelta(days=1)).isoformat()
        except ValueError:
            pass
    return (dt.date.today() - dt.timedelta(days=fallback_days)).isoformat()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--apps-dir", type=Path, default=Path("apps"))
    ap.add_argument("--ledger", type=Path, default=Path("scripts/seen-ledger.json"))
    ap.add_argument("--min-stars", type=int, default=20)
    ap.add_argument("--limit", type=int, default=200,
                    help="Max repos returned by the GitHub Search call.")
    ap.add_argument("--max-new", type=int, default=20,
                    help="Cap on new manifests emitted per run.")
    ap.add_argument("--no-verify-registry", dest="verify_registry",
                    action="store_false", default=True,
                    help="Skip HEAD-checking pipx/npm/cargo packages.")
    ap.add_argument("--commit", action="store_true",
                    help="Run lint; on green, git commit + push to main.")
    ap.add_argument("--dry-push", action="store_true",
                    help="With --commit: do everything except the final push.")
    ap.add_argument("--dry-run", action="store_true",
                    help="Print what would happen; touch nothing on disk.")
    ap.add_argument("--full-scan", action="store_true",
                    help="Ignore the recency fast-path; scan everything.")
    args = ap.parse_args()

    repo_root = args.apps_dir.resolve().parent
    ledger, ledger_updated_at = load_ledger(args.ledger)
    existing_homepages = load_existing_homepages(args.apps_dir)
    used_slugs = {p.stem for p in args.apps_dir.glob("*.toml")} if args.apps_dir.exists() else set()

    pushed_since = None if args.full_scan else derive_pushed_since(ledger_updated_at)

    print(f"ledger entries: {len(ledger)} (last updated {ledger_updated_at or 'never'})")
    print(f"existing apps: {len(existing_homepages)}")
    print(f"search since:  {pushed_since or 'unbounded'}")

    repos = collect_repos(args.min_stars, args.limit, pushed_since=pushed_since)
    print(f"repos returned: {len(repos)}")

    if not repos:
        print("nothing to evaluate; exiting clean")
        return 0

    verdicts: list[Verdict] = []
    accepted_count = 0
    for repo in repos:
        v = evaluate(repo, ledger, existing_homepages, args.verify_registry)
        if v.decision == "accepted" and accepted_count >= args.max_new:
            v.decision = "deferred"
            v.reason = "max-new-cap"
        if v.decision == "accepted":
            accepted_count += 1
        verdicts.append(v)

    counts: dict[str, int] = {}
    for v in verdicts:
        counts[v.decision] = counts.get(v.decision, 0) + 1
    print(f"verdicts: {counts}")

    accepted = [v for v in verdicts if v.decision == "accepted"]
    if not accepted:
        print("nothing accepted this run; exiting clean")
        return 0

    if args.dry_run:
        print(f"[dry-run] would emit {len(accepted)} manifests:")
        for v in accepted:
            slug = slugify(v.full_name.split("/")[-1], v.full_name.split("/")[0], set(used_slugs))
            print(f"  {slug:30s} ← {v.full_name} ({v.install_type})")
        return 0

    written: list[Path] = []
    for v in accepted:
        slug = slugify(v.full_name.split("/")[-1], v.full_name.split("/")[0], used_slugs)
        path = args.apps_dir / f"{slug}.toml"
        path.write_text(render_manifest(v, slug), encoding="utf-8")
        written.append(path)
    print(f"wrote {len(written)} manifests to {args.apps_dir}")

    if args.commit:
        if not run_lint(repo_root):
            print("lint failed; rolling back this run's manifests", file=sys.stderr)
            for p in written:
                p.unlink(missing_ok=True)
            return 1

    next_ledger = dict(ledger)
    today = dt.date.today().isoformat()
    for v in verdicts:
        if v.decision not in ("accepted", "rejected"):
            continue
        key = v.full_name.lower()
        next_ledger[key] = {
            "decision": v.decision,
            "reason": v.reason,
            "install_type": v.install_type,
            "first_seen": ledger.get(key, {}).get("first_seen", today),
            "last_seen": today,
        }
    write_ledger(args.ledger, next_ledger)

    if args.commit:
        git_commit_and_push(repo_root, len(written), dry_push=args.dry_push)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
