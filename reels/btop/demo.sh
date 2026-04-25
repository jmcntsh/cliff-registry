#!/usr/bin/env bash
# btop — resource monitor with extras
#
# Template 1 (scripted fake). btop's signature look is the gradient
# CPU bars and the boxed multi-pane layout. We use truecolor here
# because btop's identity is its theme — the viewer should see
# btop's gradients, not their terminal's idea of colors.

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

prompt; type_line 'btop'
beat
pause 0.3
clear

# btop's gradient: we use a 256-color ramp from teal → green → yellow → red.
printf '\033[1;38;5;213m▼ btop++  v1.4 \033[0m\033[2m  ?  options  q  quit  m  min  esc  toggle \033[0m\n'
printf '┌─cpu────────────────────────────────────────────────────────────────────────┐\n'
printf '│  Apple M3 Pro                                                             │\n'
printf '│  CPU \033[38;5;46m▰▰▰▰▰▰\033[38;5;82m▰▰▰\033[38;5;226m▰\033[38;5;208m▰\033[2m▱▱▱▱▱▱▱\033[0m  47%%   \033[2mfreq 4.05GHz   load 1.2 1.4 1.1\033[0m  │\n'
printf '│  C0  \033[38;5;46m▰▰▰▰▰▰▰\033[38;5;82m▰▰\033[38;5;226m▰\033[38;5;208m▰▰\033[2m▱▱▱▱▱\033[0m  62%%                                       │\n'
printf '│  C1  \033[38;5;46m▰▰▰\033[2m▱▱▱▱▱▱▱▱▱▱▱▱▱\033[0m  18%%                                       │\n'
printf '│  C2  \033[38;5;46m▰▰▰▰\033[38;5;82m▰\033[2m▱▱▱▱▱▱▱▱▱▱▱\033[0m  31%%                                       │\n'
printf '│  C3  \033[38;5;46m▰▰▰▰▰▰▰▰\033[38;5;82m▰▰\033[38;5;226m▰\033[38;5;208m▰▰\033[38;5;196m▰\033[2m▱▱▱\033[0m  77%%                                       │\n'
printf '└────────────────────────────────────────────────────────────────────────────┘\n'
printf '┌─mem────────────────────┬─net──────────────────┬─proc──────────────────────┐\n'
printf '│ used  \033[38;5;46m▰▰▰▰▰▰▰▰▰▰\033[2m▱▱▱▱▱\033[0m  │ \033[38;5;46m↓\033[0m \033[38;5;81m1.2 MB/s\033[0m  ▁▂▃▄▅▆▅▄ │ pid    cmd          cpu%% │\n'
printf '│ swap  \033[38;5;46m▰▰\033[2m▱▱▱▱▱▱▱▱▱▱▱▱▱\033[0m  │ \033[38;5;208m↑\033[0m \033[38;5;81m340 KB/s\033[0m  ▁▁▂▂▃▂▂▁ │ 7421   chrome     \033[38;5;226m24.6\033[0m │\n'
printf '│ disk  \033[38;5;46m▰▰▰▰▰▰\033[2m▱▱▱▱▱▱▱▱▱\033[0m  │                      │ 913    wezterm    \033[38;5;46m13.8\033[0m │\n'
printf '└────────────────────────┴──────────────────────┴───────────────────────────┘\n'
pause 4.0

clear
