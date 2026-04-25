#!/usr/bin/env bash
# frogmouth — Markdown browser for your terminal (Textualize)
#
# Template 1 (scripted fake). Frogmouth's gimmick: like a web browser
# but for markdown — back/forward, address bar, tabs, in-page links
# that follow markdown anchors. We mirror that browser chrome.

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

prompt; type_line 'frogmouth README.md'
beat
pause 0.3
clear

printf '\033[1;38;5;120m  Frogmouth \033[0m\033[2m  ←  →  ⟳   \033[0m\033[38;5;215mfile://README.md\033[0m\n'
printf '┌─────────────────────────────────────────────────────────────────────────────┐\n'
printf '│                                                                             │\n'
printf '│  \033[1;35m# cliff-registry\033[0m                                                          │\n'
printf '│                                                                             │\n'
printf '│  Catalog of CLIs and TUIs available through the cliff app.                  │\n'
printf '│                                                                             │\n'
printf '│  \033[1;36m## How submission works\033[0m                                                    │\n'
printf '│                                                                             │\n'
printf '│  \033[35m1.\033[0m Read the \033[4;38;5;81msubmission guidelines\033[0m                                            │\n'
printf '│  \033[35m2.\033[0m Add `apps/<slug>.toml` with your app metadata                              │\n'
printf '│  \033[35m3.\033[0m (optional) Drop a 80x24 demo.sh in `reels/<slug>/`                          │\n'
printf '│  \033[35m4.\033[0m Open a PR. CI will validate and publish.                                    │\n'
printf '│                                                                             │\n'
printf '│  \033[1;36m## Anatomy of an entry\033[0m                                                     │\n'
printf '│                                                                             │\n'
printf '│      \033[48;5;236;38;5;252m name        = "yourapp"                          \033[0m                  │\n'
printf '│      \033[48;5;236;38;5;252m description = "what it does in one line"         \033[0m                  │\n'
printf '│      \033[48;5;236;38;5;252m homepage    = "https://github.com/you/yourapp"   \033[0m                  │\n'
printf '│                                                                             │\n'
printf '└─────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ←  back   →  forward   ⌘+b  bookmark   /  find   ⌘+t  new tab   q  quit \033[0m\n'
pause 4.0

clear
