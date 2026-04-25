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
  printf '
'
}

prompt() { printf '[2m$[0m '; }

clear
pause 0.5

prompt; type_line 'btop'
beat
pause 0.3
clear

# btop's gradient: we use a 256-color ramp from teal → green → yellow → red.
printf '[1;38;5;213m▼ btop++  v1.4 [0m[2m  ?  options  q  quit  m  min  esc  toggle [0m
'
printf '┌─cpu────────────────────────────────────────────────────────────────────────┐
'
printf '│  Apple M3 Pro                                                             │
'
printf '│  CPU [38;5;46m▰▰▰▰▰▰[38;5;82m▰▰▰[38;5;226m▰[38;5;208m▰[2m▱▱▱▱▱▱▱[0m  47%%   [2mfreq 4.05GHz   load 1.2 1.4 1.1[0m  │
'
printf '│  C0  [38;5;46m▰▰▰▰▰▰▰[38;5;82m▰▰[38;5;226m▰[38;5;208m▰▰[2m▱▱▱▱▱[0m  62%%                                       │
'
printf '│  C1  [38;5;46m▰▰▰[2m▱▱▱▱▱▱▱▱▱▱▱▱▱[0m  18%%                                       │
'
printf '│  C2  [38;5;46m▰▰▰▰[38;5;82m▰[2m▱▱▱▱▱▱▱▱▱▱▱[0m  31%%                                       │
'
printf '│  C3  [38;5;46m▰▰▰▰▰▰▰▰[38;5;82m▰▰[38;5;226m▰[38;5;208m▰▰[38;5;196m▰[2m▱▱▱[0m  77%%                                       │
'
printf '└────────────────────────────────────────────────────────────────────────────┘
'
printf '┌─mem────────────────────┬─net──────────────────┬─proc──────────────────────┐
'
printf '│ used  [38;5;46m▰▰▰▰▰▰▰▰▰▰[2m▱▱▱▱▱[0m  │ [38;5;46m↓[0m [38;5;81m1.2 MB/s[0m  ▁▂▃▄▅▆▅▄ │ pid    cmd          cpu%% │
'
printf '│ swap  [38;5;46m▰▰[2m▱▱▱▱▱▱▱▱▱▱▱▱▱[0m  │ [38;5;208m↑[0m [38;5;81m340 KB/s[0m  ▁▁▂▂▃▂▂▁ │ 7421   chrome     [38;5;226m24.6[0m │
'
printf '│ disk  [38;5;46m▰▰▰▰▰▰[2m▱▱▱▱▱▱▱▱▱[0m  │                      │ 913    wezterm    [38;5;46m13.8[0m │
'
printf '└────────────────────────┴──────────────────────┴───────────────────────────┘
'
pause 4.0

clear
