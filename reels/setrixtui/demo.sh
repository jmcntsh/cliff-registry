#!/usr/bin/env bash
# setrixtui — set/logic puzzle game in terminal
#
# Template 2 (real TUI capture). Real gameplay frame is clearer than
# a hand-drawn approximation.

# SIZE=100x30

( sleep 8; kill -TERM $$ ) &
exec setrixtui 2>/dev/null
