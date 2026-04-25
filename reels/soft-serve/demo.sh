#!/usr/bin/env bash
# soft-serve — self-hostable Git server with an SSH-accessible TUI
#
# Template 2 (real capture). Soft-serve is server software; for a
# deterministic privacy-safe demo we show real CLI help output.

pause() { sleep "${1:-0.6}"; }
prompt() { printf '\033[2m$\033[0m '; }

clear
pause
prompt; printf 'soft --help\n'
pause 0.3
soft --help 2>/dev/null | sed -n '1,24p'
pause 4.2
clear
