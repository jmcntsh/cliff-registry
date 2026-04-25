#!/usr/bin/env bash
# minesweep — minesweeper in your terminal
#
# Template 2 (real TUI capture). Minesweeper's whole UI is the grid;
# the real binary draws it instantly with no network or env coupling,
# so we just run it for a few seconds.

# SIZE=80x24

( sleep 7; kill -TERM $$ ) &
exec minesweep
