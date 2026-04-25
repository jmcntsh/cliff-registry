#!/usr/bin/env bash
# impala — TUI for managing Wi-Fi networks with iwd on Linux
#
# Template 1 (scripted fake). Hero shot: list of nearby SSIDs with
# signal bars, security badges, and the "connected" marker. We use
# placeholder SSIDs so we never leak the recorder's actual nearby
# networks.

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

prompt; type_line 'impala'
beat
pause 0.3
clear

printf '\033[1;38;5;81m  impala \033[0m\033[2m  iwd · adapter wlan0 · station mode · scanning ◐ \033[0m\n'
printf '┌─Adapter───────────────────────────────────────────────────────────────────┐\n'
printf '│   wlan0     Intel AX211 · powered · scan period 5s                        │\n'
printf '└───────────────────────────────────────────────────────────────────────────┘\n'
printf '┌─Networks──────────────────────────────────────────────────────────────────┐\n'
printf '│  \033[38;5;46m●\033[0m  home-2.4         psk      \033[38;5;46m▮▮▮▮▮\033[0m   ch  6   \033[38;5;46m connected   \033[0m       │\n'
printf '│  \033[2m○\033[0m  home-5G          psk      \033[38;5;46m▮▮▮▮\033[2m▮\033[0m   ch  36  \033[2m  known      \033[0m       │\n'
printf '│  \033[2m○\033[0m  guest-net        open     \033[38;5;46m▮▮▮\033[2m▮▮\033[0m   ch  11                          │\n'
printf '│  \033[2m○\033[0m  cafe-wifi        psk      \033[38;5;46m▮▮\033[2m▮▮▮\033[0m   ch  1                           │\n'
printf '│  \033[2m○\033[0m  printer-direct   wpa2     \033[38;5;46m▮\033[2m▮▮▮▮\033[0m   ch  6                           │\n'
printf '│  \033[2m○\033[0m  hidden           psk      \033[2m▮▮▮▮▮\033[0m   ch  --                          │\n'
printf '└───────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ↑↓ navigate    ⏎ connect    d disconnect    f forget    s scan    ? help \033[0m\n'
pause 4.0

clear
