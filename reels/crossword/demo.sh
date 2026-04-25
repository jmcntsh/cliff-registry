#!/usr/bin/env bash
# crossword — crossword puzzle game in terminal
#
# Template 2 (real TUI capture). The board view is the product.

# SIZE=100x30

( sleep 8; kill -TERM $$ ) &
exec crossword 2>/dev/null
