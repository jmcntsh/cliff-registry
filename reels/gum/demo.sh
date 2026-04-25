#!/usr/bin/env bash
# gum — glamorous shell script primitives
#
# Template 2 (real capture). Show real gum primitives with canned input.

pause() { sleep "${1:-0.6}"; }
prompt() { printf '\033[2m$\033[0m '; }

clear
pause

prompt; printf 'gum style --foreground 212 "gum: glamorous shell primitives"\n'
pause 0.3
gum style --foreground 212 "gum: glamorous shell primitives" 2>/dev/null
pause 0.6

prompt; printf 'gum format --theme dracula "# gum\\n\\n- choose\\n- input\\n- confirm"\n'
pause 0.3
gum format --theme dracula "# gum\n\n- choose\n- input\n- confirm" 2>/dev/null
pause 3.4
clear
