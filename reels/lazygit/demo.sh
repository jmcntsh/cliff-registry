#!/usr/bin/env bash
# lazygit — simple terminal UI for git commands
#
# Template 2 (real TUI capture) in a synthetic repo so the reel shows
# realistic git state without exposing recorder-specific history.

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

for lazygit reel capture
EOF

git add README.md
git commit -q -m "init"

echo "change" >>README.md
git add README.md

echo "todo" >todo.txt

( sleep 8; kill -TERM $$ ) &
exec lazygit 2>/dev/null
