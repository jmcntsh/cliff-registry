#!/usr/bin/env bash
# oxker — TUI for viewing and controlling Docker containers
#
# Template 1 (scripted fake). The hero view is: container list with
# state + cpu/mem, and a logs pane that streams. We mirror that.

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

prompt; type_line 'oxker'
beat
pause 0.3
clear

printf '\033[1;38;5;81m oxker \033[0m\033[2m  containers · logs · stats · ↑↓ select · ?  help \033[0m\n'
printf '┌─Containers──────────────────────────────────────────────────────────────────┐\n'
printf '│ \033[38;5;46m●\033[0m  cliff-registry-api    \033[38;5;46mUp 4h\033[0m     cpu \033[38;5;226m18%%\033[0m  mem  342 MB           │\n'
printf '│ \033[7m\033[38;5;46m●\033[0m  cliff-registry-pages  \033[38;5;46mUp 4h\033[0m     cpu  \033[38;5;46m4%%\033[0m  mem   88 MB         \033[0m │\n'
printf '│ \033[38;5;46m●\033[0m  postgres-15           \033[38;5;46mUp 2d\033[0m     cpu  \033[38;5;46m6%%\033[0m  mem  512 MB           │\n'
printf '│ \033[38;5;208m◐\033[0m  redis-cache           Restarting cpu  \033[38;5;46m0%%\033[0m  mem    0 MB           │\n'
printf '│ \033[38;5;9m●\033[0m  legacy-worker         Exited     cpu  \033[38;5;46m0%%\033[0m  mem    0 MB           │\n'
printf '└─────────────────────────────────────────────────────────────────────────────┘\n'
printf '┌─Logs · cliff-registry-pages ────────────────────────────────────────────────┐\n'
printf '│ \033[2m12:04:18\033[0m \033[38;5;46m INFO\033[0m  serving / from /usr/share/nginx/html                  │\n'
printf '│ \033[2m12:04:22\033[0m \033[38;5;46m INFO\033[0m  GET  /index.json     200  1.2KB    8ms                 │\n'
printf '│ \033[2m12:04:25\033[0m \033[38;5;46m INFO\033[0m  GET  /reels/glow.reel 200 14KB    11ms                 │\n'
printf '│ \033[2m12:04:28\033[0m \033[38;5;46m INFO\033[0m  GET  /reels/cava.reel 200  9KB     7ms                 │\n'
printf '│ \033[2m12:04:31\033[0m \033[38;5;226m WARN\033[0m  GET  /reels/missing  404           4ms                 │\n'
printf '└─────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ↑↓ navigate    s start    x stop    r restart    e exec    /  search \033[0m\n'
pause 4.0

clear
