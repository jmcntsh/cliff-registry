#!/usr/bin/env bash
# glow — Render markdown on the CLI, with pizzazz
#
# Template 1 (scripted fake). Glow's whole pitch is "your README, but
# rendered nicely in the terminal." So the demo is: cat a raw README
# (ugly), then `glow` the same file (pretty). Side-by-side in one
# short arc with no commentary; the contrast is the whole sell.
#
# The README we render is glow's own — the viewer is about to read it
# right below this reel inside cliff, so showing glow rendering its
# own readme is both honest and reinforces "this is what you'll get
# when you point glow at any README." Kept short (one section + a
# code fence + a list) because a faithful full-README render would
# be 80+ rows tall and the reel canvas is 80x24.
#
# We don't shell out to a real glow because (a) it might not be on
# the recording machine and (b) a curated fake is deterministic
# across re-records. The styled output below is hand-tuned to look
# like glow's default "auto" theme without copying any specific
# palette verbatim — close enough to convey the idea.

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

# Act 1: the raw markdown. Plain, dense, hard to scan. This is what
# README.md looks like when you `cat` it — exactly the experience
# glow is built to replace.
prompt; type_line 'cat README.md'
beat
cat <<'EOF'
# Glow

Render markdown on the CLI, with _pizzazz_!

## What is it?

Glow is a terminal based markdown reader designed from the
ground up to bring out the beauty—and power—of the CLI.

## Installation

```
brew install glow
```

Or with go:

- `go install github.com/charmbracelet/glow/v2@latest`
- pre-built binaries on the releases page
- packages for apt, dnf, pacman, snap, and more
EOF
pause 2.2

# Act 2: same file, through glow. The headings get color and weight,
# the code fence gets a subtle background, the bullets get re-marked.
# This is where the viewer goes "oh, that's the difference."
prompt; type_line 'glow README.md'
beat
pause 0.4

printf '\n'

# H1: bold magenta with a leading bar. Glow's default H1 style is
# distinctive and instantly recognizable to anyone who's used it.
printf '  \033[1;35m# Glow\033[0m\n'
printf '\n'
printf '  Render markdown on the CLI, with \033[3mpizzazz\033[0m!\n'
printf '\n'

# H2s: bold cyan, slightly less prominent than H1.
printf '  \033[1;36m## What is it?\033[0m\n'
printf '\n'
printf '  Glow is a terminal based markdown reader designed from the\n'
printf '  ground up to bring out the beauty—and power—of the CLI.\n'
printf '\n'

printf '  \033[1;36m## Installation\033[0m\n'
printf '\n'
# Code fence: rendered as an indented block with a muted background.
# We use a dim bg via 48;5;236 (near-black) to suggest the chrome
# without overcommitting to one terminal's idea of "code block."
printf '    \033[48;5;236;38;5;252m brew install glow               \033[0m\n'
printf '\n'
printf '  Or with go:\n'
printf '\n'
# Bullets: glow swaps `-` for a styled glyph and indents the body.
printf '  \033[35m•\033[0m \033[38;5;215mgo install github.com/charmbracelet/glow/v2@latest\033[0m\n'
printf '  \033[35m•\033[0m pre-built binaries on the releases page\n'
printf '  \033[35m•\033[0m packages for apt, dnf, pacman, snap, and more\n'
printf '\n'
pause 4.0

clear
