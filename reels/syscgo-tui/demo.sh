#!/usr/bin/env bash
# syscgo-tui — interactive launcher for fire, matrix rain, fireworks, ...
#
# Template 1 (scripted fake). The launcher shows a menu of effects;
# the value prop is "one binary that aggregates a bunch of terminal
# eye candy." We render the menu + a frame of one of the effects
# ("matrix rain") to convey both the launcher and what it launches.

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

prompt; type_line 'syscgo-tui'
beat
pause 0.3
clear

printf '\033[1;38;5;46m syscgo-tui \033[0m\033[2m  pick a vibe · ↑↓ navigate · ⏎ run · q quit \033[0m\n'
printf '┌─────────────────────────────────────────────────────────────────────────────┐\n'
printf '│                                                                             │\n'
printf '│   \033[7m  matrix       \033[0m   green rain                                          │\n'
printf '│     fire           ANSI flame at the bottom of the screen                     │\n'
printf '│     fireworks      bursts on a black sky                                      │\n'
printf '│     starfield      3D-feeling parallax                                        │\n'
printf '│     plasma         shifting hue field                                         │\n'
printf '│     rain           neon droplets and pools                                    │\n'
printf '│                                                                             │\n'
printf '├─Preview · matrix────────────────────────────────────────────────────────────┤\n'
printf '│  \033[38;5;46m0 1 0  ⌷  ㄟ        7 ⌷ ㄗ      0 ⌷       ㄚ 1   ⌷ 0   ㄠ  1\033[0m         │\n'
printf '│  \033[38;5;46m  ⌷ 1 0    ㄒ 0 ⌷    1 ㄕ 0     ㄗ ⌷ 1     ⌷ 0       1 ㄚ\033[0m            │\n'
printf '│  \033[38;5;46m1 ㄎ 0 1    ⌷  0       ㄚ ⌷ 0     1 ㄠ ⌷    0 1     ⌷ ㄎ 0  ㄈ\033[0m       │\n'
printf '│  \033[38;5;46m 0 ⌷ 1 ㄗ    1 ⌷ ㄝ      ㄠ 0   1   ⌷ ㄒ      1 ⌷ 0    ㄍ 1\033[0m         │\n'
printf '│  \033[38;5;82m1 ⌷ 0  ㄟ      ⌷ 1 ㄈ   0 ⌷         ㄉ 0 ⌷    1 ㄔ 0       ⌷\033[0m         │\n'
printf '└─────────────────────────────────────────────────────────────────────────────┘\n'
pause 3.8

clear
