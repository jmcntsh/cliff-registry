#!/usr/bin/env python3
"""
Seed cliff-registry with new CLI/TUI candidates from GitHub.

Design goals:
- One script, one job, no matrix juggling.
- A persistent ledger of every repo we have ever evaluated, so weekly
  runs only do work on truly new candidates and we never re-litigate
  rejections via the rules file.
- Conservative API usage: search the topics we care about, sleep
  between calls, fail soft on rate limits rather than crashing the run.
- Hotness in the TUI does the curation. This script's job is to keep
  the funnel topped up with installable candidates that pass a basic
  category check and the registry's own lint.

Outputs (all under --out-dir, default /tmp/seed):
- candidates.json   — every repo evaluated this run, with verdict
- review.csv        — same data, spreadsheet-friendly
- manifests/        — new TOML manifests, ready to copy into apps/
- ledger.next.json  — proposed updated ledger (caller writes back)

The ledger format is documented in scripts/README.md.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import re
import subprocess
import sys
import time
import tomllib
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


INSTALL_TYPES = ("go", "cargo", "pipx", "npm")

# Search queries. Each one is one Search API call per page. Keep this
# list short — every entry costs against the 30 req/min Search quota.
QUERIES = (
    "topic:tui",
    "topic:cli",
    "topic:terminal",
    '"terminal ui" in:description',
    '"command line" cli in:description',
)

# Pause between Search API calls. The authenticated cap is 30/min;
# 2.5s = ~24 req/min, leaving headroom for retries.
SEARCH_CALL_INTERVAL_S = 2.5

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


def run_gh_search(query: str, min_stars: int, page_limit: int) -> list[dict[str, Any]]:
    """One paged search call. Returns up to page_limit repos.

    Uses gh CLI (already authenticated in CI via GH_TOKEN).
    """
    cmd = [
        "gh", "search", "repos", query,
        "--limit", str(page_limit),
        "--sort", "stars",
        "--order", "desc",
        "--stars", f">={min_stars}",
        "--archived=false",
        "--include-forks=false",
        "--visibility", "public",
        "--match", "name,description",
        "--json", "fullName,name,owner,url,description,stargazersCount,"
                  "language,createdAt,pushedAt,defaultBranch,license,"
                  "isArchived,isFork",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        err = proc.stderr.strip() or "gh search failed"
        # Rate-limit errors are recoverable; surface them but don't crash.
        if "rate limit" in err.lower() or "403" in err:
            print(f"warn: rate-limited on '{query}', skipping page", file=sys.stderr)
            return []
        raise RuntimeError(err)
    return json.loads(proc.stdout)


def collect_repos(min_stars: int, per_query: int) -> list[dict[str, Any]]:
    """Run all queries and dedupe by full_name."""
    seen: dict[str, dict[str, Any]] = {}
    for i, q in enumerate(QUERIES):
        if i > 0:
            time.sleep(SEARCH_CALL_INTERVAL_S)
        items = run_gh_search(q, min_stars, per_query)
        for item in items:
            key = str(item.get("fullName", "")).lower()
            if not key or item.get("isArchived") or item.get("isFork"):
                continue
            seen.setdefault(key, item)
    return list(seen.values())


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


def load_ledger(path: Path) -> dict[str, dict[str, Any]]:
    """Ledger is keyed by full_name (lowercase)."""
    if not path.exists():
        return {}
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        return {}
    return raw.get("entries", {}) or {}


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


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out-dir", type=Path, default=Path("/tmp/seed"))
    ap.add_argument("--apps-dir", type=Path, default=Path("apps"))
    ap.add_argument("--ledger", type=Path, default=Path("scripts/seen-ledger.json"))
    ap.add_argument("--min-stars", type=int, default=20,
                    help="Lower bound for the GitHub Search query.")
    ap.add_argument("--per-query", type=int, default=100,
                    help="Results per query (max 100 = single Search page).")
    ap.add_argument("--max-new", type=int, default=20,
                    help="Cap on new manifests emitted per run.")
    ap.add_argument("--verify-registry", action="store_true", default=True,
                    help="HEAD-check pipx/npm/cargo packages exist before emitting.")
    ap.add_argument("--no-verify-registry", dest="verify_registry", action="store_false")
    ap.add_argument("--dry-run", action="store_true",
                    help="Score and report only; do not write manifests or update ledger.")
    args = ap.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)
    manifests_dir = args.out_dir / "manifests"
    manifests_dir.mkdir(exist_ok=True)

    ledger = load_ledger(args.ledger)
    existing_homepages = load_existing_homepages(args.apps_dir)
    used_slugs = {p.stem for p in args.apps_dir.glob("*.toml")} if args.apps_dir.exists() else set()

    print(f"loaded ledger entries: {len(ledger)}")
    print(f"existing apps in registry: {len(existing_homepages)}")

    repos = collect_repos(args.min_stars, args.per_query)
    print(f"unique repos collected from search: {len(repos)}")

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

    # Emit manifests for accepted entries.
    emitted_slugs: list[str] = []
    if not args.dry_run:
        for v in verdicts:
            if v.decision != "accepted":
                continue
            slug = slugify(v.full_name.split("/")[-1], v.full_name.split("/")[0], used_slugs)
            (manifests_dir / f"{slug}.toml").write_text(render_manifest(v, slug), encoding="utf-8")
            emitted_slugs.append(slug)

    # Write candidates.json and review.csv.
    cand_path = args.out_dir / "candidates.json"
    cand_path.write_text(
        json.dumps([v.__dict__ for v in verdicts], indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    review_path = args.out_dir / "review.csv"
    with review_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=[
            "full_name", "decision", "reason", "install_type", "package",
            "stars", "language", "html_url", "description",
        ])
        w.writeheader()
        for v in verdicts:
            w.writerow({
                "full_name": v.full_name, "decision": v.decision, "reason": v.reason,
                "install_type": v.install_type, "package": v.package,
                "stars": v.stars, "language": v.language,
                "html_url": v.html_url, "description": v.description,
            })

    # Build the proposed next ledger. Only mark entries we *evaluated*
    # this run (skip-by-ledger entries are already there). Accepted
    # entries are recorded with their emitted slug for traceability.
    next_ledger = dict(ledger)
    today = dt.date.today().isoformat()
    for v in verdicts:
        key = v.full_name.lower()
        if v.decision == "skipped":
            continue
        next_ledger[key] = {
            "decision": v.decision,
            "reason": v.reason,
            "install_type": v.install_type,
            "first_seen": ledger.get(key, {}).get("first_seen", today),
            "last_seen": today,
        }

    next_ledger_path = args.out_dir / "ledger.next.json"
    write_ledger(next_ledger_path, next_ledger)

    if not args.dry_run:
        write_ledger(args.ledger, next_ledger)

    counts: dict[str, int] = {}
    for v in verdicts:
        counts[v.decision] = counts.get(v.decision, 0) + 1
    print(f"verdicts: {counts}")
    print(f"manifests emitted: {len(emitted_slugs)}")
    print(f"  → {manifests_dir}")
    print(f"review: {review_path}")
    print(f"ledger: {args.ledger if not args.dry_run else next_ledger_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
