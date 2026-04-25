#!/usr/bin/env bash
# atac — TUI API client (Postman in your terminal)
#
# Template 1 (scripted fake). Show the canonical request/response
# layout: collection list on the left, request builder + response
# on the right. The single most recognizable hook is the colored
# method badges (GET / POST / PUT) and a status line with the
# response code.

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

prompt; type_line 'atac'
beat
pause 0.3
clear

printf '\033[1;38;5;213m ATAC \033[0m\033[2m  collections · environments · history · settings \033[0m\n'
printf '┌─Collections────────┬─Request───────────────────────────────────────────────┐\n'
printf '│ ▾ users-api        │ \033[1;38;5;46m GET \033[0m \033[38;5;215mhttps://api.example.com/v1/users/42\033[0m            │\n'
printf '│   \033[1;38;5;46mGET\033[0m  /users/:id   │                                                       │\n'
printf '│   \033[1;38;5;214mPOST\033[0m /users       │ \033[2mParams · Headers · Body · Auth · Tests · Scripts\033[0m       │\n'
printf '│   \033[1;38;5;81mPUT\033[0m  /users/:id   │                                                       │\n'
printf '│ ▾ checkout         │ Authorization  Bearer •••••••••••••••••••           │\n'
printf '│   \033[1;38;5;214mPOST\033[0m /charge      │ Accept         application/json                       │\n'
printf '│                    │                                                       │\n'
printf '├─Environments───────┼─Response──── \033[1;38;5;46m200 OK\033[0m  \033[2m· 142ms · 318 B\033[0m ────────────────┤\n'
printf '│ • staging          │ {                                                     │\n'
printf '│ • prod             │   \033[38;5;81m"id"\033[0m: 42,                                          │\n'
printf '│                    │   \033[38;5;81m"name"\033[0m: \033[38;5;215m"Ada Lovelace"\033[0m,                          │\n'
printf '│                    │   \033[38;5;81m"team"\033[0m: \033[38;5;215m"analytical-engine"\033[0m                      │\n'
printf '│                    │ }                                                     │\n'
printf '└────────────────────┴───────────────────────────────────────────────────────┘\n'
printf '\033[2m  / search   <enter> send   c collections   e env   h history   ? help \033[0m\n'
pause 4.0

clear
