#!/usr/bin/env bash
# cava — Cross-platform bar spectrum audio visualizer
#
# Template 2 (real TUI under a kill-timer). Cava's only job is to
# look good while bouncing to audio; a scripted fake of bouncing
# bars would be both more work and less honest than just running
# the real thing for a few seconds.
#
# The bars only move when there's audio. On a recording machine
# with no playing audio, cava renders a static spectrum (which is
# still more illustrative than a fake), and on a machine that does
# have audio — the recommended setup — they bounce. Either way the
# viewer sees real cava.

# SIZE=80x24

# Sidecar kill-timer: end the recording on its own after 6s so
# the resulting reel is README-friendly (short, looped). $$ is the
# script's pid, which after the exec below is cava's pid.
( sleep 6; kill -TERM $$ ) &

# exec, not background, so cava inherits reel's pty directly and
# can read its own input / paint to its own alt screen.
exec cava
