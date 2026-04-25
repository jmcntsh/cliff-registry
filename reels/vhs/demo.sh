#!/usr/bin/env bash
# vhs — write terminal GIFs as code
#
# Template 1 (scripted fake). VHS isn't a TUI; it's a tape file
# language that produces a .gif. The pitch is "your demo is a
# checked-in script." So we show: cat the .tape, then vhs builds it.

pause() { sleep "${1:-0.8}"; }
beat()  { sleep "${1:-0.3}"; }

type_line() {
  local s="$1" i
  for (( i=0; i<${#s}; i++ )); do
    printf '%s' "${s:$i:1}"
    sleep 0.025
  done
  printf '\n'
}

prompt() { printf '\033[2m$\033[0m '; }

clear
pause 0.5

prompt; type_line 'cat demo.tape'
beat
cat <<'EOF'
Output demo.gif
Set FontSize 14
Set Width 1200
Set Height 600

Type "echo hello, vhs"
Enter
Sleep 1s
Type "ls -la"
Enter
Sleep 1.5s
EOF
pause 1.0

prompt; type_line 'vhs demo.tape'
beat
printf '\033[38;5;213m■\033[0m \033[2mrendering frames\033[0m  \033[38;5;177m▰▰▰▰▰▰▰▰▰▰▱▱▱▱\033[0m  72%%\n'
pause 0.6
printf '\033[1A\033[2K'
printf '\033[38;5;213m■\033[0m \033[2mrendering frames\033[0m  \033[38;5;177m▰▰▰▰▰▰▰▰▰▰▰▰▰▰\033[0m 100%%\n'
pause 0.3
printf '\033[38;5;46m✓\033[0m wrote \033[38;5;215mdemo.gif\033[0m   \033[2m1200x600 · 38 frames · 184 KB\033[0m\n'
pause 1.6

clear
