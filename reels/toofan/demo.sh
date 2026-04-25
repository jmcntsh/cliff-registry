#!/usr/bin/env bash
# toofan — lightning-fast typing TUI with live WPM and themes
#
# Template 2 (real capture). Run the real binary and show real flags.

pause() { sleep "${1:-0.6}"; }
prompt() { printf '\033[2m$\033[0m '; }

clear
pause
prompt; printf 'toofan -version\n'
pause 0.3
toofan -version 2>/dev/null
pause 0.7
prompt; printf 'toofan -help\n'
pause 0.3
toofan -help 2>/dev/null | sed -n '1,18p'
pause 3.4
clear
