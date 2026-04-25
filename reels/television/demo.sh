#!/usr/bin/env bash
# television — fast, versatile fuzzy finder TUI for files, git, env, docker, ...
#
# Template 1 (scripted fake). Television's twist on fzf: pluggable
# "channels" (files / git / env / docker / etc.). We mirror the
# split layout: query bar, ranked results list, and a preview pane.

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

prompt; type_line 'tv files'
beat
pause 0.3
clear

printf '\033[1;38;5;213m  Television \033[0m\033[2m  channel: files · 4214 indexed · ?  help \033[0m\n'
printf '┌───────────────────────────────────────┬─────────────────────────────────────┐\n'
printf '│ \033[38;5;215m> \033[0mreel                              │ \033[2m── reels/glow/demo.sh ──\033[0m              │\n'
printf '│                                       │                                     │\n'
printf '│ \033[7m  reels/glow/demo.sh                 \033[0m │ \033[1;36m#!/usr/bin/env bash\033[0m                 │\n'
printf '│   reels/cava/demo.sh                  │ \033[2m# glow — render markdown on\033[0m         │\n'
printf '│   reels/gum/demo.sh                   │ \033[2m# the CLI, with pizzazz.\033[0m            │\n'
printf '│   reels/yazi/demo.sh                  │                                     │\n'
printf '│   internal/ui/reel_strip.go           │ pause() { sleep "${1:-0.8}"; }      │\n'
printf '│   internal/ui/reel_strip_test.go      │ beat()  { sleep "${1:-0.3}"; }      │\n'
printf '│   scripts/record-reel.sh              │                                     │\n'
printf '│   reels/GUIDELINES.md                 │ type_line() {                       │\n'
printf '│   reels/balatro-tui/demo.sh           │   local s="$1" i                    │\n'
printf '│   reels/bottom/demo.sh                │   for (( i=0; ... ))                │\n'
printf '└───────────────────────────────────────┴─────────────────────────────────────┘\n'
printf '\033[2m  ↑↓  pick    ⏎  open    ctrl-/ channel    ctrl-r reload    esc cancel \033[0m\n'
pause 4.0

clear
