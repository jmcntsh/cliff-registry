#!/usr/bin/env bash
# balatro-tui — balatro-inspired poker roguelike
#
# Template 2 (real TUI capture). The game's visual identity is the
# product, so use real frames now that balatro_tui is installed.

# SIZE=100x30

# Keep the reel short and loopable.
# Minimum target for visual-first apps is 5s; we use 8s here.
( sleep 8; kill -TERM $$ ) &
exec balatro_tui
