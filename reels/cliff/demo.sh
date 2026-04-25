#!/usr/bin/env bash
# cliff — terminal-native directory for CLIs and TUIs
#
# Template 1 (scripted fake). Cliff already has its own embedded
# `cliffdemo.reel` that plays above its own README — but the registry
# manifest needs a reel too so the URL-based fetcher we're building
# has a uniform expectation across all 44 apps. This is that file.
#
# We mirror the cliff browse-mode UI: the left list of apps, the
# right pane with a rendered README, and the status footer.

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
pause 0.6

prompt; type_line 'cliff'
beat
pause 0.3
clear

# Header + two-column body + footer. The left column is a curated
# scroll of recognizable catalog entries; the right column is a
# scrap of the highlighted app's rendered README.
printf '\033[1;38;5;213m cliff \033[0m\033[2m  44 apps  ·  /search  ·  ↑↓ navigate  ·  enter install \033[0m\n'
printf '┌────────────────────┬───────────────────────────────────────────────────────┐\n'
printf '│ \033[7m glow             \033[0m │ \033[1;35m# Glow\033[0m                                                │\n'
printf '│   gum              │                                                       │\n'
printf '│   bottom           │   Render markdown on the CLI, with \033[3mpizzazz\033[0m!            │\n'
printf '│   yazi             │                                                       │\n'
printf '│   gitui            │ \033[1;36m## Use it\033[0m                                             │\n'
printf '│   lazygit          │                                                       │\n'
printf '│   atuin            │   \033[35m•\033[0m \033[38;5;215mglow README.md\033[0m                                  │\n'
printf '│   television       │   \033[35m•\033[0m \033[38;5;215mglow github.com/charmbracelet/glow\033[0m              │\n'
printf '│   posting          │   \033[35m•\033[0m \033[38;5;215mglow -p\033[0m  \033[2m# pager mode\033[0m                          │\n'
printf '│   harlequin        │                                                       │\n'
printf '│   btop             │ \033[1;36m## Install\033[0m                                            │\n'
printf '│   cava             │                                                       │\n'
printf '│   weathr           │     \033[48;5;236;38;5;252m brew install glow                          \033[0m  │\n'
printf '│   superfile        │                                                       │\n'
printf '│   ...              │                                                       │\n'
printf '└────────────────────┴───────────────────────────────────────────────────────┘\n'
printf '\033[2m i install   u uninstall   r readme   s submit   ? help   q quit \033[0m\n'
pause 4.0

clear
