#!/usr/bin/env bash
# plastic — NES emulator with a Ratatui terminal UI
#
# Template 1 (scripted fake). Plastic actually renders NES game
# frames into the terminal. We render a recognizable side-scrolling
# platformer scene (ground, blocks, sky, score) — not lifted from
# any specific game's art, just the universal "this is a 2D
# platformer" composition.

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

prompt; type_line 'plastic platformer.nes'
beat
pause 0.3
clear

printf '\033[1;38;5;213m  plastic \033[0m\033[2m  NES · 60 fps · ?  help \033[0m\n'
printf '┌────────────────────────────────────────────────────────────────────────────┐\n'
printf '│ \033[1;38;5;226m  P1 000300         WORLD 1-1         TIME 281       LIVES 03  \033[0m         │\n'
printf '├────────────────────────────────────────────────────────────────────────────┤\n'
printf '│                                                                            │\n'
printf '│            \033[38;5;231m·   ·\033[0m         \033[38;5;231m·\033[0m                                            │\n'
printf '│                                                                            │\n'
printf '│                                                                            │\n'
printf '│                              \033[38;5;226m▒▒▒▒▒▒▒\033[0m                                  │\n'
printf '│                              \033[38;5;226m▒\033[0m   ?   \033[38;5;226m▒\033[0m                                  │\n'
printf '│                              \033[38;5;226m▒▒▒▒▒▒▒\033[0m                                  │\n'
printf '│                                                                            │\n'
printf '│                                                                            │\n'
printf '│                  \033[38;5;9m▓▓\033[0m                                          \033[38;5;46m▲\033[0m         │\n'
printf '│                  \033[38;5;9m▓▓\033[0m                                        \033[38;5;46m▲▲▲\033[0m        │\n'
printf '│   \033[38;5;208m▒▒▒\033[0m                                                                      │\n'
printf '│   \033[38;5;208m▒▒▒\033[0m                                                                      │\n'
printf '│ \033[38;5;94m▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\033[0m │\n'
printf '│ \033[38;5;58m░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░\033[0m │\n'
printf '└────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ←→ move    ↑ jump    z run    x action    p pause    f save state \033[0m\n'
pause 4.0

clear
