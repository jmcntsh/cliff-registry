#!/usr/bin/env bash
# gitui — git GUI comfort in terminal
#
# Template 2 (real TUI capture) in a synthetic repo so we don't leak
# personal commit history, repo names, branches, or paths.

# SIZE=100x30

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
mkdir repo
cd repo

git init -q
git config user.name "Demo User"
git config user.email "demo@example.com"

cat >README.md <<'EOF'
# demo repo

for gitui reel capture
EOF

git add README.md
git commit -q -m "init"

echo "second line" >>README.md
git add README.md

echo "wip note" >notes.txt

( sleep 8; kill -TERM $$ ) &
exec gitui 2>/dev/null
