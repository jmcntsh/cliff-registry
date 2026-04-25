#!/usr/bin/env bash
# rebels-in-the-sky — P2P terminal game about space pirates basketball
#
# Template 1 (scripted fake). Hero shot: team roster + a court
# diagram + a play-by-play feed. Static frame held for a few seconds.

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

prompt; type_line 'rebels-in-the-sky'
beat
pause 0.3
clear

printf '\033[1;38;5;213m  rebels in the sky \033[0m\033[2m  Sector 7 — Match · Q3 02:14 \033[0m\n'
printf '┌─Roster · Void Vipers ──────┬─Court──────────────┬─Roster · Nebula Knights ──┐\n'
printf '│  \033[38;5;213m1\033[0m  Z. Quill        \033[38;5;46m●\033[0m   │ ╭──────────────────╮ │  \033[38;5;81m1\033[0m  K. Starlight    \033[38;5;46m●\033[0m  │\n'
printf '│  \033[38;5;213m2\033[0m  R. Pulsar       \033[38;5;46m●\033[0m   │ │     \033[38;5;226m●\033[0m            │ │  \033[38;5;81m2\033[0m  L. Vega         \033[38;5;46m●\033[0m  │\n'
printf '│  \033[38;5;213m3\033[0m  V. Singh        \033[38;5;46m●\033[0m   │ │ \033[38;5;213m▲\033[0m       \033[38;5;81m▼\033[0m       │ │  \033[38;5;81m3\033[0m  C. Moon         \033[38;5;46m●\033[0m  │\n'
printf '│  \033[38;5;213m4\033[0m  T. Helix        \033[38;5;46m●\033[0m   │ │   \033[38;5;213m▲\033[0m   \033[38;5;81m▼\033[0m         │ │  \033[38;5;81m4\033[0m  M. Rilke        \033[38;5;46m●\033[0m  │\n'
printf '│  \033[38;5;213m5\033[0m  P. Nyx          \033[38;5;46m●\033[0m   │ │  \033[38;5;213m▲\033[0m       \033[38;5;81m▼\033[0m      │ │  \033[38;5;81m5\033[0m  J. Hex          \033[38;5;46m●\033[0m  │\n'
printf '│                            │ │      \033[38;5;213m▲\033[0m \033[38;5;81m▼\033[0m         │ │                           │\n'
printf '│  fuel  ▰▰▰▰▰▰▱▱  72%%      │ ╰──────────────────╯ │  fuel  ▰▰▰▰▰▱▱▱  64%%     │\n'
printf '└────────────────────────────┴────────────────────┴───────────────────────────┘\n'
printf '┌─Play-by-play───────────────────────────  Score \033[1;38;5;213m 58 \033[0m — \033[1;38;5;81m 54 \033[0m ──────────┐\n'
printf '│  Q3 02:14   Quill drives baseline, kicks out to Helix for three  \033[38;5;226m+3\033[0m         │\n'
printf '│  Q3 02:38   Vega misses the contested mid-range fade                          │\n'
printf '│  Q3 02:51   Singh blocks Hex at the rim, fast break                           │\n'
printf '│  Q3 03:02   Starlight nails the corner three  \033[38;5;81m+3\033[0m                            │\n'
printf '└──────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ↑↓ pick    ⏎ tactic    p pause    n network    q quit \033[0m\n'
pause 4.0

clear
