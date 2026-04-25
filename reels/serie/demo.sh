#!/usr/bin/env bash
# serie — rich git commit graph in your terminal, like magic
#
# Template 1 (scripted fake). Serie's hero shot is the colored
# branch-graph drawing on the left edge with commit messages and
# refs on the right. We mirror that without naming any private
# branches/people.

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

prompt; type_line 'serie'
beat
pause 0.3
clear

printf '\033[1;38;5;177m serie \033[0m\033[2m  cliff-registry · 218 commits · ?  help \033[0m\n'
printf '┌─Graph───────────────────────────────────────────────────────────────────────┐\n'
printf '│ \033[38;5;213m●\033[0m \033[38;5;81mf3a91c2\033[0m  \033[38;5;46m(HEAD → main)\033[0m feat(reels): batch one demo scripts        │\n'
printf '│ \033[38;5;213m●\033[0m \033[38;5;81m9f3a6e1\033[0m  fix(record-reel): clobber existing artifact               │\n'
printf '│ \033[38;5;213m●\033[0m \033[38;5;81m8e2a071\033[0m  docs(reels): add GUIDELINES.md                            │\n'
printf '│ \033[38;5;213m●\033[0m \033[38;5;81m4b1f88c\033[0m  \033[38;5;226m(origin/main)\033[0m feat(reels): pilot batch (glow, cava)      │\n'
printf '│ \033[38;5;213m│\033[0m\033[38;5;82m\\\033[0m                                                                          │\n'
printf '│ \033[38;5;213m│\033[0m \033[38;5;82m●\033[0m \033[38;5;81m211aa0c\033[0m  feat(reels): scripts/record-reel.sh                     │\n'
printf '│ \033[38;5;213m│\033[0m \033[38;5;82m●\033[0m \033[38;5;81m1c0aa7e\033[0m  feat(reels): glow demo                                  │\n'
printf '│ \033[38;5;213m│\033[0m\033[38;5;82m/\033[0m                                                                          │\n'
printf '│ \033[38;5;213m●\033[0m \033[38;5;81mae33e1d\033[0m  chore: bump catalog to 44 entries                         │\n'
printf '│ \033[38;5;213m●\033[0m \033[38;5;81m71b2e4f\033[0m  feat(catalog): add 6 music & visualizer apps              │\n'
printf '└─────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ↑↓ navigate    ⏎ show    /  search    H toggle help    q  quit \033[0m\n'
pause 4.0

clear
