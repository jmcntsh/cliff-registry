#!/usr/bin/env bash
# setrixtui — falling-block puzzle where pieces turn to sand
#
# Template 1 (scripted fake). The hook is the moment a falling
# tetromino "settles" into colored sand at the bottom and same-
# colored regions clear. We render the field mid-fall, with sand
# already accumulated.

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

prompt; type_line 'setrixtui'
beat
pause 0.3
clear

printf '\033[1;38;5;213m setrixtui \033[0m\033[2m  sand-sweep · score  9,820 · ?  help \033[0m\n'
printf '\n'
printf '          ┌────────────────────────────────┐         \033[2mNEXT\033[0m\n'
printf '          │                                │         \033[38;5;81m■■\033[0m\n'
printf '          │           \033[38;5;226m■■\033[0m                   │         \033[38;5;81m■■\033[0m\n'
printf '          │           \033[38;5;226m■■\033[0m                   │\n'
printf '          │                                │         \033[2mLEVEL\033[0m\n'
printf '          │                                │         \033[1;38;5;46m  6\033[0m\n'
printf '          │                                │\n'
printf '          │                                │         \033[2mSCORE\033[0m\n'
printf '          │                                │         \033[1;38;5;226m 9,820\033[0m\n'
printf '          │     \033[38;5;9m▒\033[0m                          │\n'
printf '          │   \033[38;5;9m▒▒▒\033[0m   \033[38;5;46m░\033[0m         \033[38;5;177m▒\033[0m            │\n'
printf '          │  \033[38;5;9m▒▒▒▒\033[0m \033[38;5;46m░░░\033[0m  \033[38;5;81m▓▓\033[0m   \033[38;5;177m▒▒▒\033[0m         │\n'
printf '          │ \033[38;5;9m▒▒▒▒▒\033[0m \033[38;5;46m░░░░░\033[0m \033[38;5;81m▓▓▓▓\033[0m \033[38;5;177m▒▒▒▒\033[0m   \033[38;5;226m■\033[0m   │\n'
printf '          │\033[38;5;9m▒▒▒▒▒▒\033[0m \033[38;5;46m░░░░░░░\033[0m \033[38;5;81m▓▓▓▓▓\033[0m \033[38;5;177m▒▒▒▒▒\033[0m  \033[38;5;226m■■\033[0m │\n'
printf '          └────────────────────────────────┘\n'
printf '\033[2m  ←→ move    ↓ soft drop    ↑ rotate    space hard drop    p pause \033[0m\n'
pause 4.0

clear
