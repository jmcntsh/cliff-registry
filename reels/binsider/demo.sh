#!/usr/bin/env bash
# binsider — analyze ELF binaries in your terminal
#
# Template 1 (scripted fake). The pitch is "open an ELF, browse its
# headers, sections, strings, and disassembly in tabs." We render
# the header summary + a strings sample, which is the most
# recognizable first-screen.

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

prompt; type_line 'binsider /usr/bin/ls'
beat
pause 0.3
clear

printf '\033[1;38;5;213m binsider \033[0m\033[2m  /usr/bin/ls · ELF · 64-bit · ?  help \033[0m\n'
printf '┌─\033[7m General \033[0m─\033[2m Strings \033[0m─\033[2m Headers \033[0m─\033[2m Sections \033[0m─\033[2m Hexdump \033[0m─\033[2m Disasm \033[0m──────────┐\n'
printf '│                                                                             │\n'
printf '│   File         /usr/bin/ls                                                  │\n'
printf '│   Size         147,016  bytes                                               │\n'
printf '│   Format       ELF 64-bit LSB executable                                    │\n'
printf '│   Machine      AArch64                                                       │\n'
printf '│   Type         EXEC (Executable)                                             │\n'
printf '│   Entry        0x0000000100003ad0                                            │\n'
printf '│                                                                             │\n'
printf '│   Sections     31                                                            │\n'
printf '│   Symbols      612                                                          │\n'
printf '│   Dynamic      28 entries                                                    │\n'
printf '│                                                                             │\n'
printf '│   Linked       \033[38;5;215mlibSystem.B.dylib\033[0m                                            │\n'
printf '│                \033[38;5;215mlibutil.dylib\033[0m                                                │\n'
printf '│                \033[38;5;215mlibncurses.5.4.dylib\033[0m                                          │\n'
printf '│                                                                             │\n'
printf '└─────────────────────────────────────────────────────────────────────────────┘\n'
printf '\033[2m  ←→ tabs    /  search    e exec    q  quit    ?  help \033[0m\n'
pause 4.0

clear
