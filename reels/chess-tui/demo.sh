#!/usr/bin/env bash
# chess-tui — terminal chess game
#
# Template 2 (real TUI capture). The opening board is immediately
# recognizable and deterministic.

# SIZE=100x30

( sleep 8; kill -TERM $$ ) &
exec chess-tui 2>/dev/null
