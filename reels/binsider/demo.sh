#!/usr/bin/env bash
# binsider — analyze ELF binaries in your terminal
#
# Template 2 (real capture). Use the real binary's real analysis output.

pause() { sleep "${1:-0.6}"; }
prompt() { printf '\033[2m$\033[0m '; }

clear
pause
prompt; printf 'binsider --help\n'
pause 0.3
binsider --help 2>/dev/null | sed -n '1,24p'
pause 4.2
clear
