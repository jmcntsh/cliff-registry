#!/usr/bin/env bash
# termusic — terminal music player with playlists, tags, podcasts
#
# Template 1 (scripted fake). Termusic's signature: 4-pane layout —
# library tree, track list, lyrics, and now-playing footer. We use
# placeholder track and album names so we never expose the
# recorder's real library.

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

prompt; type_line 'termusic'
beat
pause 0.3
clear

printf '\033[1;38;5;81m termusic \033[0m\033[2m  library · queue · podcasts · tag editor · ?  help \033[0m\n'
printf '┌─Library──────────────┬─Tracks────────────────────────────────────────────────┐\n'
printf '│ ▾ Public Domain      │  1  Andante in C              Quartet · 5:14         │\n'
printf '│   ▾ Quartet          │  2  Lullaby (reprise)         Field Rec · 3:02       │\n'
printf '│     • Andante in C   │  3  Ostinato no. 4            Trio · 4:11            │\n'
printf '│     • Allegro        │  \033[7m4  Sketch in B-flat            Trio · 4:21          \033[0m │\n'
printf '│   ▸ Trio             │  5  Etude for Two Voices      Quartet · 6:48         │\n'
printf '│   ▸ Field Recordings │  6  Berceuse                  Field Rec · 2:55       │\n'
printf '├─Lyrics───────────────┴───────────────────────────────────────────────────────┤\n'
printf '│   (instrumental)                                                              │\n'
printf '│                                                                              │\n'
printf '│                                                                              │\n'
printf '├──────────────────────────────────────────────────────────────────────────────┤\n'
printf '│  ▶ \033[1;38;5;46mSketch in B-flat\033[0m   \033[2m1:42\033[0m  \033[38;5;46m▰▰▰▰▰▰\033[0m\033[2m▱▱▱▱▱▱▱\033[0m  \033[2m4:21\033[0m   \033[2mvol\033[0m ▰▰▰▰▰▰▱▱   │\n'
printf '└──────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  space pause    n next    /  search    e edit tags    p podcasts    ?  help \033[0m\n'
pause 4.0

clear
