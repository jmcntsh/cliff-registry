#!/usr/bin/env bash
# posting — modern HTTP API client in the terminal (Textual-based)
#
# Template 1 (scripted fake). Posting's signature is its modern Textual
# look: rounded panels, accent purple/pink chrome, and a clean
# request → response split. We mirror that.

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

prompt; type_line 'posting'
beat
pause 0.3
clear

printf '\033[1;38;5;177m  Posting \033[0m\033[2m  api · workspaces · variables · keymap · ? \033[0m\n'
printf '╭─ Collection ───────╮╭─ Request ─────────────────────────────────────────╮\n'
printf '│ ▾ pokeapi          ││ \033[1;38;5;46mGET\033[0m  \033[38;5;215mhttps://pokeapi.co/api/v2/pokemon/ditto\033[0m       │\n'
printf '│   \033[1;38;5;46mGET\033[0m  pokemon/:n   ││                                                   │\n'
printf '│   \033[1;38;5;46mGET\033[0m  type/:t      ││ \033[2mHeaders   Body   Query   Auth   Cookies\033[0m            │\n'
printf '│ ▾ stripe           ││                                                   │\n'
printf '│   \033[1;38;5;214mPOST\033[0m charges      ││ Accept       application/json                     │\n'
printf '│   \033[1;38;5;81mPUT\033[0m  customers    ││ User-Agent   posting/3.0                          │\n'
printf '╰────────────────────╯╰───────────────────────────────────────────────────╯\n'
printf '╭─ Response  \033[1;38;5;46m200\033[0m \033[2m·  87ms  ·  742 bytes\033[0m  ──────────────────────────────╮\n'
printf '│ {                                                                       │\n'
printf '│   \033[38;5;81m"name"\033[0m: \033[38;5;215m"ditto"\033[0m,                                                  │\n'
printf '│   \033[38;5;81m"id"\033[0m: 132,                                                          │\n'
printf '│   \033[38;5;81m"types"\033[0m: [{ \033[38;5;81m"slot"\033[0m: 1, \033[38;5;81m"type"\033[0m: { \033[38;5;81m"name"\033[0m: \033[38;5;215m"normal"\033[0m } }],     │\n'
printf '│   \033[38;5;81m"abilities"\033[0m: [\033[38;5;215m"limber"\033[0m, \033[38;5;215m"imposter"\033[0m]                            │\n'
printf '│ }                                                                       │\n'
printf '╰─────────────────────────────────────────────────────────────────────────╯\n'
printf '\033[2m  ctrl+j send    /  search    e env    ?  help \033[0m\n'
pause 3.8

clear
