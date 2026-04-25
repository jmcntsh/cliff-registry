#!/usr/bin/env bash
# kew — minimalist terminal music player with ASCII covers and visualizer
#
# Template 1 (scripted fake). Kew's hero shot: ASCII rendering of
# album art on the left, track info + progress bar on the right,
# tiny visualizer at the bottom. We use placeholder track names —
# never the recorder's real library.

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

prompt; type_line 'kew'
beat
pause 0.3
clear

printf '\033[1;38;5;213m  kew \033[0m\033[2m  library · queue · search · ?  help \033[0m\n'
printf '\n'
printf '   \033[38;5;213m▓▓▓▓▓▓▓▓▓▓▓\033[0m       \033[1m Sketch in B-flat\033[0m\n'
printf '   \033[38;5;213m▓▒▒▒▒▒▒▒▒▒▓\033[0m       \033[2mby\033[0m  Public Domain Trio\n'
printf '   \033[38;5;213m▓▒░░░░░░░▒▓\033[0m       \033[2mfrom\033[0m  Lossless Demos · 2026\n'
printf '   \033[38;5;213m▓▒░  ◯  ░▒▓\033[0m\n'
printf '   \033[38;5;213m▓▒░ /│\\ ░▒▓\033[0m       ▶  \033[1;38;5;46m1:42\033[0m  \033[38;5;46m▰▰▰▰▰▰\033[0m\033[2m▱▱▱▱▱▱▱\033[0m  \033[38;5;177m4:21\033[0m\n'
printf '   \033[38;5;213m▓▒░░░░░░░▒▓\033[0m\n'
printf '   \033[38;5;213m▓▒▒▒▒▒▒▒▒▒▓\033[0m       \033[2mvolume\033[0m  ▰▰▰▰▰▰▱▱  72%%\n'
printf '   \033[38;5;213m▓▓▓▓▓▓▓▓▓▓▓\033[0m       \033[2mshuffle\033[0m  off    \033[2mrepeat\033[0m  all\n'
printf '\n'
printf '   \033[2mUp Next\033[0m\n'
printf '   1  Andante in C        Quartet for Strings\n'
printf '   2  Lullaby (reprise)   Field Recordings\n'
printf '   3  Ostinato no. 4      Public Domain Trio\n'
printf '\n'
printf '   \033[38;5;46m▁▂▃▅▆▇▆▅▃▂▁ ▁▂▃▅▆▅▃▂▁ ▁▃▅▇▆▅▃▁ ▁▂▄▆▅▄▂▁ ▁▂▃▅▆▅▃▂▁\033[0m\n'
printf '\n'
printf '\033[2m  space pause    ←→ seek    n next    p prev    /  search    q  quit \033[0m\n'
pause 4.0

clear
