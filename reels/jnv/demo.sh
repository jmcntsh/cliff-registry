#!/usr/bin/env bash
# jnv — interactive JSON filter using jq
#
# Template 1 (scripted fake). The whole pitch is "incrementally type
# a jq expression and see the JSON narrow live." We show three
# stages of that narrowing on the same source document.

pause() { sleep "${1:-0.8}"; }
beat()  { sleep "${1:-0.3}"; }

type_line() {
  local s="$1" i
  for (( i=0; i<${#s}; i++ )); do
    printf '%s' "${s:$i:1}"
    sleep 0.04
  done
  printf '\n'
}

prompt() { printf '\033[2m$\033[0m '; }

clear
pause 0.5

prompt; type_line 'cat repos.json | jnv'
beat
pause 0.3
clear

printf '\033[1;38;5;81m jnv \033[0m\033[2m  type jq filter — preview updates live — ?  help \033[0m\n'
printf '┌─ filter ────────────────────────────────────────────────────────────────┐\n'
printf '│ \033[38;5;215m.\033[0m█                                                                       │\n'
printf '└─────────────────────────────────────────────────────────────────────────┘\n'
printf '┌─ preview ───────────────────────────────────────────────────────────────┐\n'
printf '│ [                                                                       │\n'
printf '│   { \033[38;5;81m"name"\033[0m: \033[38;5;215m"cliff"\033[0m,    \033[38;5;81m"stars"\033[0m: 412,  \033[38;5;81m"lang"\033[0m: \033[38;5;215m"Go"\033[0m       },    │\n'
printf '│   { \033[38;5;81m"name"\033[0m: \033[38;5;215m"reel"\033[0m,     \033[38;5;81m"stars"\033[0m:  88,  \033[38;5;81m"lang"\033[0m: \033[38;5;215m"Go"\033[0m       },    │\n'
printf '│   { \033[38;5;81m"name"\033[0m: \033[38;5;215m"glow"\033[0m,     \033[38;5;81m"stars"\033[0m: 17500, \033[38;5;81m"lang"\033[0m: \033[38;5;215m"Go"\033[0m      },    │\n'
printf '│   { \033[38;5;81m"name"\033[0m: \033[38;5;215m"yazi"\033[0m,     \033[38;5;81m"stars"\033[0m: 12200, \033[38;5;81m"lang"\033[0m: \033[38;5;215m"Rust"\033[0m    }     │\n'
printf '│ ]                                                                       │\n'
printf '└─────────────────────────────────────────────────────────────────────────┘\n'
pause 1.2

printf '\033[10A\033[2K\033[2K\033[2K\033[2K\033[2K\033[2K\033[2K\033[2K\033[2K\033[2K'
printf '┌─ filter ────────────────────────────────────────────────────────────────┐\n'
printf '│ \033[38;5;215m.[] | select(.stars > 1000) | {name, stars}\033[0m█                            │\n'
printf '└─────────────────────────────────────────────────────────────────────────┘\n'
printf '┌─ preview ───────────────────────────────────────────────────────────────┐\n'
printf '│ { \033[38;5;81m"name"\033[0m: \033[38;5;215m"glow"\033[0m, \033[38;5;81m"stars"\033[0m: 17500 }                                  │\n'
printf '│ { \033[38;5;81m"name"\033[0m: \033[38;5;215m"yazi"\033[0m, \033[38;5;81m"stars"\033[0m: 12200 }                                  │\n'
printf '│                                                                         │\n'
printf '│                                                                         │\n'
printf '│                                                                         │\n'
printf '│                                                                         │\n'
printf '└─────────────────────────────────────────────────────────────────────────┘\n'
pause 3.0

clear
