#!/usr/bin/env bash
# superfile — pretty fancy and modern terminal file manager
#
# Template 2 (real capture). Run in a synthetic HOME/tree to avoid
# exposing recorder-specific filesystem paths.

# SIZE=100x30

tmp="$(mktemp -d "/tmp/cliff-reel-superfile.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME/projects/demo/reels" "$HOME/projects/demo/apps"
printf '# demo\n' > "$HOME/projects/demo/README.md"
printf 'name = "demo"\n' > "$HOME/projects/demo/apps/demo.toml"
cd "$HOME/projects/demo"

( sleep 8; kill -TERM $$ ) &
exec spf 2>/dev/null
