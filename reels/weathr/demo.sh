#!/usr/bin/env bash
# weathr — terminal-based ASCII weather animation
#
# Template 2 (real TUI capture). Weathr's product is the animation:
# rain falling in ASCII, the sky color transitioning, particles drifting.
# A scripted fake of motion would feel dead; the real thing for a few
# seconds shows what it actually does.
#
# We pin the simulation flags so the recording is deterministic:
#   --simulate rain    fixed scene, no network call to fetch real weather
#   --hide-location    no coords on screen
#   --metric           units consistent across recording machines
#   --silent           suppress non-error stdout
# No --auto-location flag → no IP geolocation network call at startup.
#
# stderr → /dev/null because weathr prints a "config not found at
# /Users/<you>/Library/Application Support/weathr/config.toml" warning
# on first run, which would leak the recorder's home path into the reel.

# SIZE=100x30

( sleep 8; kill -TERM $$ ) &
exec weathr --simulate rain --hide-location --metric --silent 2>/dev/null
