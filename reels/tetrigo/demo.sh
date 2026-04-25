#!/usr/bin/env bash
# tetrigo — tetris in terminal
#
# Template 2 (real TUI capture). Splash/board frame is enough to
# communicate gameplay style.

# SIZE=100x30

( sleep 8; kill -TERM $$ ) &
exec tetrigo 2>/dev/null
