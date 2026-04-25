#!/usr/bin/env bash
# rmpc — modern MPD client with album art (ncmpcpp / ranger inspired)
#
# Template 1 (scripted fake). Hero shot: album-art block on the left,
# queue + library miller-columns on the right, now-playing footer.

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

prompt; type_line 'rmpc'
beat
pause 0.3
clear

printf '\033[1;38;5;213m rmpc \033[0m\033[2m  mpd@127.0.0.1:6600 · queue · browse · search · ?  help \033[0m\n'
printf '┌──────────────┬─Artists────────┬─Albums────────────┬─Tracks──────────────────┐\n'
printf '│ \033[38;5;177m▓▓▓▓▓▓▓▓▓▓\033[0m   │ Field Recordings│ Lossless Demos    │  1  Andante in C    5:14 │\n'
printf '│ \033[38;5;177m▓▒▒▒▒▒▒▒▒▓\033[0m   │ Public Domain   │ Quiet Hours       │  2  Lullaby         3:02 │\n'
printf '│ \033[38;5;177m▓▒░░░░░░▒▓\033[0m   │ \033[7m Quartet         \033[0m│ \033[7m Sketches in B-flat \033[0m│  3  Ostinato no. 4  4:11 │\n'
printf '│ \033[38;5;177m▓▒░ ♪♪ ░▒▓\033[0m   │ Trio            │ Long Tones        │ \033[7m 4  Sketch in B-flat 4:21 \033[0m│\n'
printf '│ \033[38;5;177m▓▒░░░░░░▒▓\033[0m   │                 │                   │  5  Etude           6:48 │\n'
printf '│ \033[38;5;177m▓▒▒▒▒▒▒▒▒▓\033[0m   │                 │                   │  6  Berceuse        2:55 │\n'
printf '│ \033[38;5;177m▓▓▓▓▓▓▓▓▓▓\033[0m   │                 │                   │                          │\n'
printf '├──────────────┴─────────────────┴───────────────────┴──────────────────────────┤\n'
printf '│  ▶ \033[1;38;5;46mSketch in B-flat\033[0m  \033[2m·\033[0m  Quartet  \033[2m·\033[0m  Lossless Demos                       │\n'
printf '│  \033[2m1:42\033[0m  \033[38;5;46m▰▰▰▰▰▰▰▰\033[0m\033[2m▱▱▱▱▱▱▱▱▱▱▱▱▱▱\033[0m  \033[2m4:21\033[0m            \033[2mvol\033[0m  ▰▰▰▰▰▰▱▱           │\n'
printf '└──────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  1-4 pane    space pause    > next    < prev    /  search    ?  help \033[0m\n'
pause 4.0

clear
