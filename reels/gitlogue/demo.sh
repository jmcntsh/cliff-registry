#!/usr/bin/env bash
# gitlogue — cinematic git-history replay with typing animations
#
# Template 2 (real capture). Show real gitlogue output in a synthetic repo.

# SIZE=100x30

tmp="$(mktemp -d "/tmp/cliff-reel-gitlogue.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q
git config user.name "Demo User"
git config user.email "demo@example.com"
printf 'hello\n' > app.txt
git add app.txt
git commit -q -m "init"
printf 'hello world\n' > app.txt
git commit -qam "update text"

( sleep 8; kill -TERM $$ ) &
exec gitlogue 2>/dev/null
