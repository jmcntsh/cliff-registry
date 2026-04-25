#!/usr/bin/env bash
# spotify-player — Spotify in your terminal (streaming, lyrics, viz)
#
# Template 1 (scripted fake). Spotify-player's hero shot: library
# left, track list middle, now-playing footer with album art.
# We use placeholder track + artist names so the reel never reveals
# the recorder's actual listening history.

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

prompt; type_line 'spotify_player'
beat
pause 0.3
clear

printf '\033[1;38;5;46m  spotify-player \033[0m\033[2m  device: this terminal · connect ●  · ?  help \033[0m\n'
printf '┌─Library──────────────┬─Tracks · "Quiet Focus"────────────────────────────────┐\n'
printf '│ ▾ Liked Songs        │  1  Slow Sketch              Quartet     5:14        │\n'
printf '│ ▾ Playlists          │  2  Lull (reprise)           Field Rec   3:02        │\n'
printf '│   • Quiet Focus      │  3  Ostinato no. 4           Trio        4:11        │\n'
printf '│   • Coffee + Code    │  \033[7m4  Sketch in B-flat           Quartet     4:21        \033[0m │\n'
printf '│   • Long Walks       │  5  Etude for Two Voices     Quartet     6:48        │\n'
printf '│   • Chill Mix        │  6  Berceuse                 Field Rec   2:55        │\n'
printf '│ ▾ Saved Albums       │  7  Sustain                  Trio        7:14        │\n'
printf '│   • Lossless Demos   │  8  Reverie                  Quartet     5:33        │\n'
printf '│   • Quiet Hours      │  9  Open Fifths              Trio        4:02        │\n'
printf '├──────────────────────┴───────────────────────────────────────────────────────┤\n'
printf '│ ▶ \033[1;38;5;46mSketch in B-flat\033[0m  \033[2m·\033[0m  Quartet                                            │\n'
printf '│   \033[2m1:42\033[0m  \033[38;5;46m▰▰▰▰▰▰\033[0m\033[2m▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱\033[0m  \033[2m4:21\033[0m       ♥   ↻all   ⇄shuffle           │\n'
printf '└──────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  space pause    n next    /  search    L like    d devices    ?  help \033[0m\n'
pause 4.0

clear
