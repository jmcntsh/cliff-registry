#!/usr/bin/env bash
# gitlogue — cinematic git-history replay with typing animations
#
# Template 1 (scripted fake). Gitlogue is "watch your git history
# play back like a movie" — typing animation, file tree shifts,
# syntax-highlighted diff chunks. We fake one beat of that movie.

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

prompt; type_line 'gitlogue play'
beat
pause 0.3
clear

printf '\033[1;38;5;213m gitlogue \033[0m\033[2m  HEAD~12 → HEAD · ▶ playing · 1.0x · ? help \033[0m\n'
printf '┌─Files──────────────┬─Diff──────────────────────────────────────────────────┐\n'
printf '│ \033[38;5;120m+\033[0m reels/glow/demo.sh│ \033[2m@@ -41,6 +41,9 @@ func renderReadme(...)\033[0m              │\n'
printf '│ \033[38;5;120m+\033[0m reels/cava/demo.sh│   func renderReadme(app App) string {                │\n'
printf '│   internal/ui/...  │     body := mdRender(app.Readme)                     │\n'
printf '│ \033[38;5;81mM\033[0m   reel_strip.go    │ \033[38;5;120m+   strip := newReelStripForApp(app.Slug, width)\033[0m     │\n'
printf '│                    │ \033[38;5;120m+   if strip.HasReel() {\033[0m                              │\n'
printf '│                    │ \033[38;5;120m+     body = lipgloss.JoinVertical(...)\033[0m              │\n'
printf '│                    │ \033[38;5;120m+   }\033[0m                                                 │\n'
printf '│                    │     return body                                       │\n'
printf '│                    │   }                                                   │\n'
printf '└────────────────────┴───────────────────────────────────────────────────────┘\n'
printf '\033[1;38;5;177m ● f3a91c2 \033[0m  feat(reels): play app reel above readme  \033[2m  Sat 1:32pm\033[0m\n'
printf '\033[2m  ⏯  play/pause    ←→  step    > faster    <  slower    q  quit \033[0m\n'
pause 4.0

clear
