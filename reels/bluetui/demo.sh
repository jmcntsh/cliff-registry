#!/usr/bin/env bash
# bluetui — Bluetooth device manager in the terminal
#
# Template 1 (scripted fake). The hero shot is "list of nearby
# devices with battery / signal / paired state, and adapter info."
# We use placeholder device names so we never expose real nearby
# devices from the recorder's environment.

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

prompt; type_line 'bluetui'
beat
pause 0.3
clear

printf '\033[1;38;5;81m  bluetui \033[0m\033[2m  adapter: hci0 · powered · discoverable · scanning ◐ \033[0m\n'
printf '┌─Adapter─────────────────────────────────────────────────────────────────────┐\n'
printf '│   hci0   00:1A:7D:DA:71:13   Built-in   Power \033[38;5;46m●\033[0m   Discoverable \033[38;5;46m●\033[0m       │\n'
printf '└─────────────────────────────────────────────────────────────────────────────┘\n'
printf '┌─Devices─────────────────────────────────────────────────────────────────────┐\n'
printf '│  \033[38;5;46m●\033[0m  Studio Headphones      Audio       \033[38;5;46m connected\033[0m   batt \033[38;5;46m▰▰▰▰▱\033[0m 78%%   │\n'
printf '│  \033[38;5;81m◔\033[0m  Living Room Speaker    Audio       \033[2m  paired   \033[0m   batt \033[2m  --\033[0m         │\n'
printf '│  \033[38;5;81m◔\033[0m  Office Keyboard        Peripheral  \033[2m  paired   \033[0m   batt \033[38;5;46m▰▰▰▰▰\033[0m 92%%   │\n'
printf '│  \033[2m○\033[0m  Pixel Phone            Phone       \033[2m  visible  \033[0m   sig  ▰▰▰▱▱        │\n'
printf '│  \033[2m○\033[0m  Trail Cam 4K           Imaging     \033[2m  visible  \033[0m   sig  ▰▰▱▱▱        │\n'
printf '│  \033[2m○\033[0m  Anonymous-A1F2         Unknown     \033[2m  visible  \033[0m   sig  ▰▱▱▱▱        │\n'
printf '└─────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ↑↓ navigate    p pair    c connect    d disconnect    s scan    ?  help \033[0m\n'
pause 4.0

clear
