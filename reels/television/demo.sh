#!/usr/bin/env bash
# television — fast terminal fuzzy finder
#
# Template 2 (real TUI capture). Initial prompt + layout communicates
# the product without requiring real local index data.

# SIZE=100x30

( sleep 8; kill -TERM $$ ) &
exec tv 2>/dev/null
