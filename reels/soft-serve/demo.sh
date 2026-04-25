#!/usr/bin/env bash
# soft-serve — self-hostable Git server with an SSH-accessible TUI
#
# Template 1 (scripted fake). Soft-serve is fronted via SSH, so the
# canonical demo is "ssh into your server and get a charming TUI
# of your repos." We mirror the repo listing landing screen.

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

prompt; type_line 'ssh git.example.com'
beat
pause 0.5
clear

printf '\033[1;38;5;213m  Soft Serve \033[0m\033[2m  charm-served git · git.example.com:23231 \033[0m\n'
printf '┌─Repositories────────────────────────────────────────────────────────────────┐\n'
printf '│                                                                             │\n'
printf '│ \033[7m  cliff             \033[0m  terminal-native directory for CLIs and TUIs       │\n'
printf '│   cliff-registry    catalog of apps installable through cliff               │\n'
printf '│   reel              terminal session recorder                                │\n'
printf '│   weathr            ascii weather, animated                                  │\n'
printf '│   minesweep         minesweeper in the terminal                              │\n'
printf '│   .config           dotfiles                                                 │\n'
printf '│                                                                             │\n'
printf '└─────────────────────────────────────────────────────────────────────────────┘\n'
printf '┌─cliff · README ─────────────────────────────────────────────────────────────┐\n'
printf '│ \033[1;35m# cliff\033[0m                                                                     │\n'
printf '│                                                                             │\n'
printf '│ A terminal-native directory for CLIs and TUIs.                               │\n'
printf '│                                                                             │\n'
printf '│ \033[1;36m## Install\033[0m                                                                  │\n'
printf '│     \033[48;5;236;38;5;252m brew install cliff                                  \033[0m            │\n'
printf '└─────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ↑↓ navigate    ⏎ open    R refs    F files    L log    q  quit \033[0m\n'
pause 4.0

clear
