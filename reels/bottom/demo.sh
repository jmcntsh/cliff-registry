#!/usr/bin/env bash
# bottom (btm) — process/system monitor
#
# Template 2 (real TUI capture). Real bottom immediately communicates its
# product shape on first paint, so a static hold is enough.

# SIZE=100x30

( sleep 8; kill -TERM $$ ) &
exec btm 2>/dev/null
