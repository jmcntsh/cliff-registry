#!/usr/bin/env bash
# gh-dash — gh extension: PRs and issues on a customizable terminal dashboard
#
# Template 1 (scripted fake). Show the canonical PR dashboard:
# tabbed sections (My Pull Requests / Needs Review / Subscribed),
# a colored table of PRs with status icons, repo, branch, age.

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

prompt; type_line 'gh dash'
beat
pause 0.3
clear

printf '\033[1;38;5;81m gh-dash \033[0m\033[2m   /  search    p  prs    i  issues    r  refresh    ?  help \033[0m\n'
printf '┌─\033[7m My Pull Requests \033[0m─\033[2m Needs My Review \033[0m─\033[2m Subscribed \033[0m──────────────────────────────┐\n'
printf '│                                                                              │\n'
printf '│   \033[38;5;46m✓\033[0m  #1248  feat(reels): batch one demo scripts          \033[2mcliff-registry\033[0m   2h │\n'
printf '│   \033[38;5;214m●\033[0m  #1249  fix(ui): readme wrap on narrow widths        \033[2mcliff\033[0m            5h │\n'
printf '│   \033[38;5;46m✓\033[0m  #1247  docs: clarify install for cargo crates       \033[2mcliff-registry\033[0m   1d │\n'
printf '│   \033[38;5;81m◔\033[0m  #1240  feat(reel): add --size flag to record         \033[2mreel\033[0m             2d │\n'
printf '│   \033[38;5;177m✎\033[0m  #1233  draft: client-side reel cache                \033[2mcliff\033[0m            3d │\n'
printf '│   \033[38;5;9m✗\033[0m  #1231  flake test: fixtures path                     \033[2mcliff\033[0m            4d │\n'
printf '│                                                                              │\n'
printf '│   \033[2m──── 6 of 6 ─────────────────────────────────────────────────────────────\033[0m │\n'
printf '│                                                                              │\n'
printf '└──────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ↑↓ navigate    ⏎ open    c checkout    a approve    /  filter    ?  help \033[0m\n'
pause 4.0

clear
