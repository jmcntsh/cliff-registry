#!/usr/bin/env bash
# glow — Render markdown on the CLI, with pizzazz
#
# Template 2 (real capture). Use the real binary on a tiny markdown
# file so viewers see actual glow rendering, not a simulation.

pause() { sleep "${1:-0.6}"; }
prompt() { printf '\033[2m$\033[0m '; }

tmp="$(mktemp -d "/tmp/cliff-reel-glow.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

cat >README.md <<'EOF'
# Glow

Render markdown on the CLI, with pizzazz.

- glow README.md
- glow -p
EOF

clear
pause
prompt; printf 'glow README.md\n'
pause 0.4
glow README.md 2>/dev/null | sed -n '1,24p'
pause 4.2
clear
