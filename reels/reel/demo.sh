#!/usr/bin/env bash
# reel — terminal session recorder
#
# Template 1 (scripted fake). Reel records and plays terminal sessions;
# the value is "record once, replay anywhere as a tiny .reel file."
# We show the round-trip: record → replay, with the artifact size as
# the kicker.

pause() { sleep "${1:-0.8}"; }
beat()  { sleep "${1:-0.3}"; }

type_line() {
  local s="$1" i
  for (( i=0; i<${#s}; i++ )); do
    printf '%s' "${s:$i:1}"
    sleep 0.03
  done
  printf '\n'
}

prompt() { printf '\033[2m$\033[0m '; }

clear
pause 0.5

prompt; type_line 'reel record demo.reel'
beat
printf '\033[2mrecording → demo.reel  (exit subshell to stop)\033[0m\n'
pause 0.5
prompt; type_line 'echo "hello, reel"'
beat
printf 'hello, reel\n'
pause 0.4
prompt; type_line 'exit'
beat
printf '\033[2mwrote demo.reel  (12 frames, 1.4s, 4.1 KB)\033[0m\n'
pause 0.7

prompt; type_line 'reel play demo.reel'
beat
pause 0.3
prompt; type_line 'echo "hello, reel"'
beat
printf 'hello, reel\n'
pause 1.4

clear
