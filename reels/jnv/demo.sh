#!/usr/bin/env bash
# jnv — interactive JSON filter using jq
#
# Template 2 (real capture). Show the real tool's interactive purpose
# via help text and a sample invocation.

pause() { sleep "${1:-0.6}"; }
prompt() { printf '\033[2m$\033[0m '; }

clear
pause
prompt; printf 'jnv --help\n'
pause 0.3
jnv --help 2>/dev/null | sed -n '1,24p'
pause 4.2
clear
