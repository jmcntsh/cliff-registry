#!/usr/bin/env bash
# atac — terminal API client
#
# Template 2 (real TUI capture). Startup dashboard is enough to show
# what the product is, even without loading a collection.

# SIZE=100x30

( sleep 8; kill -TERM $$ ) &
exec atac 2>/dev/null
