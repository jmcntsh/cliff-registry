#!/usr/bin/env bash
# rebels-in-the-sky — terminal game
#
# Template 2 (real TUI capture). Show the real opening screen/board
# instead of a scripted approximation.

# SIZE=100x30

( sleep 8; kill -TERM $$ ) &
exec rebels 2>/dev/null
