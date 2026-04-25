#!/usr/bin/env bash
# superfile — pretty fancy and modern terminal file manager
#
# Template 1 (scripted fake). Superfile's signature is its rounded
# multi-pane layout with a sidebar of pinned places + tabs. We keep
# this scripted to avoid leaking owner/group metadata from the recorder
# account that appears in real captures.

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

prompt; type_line 'spf'
beat
pause 0.3
clear

printf '\033[1;38;5;177m  superfile \033[0m\033[2m  ~/projects/cliff-registry \033[0m\n'
printf '╭─Pinned────╮╭─Files──────────────────────────╮╭─Preview · README.md────────╮\n'
printf '│  ◉ ~      ││ ▸ apps/                        ││ \033[1;35m# cliff-registry\033[0m            │\n'
printf '│    Docs   ││ ▾ reels/                       ││                            │\n'
printf '│    Code   ││   ▸ glow/                      ││ Catalog of CLIs and TUIs    │\n'
printf '│    Music  ││   ▸ cava/                      ││ available through cliff.    │\n'
printf '│           ││   ▾ gum/                       ││                            │\n'
printf '│ ─────     ││     • demo.sh                  ││ \033[1;36m## Submit an app\033[0m            │\n'
printf '│  cliff    ││     • notes.md                 ││                            │\n'
printf '│  reel     ││ \033[7m  ● README.md                  \033[0m││ Open a PR with an entry    │\n'
printf '│           ││   • CNAME                      ││ in `apps/<slug>.toml`.     │\n'
printf '│           ││   • index.json                 ││                            │\n'
printf '│           ││                                ││ \033[1;36m## Reels\033[0m                    │\n'
printf '╰───────────╯╰────────────────────────────────╯╰────────────────────────────╯\n'
printf '\033[2m  ↑↓ navigate    ⏎ open    p pin    /  search    n new    ?  help \033[0m\n'
pause 4.0

clear
