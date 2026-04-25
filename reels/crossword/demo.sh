#!/usr/bin/env bash
# crossword — play crossword puzzles in your terminal
#
# Template 1 (scripted fake). A small crossword grid with one
# active cell, plus the across/down clue list. The grid look is
# the whole identity.

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

prompt; type_line 'crossword today.puz'
beat
pause 0.3
clear

printf '\033[1;38;5;213m  crossword \033[0m\033[2m  Mini · 5x5 · 12:32 · ?  help \033[0m\n'
printf '\n'
printf '   ┌───┬───┬───┬───┬───┐    \033[1;36mAcross\033[0m\n'
printf '   │ \033[2m¹\033[0mC │ \033[2m²\033[0mL │ \033[2m³\033[0mI │ \033[2m⁴\033[0mF │ \033[2m⁵\033[0mF │      \033[38;5;215m1\033[0m  Edge of a sea cliff (5)\n'
printf '   ├───┼───┼───┼───┼───┤      \033[38;5;215m6\033[0m  Steep drop (4)\n'
printf '   │ \033[2m⁶\033[0mE │ D │ G │ E │   │      \033[38;5;215m7\033[0m  Cooked, like a steak (4)\n'
printf '   ├───┼───┼───┼───┼───┤      \033[38;5;215m8\033[0m  Type, sort, kind (4)\n'
printf '   │ \033[2m⁷\033[0mR │ A │ R │ E │ ▓ │\n'
printf '   ├───┼───┼───┼───┼───┤    \033[1;36mDown\033[0m\n'
printf '   │ \033[2m⁸\033[0mI │ L │ K │ ▓ │ \033[7m \033[0m │      \033[38;5;215m1\033[0m  Carry, as a bag (4)\n'
printf '   ├───┼───┼───┼───┼───┤      \033[38;5;215m2\033[0m  Make a quilt (4)\n'
printf '   │ ▓ │ ▓ │   │   │   │      \033[38;5;215m3\033[0m  ___ Maiden voyage (5)\n'
printf '   └───┴───┴───┴───┴───┘      \033[38;5;215m4\033[0m  Toss like a coin (5)\n'
printf '\n'
printf '\033[2m  ←→↑↓ move    space toggle dir    ? hint    R reveal    q quit \033[0m\n'
pause 4.0

clear
