#!/usr/bin/env bash
# scope-tui — oscilloscope/vectorscope/spectroscope for the terminal
#
# Template 1 (scripted fake). Real scope-tui needs an audio backend
# (CPAL) or a file source; on the recording machine those would
# either capture the recorder's actual audio (privacy issue) or
# show a flat line (boring). We hand-draw a representative waveform
# instead.

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

prompt; type_line 'scope-tui audio'
beat
pause 0.3
clear

printf '\033[1;38;5;120m scope-tui \033[0m\033[2m  oscilloscope · vectorscope · spectroscope · 48000Hz · 2ch \033[0m\n'
printf '┌────────────────────────────────────────────────────────────────────────────────┐\n'
printf '│                                                                                │\n'
printf '│        \033[38;5;46m⠀⢀⣠⠴⠚⠉⠁⠀⠀⠈⠉⠓⠦⣄⡀\033[0m                                                  │\n'
printf '│      \033[38;5;46m⢀⡴⠊⠁\033[0m              \033[38;5;46m⠉⠳⢄⡀\033[0m                                              │\n'
printf '│    \033[38;5;46m⡰⠋\033[0m                      \033[38;5;46m⠙⢆⡀\033[0m                                          │\n'
printf '│  \033[38;5;46m⡰⠁\033[0m                            \033[38;5;46m⠙⢆\033[0m                          \033[38;5;46m⢀⡠⠔⢲\033[0m       │\n'
printf '│\033[38;5;46m⠴⠁\033[0m                                  \033[38;5;46m⠳⡀\033[0m                    \033[38;5;46m⡠⠊⠁\033[0m         │\n'
printf '│\033[2m─────────────────────────────────────────────\033[0m\033[38;5;46m⢇\033[0m\033[2m──────────────\033[0m\033[38;5;46m⡜\033[0m\033[2m─────────────\033[0m  │\n'
printf '│                                            \033[38;5;46m⠳⡀\033[0m         \033[38;5;46m⢀⡰⠁\033[0m                  │\n'
printf '│                                              \033[38;5;46m⠙⢄⡀\033[0m   \033[38;5;46m⢀⡠⠞\033[0m                     │\n'
printf '│                                                 \033[38;5;46m⠉⠒⠒⠉\033[0m                          │\n'
printf '│                                                                                │\n'
printf '└────────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  q quit   space pause   v vectorscope   s spectroscope   t tune   ? help \033[0m\n'
pause 4.0

clear
