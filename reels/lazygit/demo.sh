#!/usr/bin/env bash
# lazygit — simple terminal UI for git commands
#
# Template 1 (scripted fake). Lazygit's signature is its 5-pane
# layout: status / files / branches / commits / stash. We don't try
# to render all 5 — too crowded at 80x24 — and instead focus on the
# files + diff hero shot that dominates the README screenshots.

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

prompt; type_line 'lazygit'
beat
pause 0.3
clear

printf '\033[1;38;5;46m lazygit \033[0m\033[2m  cliff-registry · main · 2 ahead · ?  help \033[0m\n'
printf '┌─1 Status─────────────┬─2 Files─────────────────────────────────────────────┐\n'
printf '│ ⎇ main ↑2            │ \033[38;5;120m●●\033[0m reels/glow/demo.sh                              │\n'
printf '│ origin/main          │ \033[38;5;120m●●\033[0m reels/cava/demo.sh                              │\n'
printf '├─3 Local branches─────┤ \033[38;5;226m●\033[0m  scripts/record-reel.sh                          │\n'
printf '│ \033[7m main             ↑2 \033[0m │ \033[38;5;120m??\033[0m reels/yazi/demo.sh                              │\n'
printf '│   feat/reel-strip    │                                                     │\n'
printf '│   fix/clobber-reel   │                                                     │\n'
printf '├─4 Commits────────────┼─5 Diff──────────────────────────────────────────────┤\n'
printf '│ \033[38;5;81mf3a91c2\033[0m feat(reels):..│ \033[2m@@ -41,6 +41,9 @@\033[0m                                  │\n'
printf '│ \033[38;5;81m9f3a6e1\033[0m fix(record):..│   func renderReadme(app App) string {              │\n'
printf '│ \033[38;5;81m8e2a071\033[0m docs(reels):..│ \033[38;5;120m+   strip := newReelStripForApp(app.Slug, width)\033[0m   │\n'
printf '│                      │ \033[38;5;120m+   body = lipgloss.JoinVertical(...)\033[0m               │\n'
printf '└──────────────────────┴─────────────────────────────────────────────────────┘\n'
printf '\033[2m  1-5 panel    space stage    c commit    P push    p pull    ?  help \033[0m\n'
pause 4.0

clear
