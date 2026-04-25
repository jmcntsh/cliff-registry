#!/usr/bin/env bash
# tetrigo — Tetris in your terminal (2009 design guideline)
#
# Template 1 (scripted fake). Mid-game frame: playfield with
# locked blocks, the active piece, hold + next previews, score.

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

prompt; type_line 'tetrigo'
beat
pause 0.3
clear

# Tetris brand colors: cyan I, yellow O, magenta T, green S, red Z, blue J, orange L.
printf '\033[1;38;5;213m  tetrigo \033[0m\033[2m  marathon · level 7 · 38 lines · ?  help \033[0m\n'
printf '\n'
printf '   \033[2mHOLD\033[0m         ┌────────────────────┐         \033[2mNEXT\033[0m\n'
printf '   ┌──────┐     │                    │         \033[38;5;46m■■\033[0m\n'
printf '   │ \033[38;5;226m■■\033[0m   │     │                    │         \033[38;5;46m■■\033[0m\n'
printf '   │ \033[38;5;226m■■\033[0m   │     │                    │\n'
printf '   │      │     │                    │         \033[38;5;208m■\033[0m\n'
printf '   └──────┘     │      \033[38;5;81m■■\033[0m            │         \033[38;5;208m■\033[0m\n'
printf '                │      \033[38;5;81m■■\033[0m            │         \033[38;5;208m■■\033[0m\n'
printf '   \033[2mSCORE\033[0m        │                    │\n'
printf '   \033[1;38;5;226m 18,420 \033[0m     │                    │         \033[38;5;177m■\033[0m\n'
printf '                │                    │         \033[38;5;177m■■\033[0m\n'
printf '   \033[2mLINES\033[0m        │                    │         \033[38;5;177m■\033[0m\n'
printf '   \033[1;38;5;46m   38   \033[0m     │  \033[38;5;177m■\033[0m         \033[38;5;9m■■■\033[0m \033[38;5;208m■\033[0m  │\n'
printf '                │  \033[38;5;177m■■■\033[0m \033[38;5;46m■■\033[0m \033[38;5;9m■\033[0m   \033[38;5;208m■■■\033[0m │\n'
printf '   \033[2mLEVEL\033[0m        │ \033[38;5;9m■\033[0m\033[38;5;177m■\033[0m  \033[38;5;226m■■\033[0m \033[38;5;46m■■■\033[0m \033[38;5;81m■■\033[0m \033[38;5;208m■\033[0m │\n'
printf '   \033[1;38;5;81m   7    \033[0m     │ \033[38;5;9m■■\033[0m \033[38;5;226m■■\033[0m \033[38;5;226m■■\033[0m \033[38;5;46m■\033[0m \033[38;5;177m■\033[0m \033[38;5;81m■■\033[0m  │\n'
printf '                └────────────────────┘\n'
printf '\033[2m  ←→ move    ↓ soft drop    space hard drop    ↑ rotate    c hold    p pause \033[0m\n'
pause 4.0

clear
