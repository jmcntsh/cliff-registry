#!/usr/bin/env bash
# vhs — write terminal GIFs as code
#
# Template 2 (real capture). Render an actual tape with real VHS.

pause() { sleep "${1:-0.6}"; }
prompt() { printf '\033[2m$\033[0m '; }

tmp="$(mktemp -d "/tmp/cliff-reel-vhs.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

cat >demo.tape <<'EOF'
Output demo.gif
Set Width 800
Set Height 300
Type "echo hello, vhs"
Enter
Sleep 1s
EOF

clear
pause
prompt; printf 'vhs demo.tape\n'
pause 0.3
vhs demo.tape 2>/dev/null
pause 4.2
clear
