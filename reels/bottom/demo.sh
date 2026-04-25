#!/usr/bin/env bash
# bottom (btm) — process/system monitor
#
# Template 1 (scripted fake). We mirror the recognizable layout shape:
# CPU/RAM/net sparklines up top, process table below, and keyboard help.

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
pause 0.6

prompt; type_line 'btm'
beat
pause 0.4
clear

printf '\033[1;36m bottom 0.12  \033[0m\033[2m cpu | mem | net | proc | disk | temp \033[0m\n'
printf '┌─CPU───────────────────────────┬─Mem───────────────────────────┬─Net──────────┐\n'
printf '│ avg \033[38;5;83m42%%\033[0m  ▁▂▃▄▅▆▅▄▃▂▁▂▃▄▅ │ used \033[38;5;214m9.8G / 32G\033[0m  ▁▁▂▃▄▅▄▃▂ │ rx \033[38;5;81m1.2MB/s\033[0m │\n'
printf '│ p0  \033[38;5;83m57%%\033[0m  ▂▃▄▅▆▇▆▅▄▃▂▃▄▅▆ │ swap \033[38;5;214m0.8G / 8G\033[0m  ▁▁▁▂▂▃▂▂▁ │ tx \033[38;5;81m340KB/s\033[0m │\n'
printf '└───────────────────────────────┴───────────────────────────────┴──────────────┘\n'
printf '┌─Processes (sorted by CPU)──────────────────────────────────────────────────────┐\n'
printf '│ pid    name                 cpu%%   mem%%   read/s   write/s   state             │\n'
printf '│ 7421   chrome               24.6   12.3   1.2MB    420KB     Running           │\n'
printf '│ 913    wezterm              13.8    3.9   120KB     88KB     Sleeping          │\n'
printf '│ 2150   spotify              10.2    4.1    96KB    130KB     Running           │\n'
printf '│ 6611   node                 7.4     2.8   210KB     40KB     Running           │\n'
printf '│ 1880   syncthing            4.9     1.6   500KB     75KB     Idle              │\n'
printf '└─────────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m ? help   / search   t tree mode   s sort   k kill process   q quit \033[0m\n'
pause 4.0

clear
