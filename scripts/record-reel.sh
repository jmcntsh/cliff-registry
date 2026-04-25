#!/usr/bin/env bash
# record-reel.sh — turn reels/<slug>/demo.sh into reels/<slug>.reel.
#
# This is the lazy-genius driver for the "every app gets a short reel
# above its readme" goal. The interesting work — what the demo should
# actually show — lives in reels/<slug>/demo.sh, written by hand (or
# by an LLM with taste) per app. This script just feeds it to reel
# and writes the artifact next to the source.
#
# Usage:
#   scripts/record-reel.sh <slug>            # uses default 80x24
#   scripts/record-reel.sh <slug> 100x30     # explicit size override
#
# The size override exists for TUIs that don't lay out cleanly at
# 80x24. If the demo.sh has a size preference baked in (e.g. a
# # SIZE=100x30 comment we parse below), that wins over the default
# but loses to an explicit CLI arg.
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $(basename "$0") <slug> [WxH]" >&2
  exit 2
fi

slug="$1"
size_arg="${2:-}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
demo="$repo_root/reels/$slug/demo.sh"
out="$repo_root/reels/$slug.reel"

if [[ ! -f "$demo" ]]; then
  echo "no demo at $demo" >&2
  exit 1
fi

# Size resolution: explicit arg > "# SIZE=WxH" comment in demo.sh >
# 80x24 default. Reel requires explicit size in non-interactive mode
# (no host tty to inherit from). 80x24 matches reel's interactive
# default and is the README-friendly target — no horizontal scroll on
# desktop or mobile. The "# SIZE=" comment form keeps any per-app
# override next to the script that needs it, so re-recording doesn't
# require remembering a magic number.
size="80x24"
comment_size="$(grep -E '^# SIZE=' "$demo" 2>/dev/null | head -1 | sed -E 's/^# SIZE=//' || true)"
if [[ -n "$comment_size" ]]; then
  size="$comment_size"
fi
if [[ -n "$size_arg" ]]; then
  size="$size_arg"
fi

# Re-recording is the common case while iterating on a demo, so we
# remove any existing artifact rather than making the user run rm
# between attempts. The source of truth (demo.sh) is checked in;
# the .reel is regenerable, so clobbering is safe.
rm -f "$out"

reel_args=(--size "$size" --command "bash $demo" "$out")

if ! command -v reel >/dev/null 2>&1; then
  echo "reel not on PATH. Install with: go install github.com/jmcntsh/reel/cmd/reel@latest" >&2
  exit 1
fi

echo "recording $slug → $out${size:+ (size $size)}"
reel record "${reel_args[@]}"
echo "wrote $out"
