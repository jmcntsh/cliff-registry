#!/usr/bin/env python3
"""lint-reels.py — guardrails for the reels/ directory.

Fails (exit 1) if any of the following hold:
  - a `.reel` artifact contains tokens that would identify the recording
    machine (`/Users/`, `/var/folders/`, common username strings).
  - a Template 1 demo's recorded artifact is missing the centered
    `[disclaimer: ...]` opening card.
  - a Template 2 demo's recorded artifact still contains the disclaimer
    card (we removed the auto-injection for real captures, so this is a
    regression signal).
  - a slug has a demo.sh but no recorded `.reel`, or vice versa.

Run locally:    scripts/lint-reels.py
Run in CI:      same; non-zero exit fails the job.

The check is intentionally cheap (string-grep across compact JSON) rather
than running reel/decoding frames. Reels are stored as text JSON, so a
substring match is enough to catch leakage in op-text fields.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
REELS_DIR = REPO_ROOT / "reels"

# Tokens that should never appear in any committed `.reel`. We keep this
# list conservative on purpose — it's the recorder's responsibility to
# scrub at record time, but CI is the safety net if a sandbox slips.
LEAK_TOKENS = (
    "/Users/",
    "/var/folders/",
    # Common recorder-account hints. These are deliberately specific to
    # the current maintainer's environment; if the project gains other
    # recorders, extend this list rather than weaken it.
    "/home/jmc",
    "jmcntsh",
)

DISCLAIMER_TOKEN = "[disclaimer:"


def reel_text(path: Path) -> str:
    """Return all op `text` values concatenated, lowercased.

    We don't grep the raw bytes because the JSON envelope itself contains
    nothing user-specific, and concatenating extracted text avoids false
    positives on metadata fields (e.g. cursor positions encoded as
    numbers).
    """
    try:
        obj = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as e:
        return f"__PARSE_ERROR__:{e}"
    out: list[str] = []
    for frame in obj.get("frames", []) or []:
        for op in frame.get("ops") or []:
            t = op.get("text")
            if isinstance(t, str):
                out.append(t)
    return "\n".join(out)


def classify(demo_path: Path) -> str:
    """Return 'template1' / 'template2' / 'unknown' based on the marker
    comment we already use across all demo scripts.
    """
    try:
        body = demo_path.read_text()
    except OSError:
        return "unknown"
    if "Template 1" in body:
        return "template1"
    if "Template 2" in body:
        return "template2"
    return "unknown"


def main() -> int:
    if not REELS_DIR.is_dir():
        print(f"reels dir not found at {REELS_DIR}", file=sys.stderr)
        return 2

    demos = sorted(REELS_DIR.glob("*/demo.sh"))
    if not demos:
        print("no demo scripts found", file=sys.stderr)
        return 2

    errors: list[str] = []
    checked = 0

    for demo in demos:
        slug = demo.parent.name
        reel = REELS_DIR / f"{slug}.reel"
        if not reel.exists():
            errors.append(f"{slug}: demo.sh exists but reels/{slug}.reel is missing")
            continue
        checked += 1

        text = reel_text(reel)
        if text.startswith("__PARSE_ERROR__"):
            errors.append(f"{slug}: failed to parse reel ({text})")
            continue

        # Privacy: any leak token is a hard fail. We grep on the full
        # extracted text, which preserves case so we can match exact
        # path prefixes.
        for token in LEAK_TOKENS:
            if token in text:
                errors.append(
                    f"{slug}: leak token {token!r} found in reel artifact"
                )

        kind = classify(demo)
        has_disclaimer = DISCLAIMER_TOKEN in text.lower()

        if kind == "template1" and not has_disclaimer:
            errors.append(
                f"{slug}: Template 1 demo missing opening "
                f"'{DISCLAIMER_TOKEN}...]' card in recorded reel"
            )
        if kind == "template2" and has_disclaimer:
            # Real captures should not auto-inject the disclaimer. If
            # they do, either the recorder mis-classified or an old
            # artifact wasn't re-recorded after a Template flip.
            errors.append(
                f"{slug}: Template 2 demo unexpectedly contains the "
                f"'{DISCLAIMER_TOKEN}' card (re-record after template change?)"
            )
        if kind == "unknown":
            errors.append(
                f"{slug}: demo.sh has no Template 1 / Template 2 marker comment"
            )

    # Catch orphan reels (a `.reel` with no matching `demo.sh`). This
    # would happen if someone deletes a demo without re-publishing.
    demo_slugs = {d.parent.name for d in demos}
    for reel in sorted(REELS_DIR.glob("*.reel")):
        slug = reel.stem
        if slug not in demo_slugs:
            errors.append(f"{slug}: reel artifact exists but has no demo.sh source")

    if errors:
        print(f"lint-reels: {len(errors)} issue(s) across {checked} reels:")
        for e in errors:
            print(f"  - {e}")
        return 1

    print(f"lint-reels: ok ({checked} reels)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
