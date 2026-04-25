#!/usr/bin/env bash
# atuin — magical shell history (SQLite-backed, searchable, syncable)
#
# Template 1 (scripted fake). Atuin's hero moment is hitting Up
# and getting the fuzzy-search overlay over your shell history,
# with metadata (when, where, exit code, duration). Mirror that.

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

prompt; type_line 'atuin search --interactive'
beat
pause 0.3
clear

printf '\033[1;38;5;213m atuin \033[0m\033[2m  search · stats · sync · import · ? help \033[0m\n'
printf '┌──────────────────────────────────────────────────────────────────────────────┐\n'
printf '│ \033[38;5;215m> \033[0mgit                                                                       │\n'
printf '│                                                                              │\n'
printf '│ \033[7m  git status                                  \033[0m \033[38;5;46m✓\033[0m \033[2m   2m ago    /cliff      \033[0m │\n'
printf '│   git switch -c feat/reel-strip                \033[38;5;46m✓\033[0m \033[2m  17m ago    /cliff      \033[0m │\n'
printf '│   git log --oneline -20                        \033[38;5;46m✓\033[0m \033[2m   1h ago    /cliff      \033[0m │\n'
printf '│   git rebase -i origin/main                    \033[38;5;46m✓\033[0m \033[2m   3h ago    /cliff      \033[0m │\n'
printf '│   git push origin HEAD                         \033[38;5;9m✗\033[0m \033[2m   3h ago    /cliff      \033[0m │\n'
printf '│   git diff --staged                            \033[38;5;46m✓\033[0m \033[2m   1d ago    /reel       \033[0m │\n'
printf '│   git remote -v                                \033[38;5;46m✓\033[0m \033[2m   2d ago    /reel       \033[0m │\n'
printf '│                                                                              │\n'
printf '└──────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ⏎ run    tab edit    ctrl-r toggle filter    ctrl-d delete    esc cancel \033[0m\n'
pause 4.0

clear
