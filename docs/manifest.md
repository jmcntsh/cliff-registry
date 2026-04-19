# Manifest schema (v0)

Each app is one TOML file under `apps/<name>.toml`. Filename
must match `name`.

## Required

- `name` — kebab-case, matches `[a-z0-9][a-z0-9-]*`.
- `description` — one sentence, ≤120 chars.
- `author` — GitHub user or org.
- `homepage` — http(s) URL. If on github.com, `Repo` is derived
  from the path.
- `[install]` table:
  - `type` — one of `brew`, `cargo`, `npm`, `pipx`, `go`, `script`.
  - `package` — required for non-script types.
  - `command` — required for `type = "script"`; the exact shell
    command shown to the user in the install confirm modal.
  - `global` — `npm` only; passes `-g`.

## Optional

- `readme` — http(s) URL to a raw README; rendered in-TUI.
- `demo` — http(s) URL to an asciinema cast (Phase 3).
- `screenshots` — array of http(s) URLs (Phase 3).
- `tags` — lowercase only.
- `license` — SPDX identifier.
- `category` — free-form; defaults to `"Other"`.
- `language` — display only.

## Example

```toml
name = "lazygit"
description = "Simple terminal UI for git commands"
author = "jesseduffield"
homepage = "https://github.com/jesseduffield/lazygit"
readme = "https://raw.githubusercontent.com/jesseduffield/lazygit/master/README.md"
tags = ["git", "tui"]
license = "MIT"
category = "Version control"
language = "Go"

[install]
type = "brew"
package = "lazygit"
```

## Validation

`go run ./cmd/lint ./apps` — exit 0 if all pass.

CI runs the same on every PR.
