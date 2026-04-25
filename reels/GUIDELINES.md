# Writing demo.sh files for the catalog

Living document. Every catalog app gets a `reels/<slug>/demo.sh` that
`scripts/record-reel.sh` turns into a `reels/<slug>.reel` to play above
its README inside cliff. This file is the durable memory of what we've
learned across batches so the late-batch demos don't re-litigate
decisions the early-batch ones already settled.

Update it after each batch. Promote anything that worked twice; cut
anything that turned out to be wrong.

## The job

A reel is a 6–15 second loop, 80×24, that plays above the app's README
in the cliff TUI. The viewer is one keystroke away from installing
the app and is trying to decide whether to. The reel's job is "show
me what this thing is." Not what it does in detail, not how to
configure it — what it *is*, in the same way a screenshot would.

## Two templates, when each one wins

**Template 1 (scripted fake).** Use when the app is a CLI that prints
and exits, or when the app isn't installed on the recording machine
(true for ~38 of the 44). The demo `printf`s a faithful impression
of what running the real thing would look like. Deterministic, no
network, no environment leakage, tiny frame count.

**Template 2 (real TUI under kill-timer).** Use when the app is a
full-screen TUI *and* it's installed on the recording machine *and*
it does something visually interesting in the first 5–8 seconds with
no input. Audio visualizers, system monitors, animations, games on
their splash screens. `exec` the app, sidecar-kill at N seconds.

If the app would be Template 2 but isn't installed: write a Template 1
fake of its splash/initial-frame instead. Don't block on installing
something just to record a reel.

## Length

6–10 seconds is the target. The reel loops, so 10s with a beat at
the end reads better than 15s racing through three scenes. If the
demo wants more than 12 seconds, cut a scene.

## Size

80×24 unless there's a specific reason otherwise. Use `# SIZE=WxH`
in the demo.sh's header comment to override (e.g. `# SIZE=100x30`
for a TUI whose layout collapses below 100 cols). Wider reels look
worse in cliff's framed strip — the rounded border has a fixed
horizontal breathing room, and over-wide reels visually dominate
the readme that follows. Default is right.

## Anatomy of a Template 1 demo

The canonical helpers (taken from `reel/scripts/demo.sh` and used by
`reels/glow/demo.sh`):

```bash
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
```

Use `type_line` for the *command* (the human input). Use plain
`printf` or a heredoc for the *output* (the machine's response).
Pause briefly after the command to feel like the program is thinking;
longer between scenes than within a scene.

A scene is: `prompt; type_line '<command>'; pause; <output>`.
A demo is 1–3 scenes. End with a `pause` long enough that the loop's
restart doesn't feel jarring, then `clear`.

## Anatomy of a Template 2 demo

```bash
#!/usr/bin/env bash
( sleep 6; kill -TERM $$ ) &
exec <the-tui-binary> <flags>
```

That's the whole script. Pick the kill-timer (5–8s typically) by
running the app once and noticing when its splash settles into
"this is the steady state." The reel should start when the app
opens and end while it's still showing its most representative
frame — not mid-transition.

Notes:
- `exec`, not background. Background loses the pty and the TUI
  can't initialize input.
- `kill $$`, not a tracked child pid. After exec, `$$` is the
  TUI's pid.
- No `timeout(1)` — not portable across macOS/Linux.

## Palette and styling (Template 1 only)

The reel format re-resolves ANSI palette colors against the viewer's
terminal at playback. True-color RGB escapes pass through literally.
What this means for our scripted fakes:

- **Use ANSI palette colors** (`\033[31m`, `\033[1;36m`, etc.) for
  anything that should adapt to the viewer's theme — generic prompts,
  default text emphasis, "this looks like a normal terminal."
- **Use 256-color (`\033[38;5;Nm`) or truecolor (`\033[38;2;R;G;Bm`)
  only when faking a specific app's brand identity** — glow's peach,
  charm pink, btop's gradients. These pass through unchanged so
  every viewer sees the app's look, not their terminal's idea of it.
- Don't over-style. A Template 1 fake that uses 8 colors looks like
  cosplay. Pick the 2–3 most recognizable visual hooks of the real
  app and lean on those.

## Faithfulness bar

Faithful enough to be recognizable, not so faithful that we're
committing to a specific user's config or version. Examples:

- **glow**: rendered the actual glow README (the one shown right
  below the reel), used glow's signature H1-magenta + peach-inline-
  code colors. Faithful and self-referential.
- **bottom (htop-style monitor)**: would be wrong to fake one
  specific user's CPU/temp readout; right to fake the *shape* of
  the layout (columns, sparklines, the blocky-bar aesthetic).
- **a game**: fake the splash screen / title card / first move,
  not a specific playthrough.

If the app's pitch is its theme (charm tools, btop), keep the
brand colors. If the app's pitch is its function (a CLI that does
X), let the colors fall back to ANSI.

## Content sources

Every manifest has a `readme = "https://..."` URL. That's the input.
Read the README, identify:

1. The one-sentence pitch (often in the first paragraph or the
   description block).
2. The most-shown example (the one most documentation pages lead
   with — usually the canonical use case).
3. Any visual hook the README itself emphasizes (a gif, a screenshot
   description, an ASCII art logo).

Build the demo around #2, framed by #1, and steal whatever ASCII or
color signature #3 implies.

## What not to put in a demo

- Network calls. Even in Template 2. Recording is supposed to be
  reproducible.
- Real credentials, hostnames, paths from the recording machine.
  Use placeholder data (`~/projects`, `me@server`).
- Long error messages or warnings. If the real app prints them,
  fake a clean run.
- More than ~3 scenes. The reel loops; the viewer doesn't need
  the whole tour, just the hook.

## Recording

```bash
scripts/record-reel.sh <slug>            # uses default 80x24
scripts/record-reel.sh <slug> 100x30     # override size
```

The script clobbers any existing `reels/<slug>.reel` so re-recording
is one command. Source of truth is the demo.sh; the .reel is a
regenerable artifact.

Per-demo headers supported by `record-reel.sh`:

- `# SIZE=WxH` — preferred recording size for that app.

## Decision log

Notes added after each batch, capturing what we changed our minds
about. Most recent first.

### Batch 2 (cliff, reel, scope-tui, minesweep, weathr) — 2026-04-25

- Confirmed: 5 templates 2 + 3 templates 1 in one sweep recorded clean
  on first try. Pipeline is solid.
- weathr: real `weathr --simulate rain --hide-location --metric --silent`
  produced 228 frames in 8s — beautiful animated rain. But on first
  recording it leaked the recorder's home path via a "config not found
  at /Users/<you>/Library/Application Support/weathr/..." warning.
  Fix: redirect stderr to /dev/null. New rule: any Template 2 binary
  that prints config/path warnings on first run gets `2>/dev/null`
  appended to the exec line.
- cliff: even though cliff itself embeds a reel, the manifest still
  needs a `reels/cliff.reel` so the URL-based fetcher we're building
  has a uniform expectation across all 44 apps. Wrote a Template 1
  fake of the cliff browser UI rather than running real cliff
  (which does network fetches at startup).
- scope-tui: real binary needs an audio backend or file source — both
  would either capture the recorder's actual audio (privacy) or look
  flat (boring). Hand-drew a representative oscilloscope wave instead.
  General rule: if a TUI requires environmental input (audio, files,
  network, credentials) to look like itself, fake it.
- minesweep: 1-frame static capture. Acceptable per Batch 1 decision;
  the grid + keys legend reads as "this is minesweeper" instantly.

### Batch 1 (gum, bottom, yazi, gitui, balatro-tui) — 2026-04-25

- Confirmed: 5-app mixed batch is the right calibration size. We
  caught one major template mistake early (real yazi capture quality)
  and corrected before it could repeat across many apps.
- Updated Template 2 rule: even if the app is installed, only use real
  capture when the recorded output is clean under `reel record`.
  If the app emits terminal capability warnings or noisy control output
  in the recording environment, fall back to Template 1 fake.
- Visual-identity apps (file managers, games) should default to real
  capture whenever possible. Hand-drawn fakes for these were called out
  as inaccurate in review.
- Privacy: never point file-manager demos at the recorder's real
  directories. Build a synthetic sandbox tree under `mktemp -d` and
  capture from there. Set `HOME=$tmp_home` and `cd` into it so visible
  paths read as `~/<sandbox>` rather than `/Users/<you>/...`.
- One-frame static-capture Template 2 is acceptable for visual-identity
  TUIs whose first painted frame is representative of the app. Driving
  keystrokes via `expect` is possible (reel docs cover it) but is
  intentionally out of scope for this pass — we keep the pipeline
  simple and accept "looks like a screenshot of the real app, held
  for a few seconds" as the bar for input-heavy TUIs.
- yazi specifically: switched from real capture to scripted fake
  because of terminal response timeout noise. Result is much cleaner
  and still recognizable (tree/files/preview layout + key hints).
- Timing: long typed commands inflate reel duration. Keep typewriter
  speed at `0.02` when command lines are long, and bias toward a single
  concise scene for utility CLIs. `gum` improved from 15s to 10s.
- Layout: for dashboard/game/TUI fakes (`bottom`, `gitui`,
  `balatro-tui`), one stable "hero frame" with subtle context beats
  multiple fast scene cuts in a short loop.

### Batch 0 (pilot: glow, cava) — 2026-04-25

- Confirmed: 80x24 default, ~9s for Template 1, ~6s for Template 2.
- glow: rendering the app's *own* README inside the demo is better
  than rendering an unrelated fake doc. Reinforces "this is what
  you're about to see this app do to the README right below."
- cava: real binary under kill-timer worked first try with no
  size override. Default 80x24 is fine for bar visualizers.
- record-reel.sh: needs `rm -f` on the output before recording
  because reel refuses to clobber. Added.
