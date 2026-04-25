#!/usr/bin/env bash
# dooit — todo manager for the terminal
#
# Template 1 (scripted fake). Dooit's structure: workspaces on the
# left, hierarchical todos in the middle, with priorities, due
# dates, and progress bars. We render that.

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

prompt; type_line 'dooit'
beat
pause 0.3
clear

printf '\033[1;38;5;177m  dooit \033[0m\033[2m  workspaces · todos · journals · ?  help \033[0m\n'
printf '┌─Workspaces─────────┬─Todos───────────────────────────────────────────────────┐\n'
printf '│ ▾ Personal          │ ▾ \033[38;5;226m●\033[0m  cliff v0.2 launch                                 │\n'
printf '│   Inbox             │   ▾ \033[38;5;46m✓\033[0m  ship reel pipeline                              │\n'
printf '│ ▾ \033[7m Cliff             \033[0m │     • \033[38;5;46m✓\033[0m  pilot reels (glow, cava)                     │\n'
printf '│   Today             │     • \033[38;5;46m✓\033[0m  batch 1 (5 apps)                              │\n'
printf '│   This week         │     • \033[38;5;226m●\033[0m  batch 2 (5 installed apps)                   │\n'
printf '│   Roadmap           │     • \033[38;5;81m○\033[0m  batch 3 (32 fakes, all at once)              │\n'
printf '│ ▾ Reading list      │   ▸ \033[38;5;226m●\033[0m  client-side reel cache                         │\n'
printf '│                     │   ▸ \033[38;5;81m○\033[0m  CI: rsync reels/ to GitHub Pages              │\n'
printf '│                     │                                                       │\n'
printf '│                     │ \033[38;5;81m○\033[0m  due  Sat 4-25       \033[2m▰▰▰▰▰▰▰▰▱▱  78%%\033[0m              │\n'
printf '│                     │                                                       │\n'
printf '└─────────────────────┴───────────────────────────────────────────────────────┘\n'
printf '\033[2m  a add    A add child    space toggle    e edit    d delete    ?  help \033[0m\n'
pause 4.0

clear
