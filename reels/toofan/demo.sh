#!/usr/bin/env bash
# toofan — lightning-fast typing TUI with live WPM and themes
#
# Template 1 (scripted fake). Hero shot: the prompt sentence with
# typed-vs-pending coloring and a live WPM counter. Static frame
# but instantly recognizable as "a typing tutor."

pause() { sleep "${1:-0.8}"; }
beat()  { sleep "${1:-0.3}"; }

type_line() {
  local s="$1" i
  for (( i=0; i<${#s}; i++ )); do
    printf '%s' "${s:$i:1}"
    sleep 0.03
  done
  printf '\n'
}

prompt() { printf '\033[2m$\033[0m '; }

clear
pause 0.5

prompt; type_line 'toofan'
beat
pause 0.3
clear

printf '\033[1;38;5;177m  toofan \033[0m\033[2m  typing test · 30s · words mode · ?  help \033[0m\n'
printf '\n'
printf '\n'
printf '   \033[38;5;46mthe\033[0m \033[38;5;46mquick\033[0m \033[38;5;46mbrown\033[0m \033[38;5;46mfox\033[0m \033[38;5;46mjumps\033[0m \033[38;5;226mover\033[0m\033[7m \033[0m\033[2mthe lazy dog and the\033[0m\n'
printf '   \033[2mfive boxing wizards jump quickly past the sleeping watchman.\033[0m\n'
printf '\n'
printf '\n'
printf '          \033[38;5;213mWPM\033[0m            \033[38;5;213mACC\033[0m            \033[38;5;213mTIME\033[0m\n'
printf '          \033[1;38;5;46m 87 \033[0m            \033[1;38;5;46m98%% \033[0m            \033[1;38;5;226m17s \033[0m\n'
printf '\n'
printf '\n'
printf '          \033[2m──────────────────────────────────────────\033[0m\n'
printf '          \033[2m   chars  142     errors  3     mode  words\033[0m\n'
printf '\n'
printf '\n'
printf '\n'
printf '\033[2m  tab restart    esc quit    \\  theme    ?  help \033[0m\n'
pause 4.0

clear
