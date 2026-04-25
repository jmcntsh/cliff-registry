#!/usr/bin/env bash
# serie — rich git commit graph in your terminal, like magic
#
# Template 2 (real capture). Show real serie output in a synthetic repo.

# SIZE=100x30

tmp="$(mktemp -d "/tmp/cliff-reel-serie.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q
git config user.name "Demo User"
git config user.email "demo@example.com"
printf '# demo\n' > README.md
git add README.md
git commit -q -m "init"
printf 'line 2\n' >> README.md
git commit -qam "update readme"
printf 'notes\n' > notes.txt
git add notes.txt
git commit -q -m "add notes"

( sleep 8; kill -TERM $$ ) &
exec serie 2>/dev/null
