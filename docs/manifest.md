# Manifest schema (v0)

Each app is one TOML file under `apps/<name>.toml`. The filename
must match `name`.

Manifests describe the app and how cliff should install it. They do
not describe pricing, sellers, hosted binaries, or accounts.

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

Use `[[installs]]` when an app supports more than one package manager:

```toml
[[installs]]
type = "brew"
package = "glow"

[[installs]]
type = "go"
package = "github.com/charmbracelet/glow@latest"
```

## Required

- `name` — kebab-case, matches `[a-z0-9][a-z0-9-]*`; must match the filename.
- `description` — one sentence, 120 characters or fewer.
- `author` — GitHub user or org when possible.
- `homepage` — `http` or `https` URL. If it is on GitHub, the index builder derives `repo` from the URL path.
- Exactly one install declaration: `[install]` for a single method, or `[[installs]]` for multiple methods.

## Optional

- `readme` — `http` or `https` URL to a raw README; rendered in the TUI.
- `demo` — `http` or `https` URL for an external demo artifact.
- `screenshots` — array of `http` or `https` URLs.
- `tags` — lowercase tags.
- `license` — SPDX identifier when known.
- `category` — free-form; defaults to `"Other"`.
- `language` — display only.
- `binary` — installed executable name when it does not match the repo basename.
- `[uninstall]` — command override for uninstall; required when any install method has `type = "script"`.
- `[upgrade]` — command override for upgrade; optional.

Demo reels are added separately as `reels/<name>.reel`. During index
build, the registry sets `has_reel = true` for apps with a matching
reel file.

## Install methods

Each install method has:

- `type` — one of `brew`, `cargo`, `npm`, `pipx`, `go`, `script`.
- `package` — required for non-script types.
- `command` — required for `type = "script"`; invalid for non-script types.
- `global` — `npm` only; passes `-g`.

Order matters for `[[installs]]`. The client picks the first method
whose tool is available, unless the user passes an explicit `--via
<type>` override. Duplicate method types are rejected.

## Uninstall and upgrade

For `brew`, `cargo`, `npm`, `pipx`, and `go`, cliff derives uninstall
and upgrade commands automatically. Use top-level blocks only when the
derived command is wrong:

```toml
[uninstall]
command = "brew uninstall --force lazygit"

[upgrade]
command = "brew upgrade lazygit"
```

For `script` installs, `[uninstall]` is required because there is no
general reverse for an arbitrary shell script. `[upgrade]` is optional;
without it, `cliff upgrade` reports that no upgrade recipe exists.

## Validation

`go run ./cmd/lint ./apps` exits 0 if all manifests pass.

CI runs the same on every PR.
