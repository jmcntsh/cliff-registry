#!/usr/bin/env bash
# dooit — tiny habit/task TUI
#
# Template 2 (real TUI capture). Fresh state is representative and
# contains no machine-specific data.

# SIZE=100x30

( sleep 8; kill -TERM $$ ) &
exec dooit 2>/dev/null
