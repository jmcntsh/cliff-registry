# cliff-registry

App manifests for [cliff](https://cliff.sh).

CI compiles `apps/*.toml` into `index.json` and publishes it to
<https://registry.cliff.sh/index.json>, which the cliff client
fetches.

## How apps get in

A scheduled scraper (`scripts/seed.py`, run weekly by
`.github/workflows/auto-seed.yml`) searches GitHub for new TUIs and
terminal apps, filters out non-apps (libraries, awesome-lists,
templates), maps each repo's language to an install method, verifies
the package is actually published, and commits the resulting manifests
to `main`. The next index build ships them to every client.

There is no submission queue. To add an app the scraper missed, or fix
a manifest:

1. Fork.
2. Add or edit a TOML file under `apps/<name>.toml`. See the existing
   manifests for shape; full schema in
   [`docs/manifest.md`](docs/manifest.md).
3. `go run ./cmd/lint ./apps` to validate locally.
4. Open a PR. CI runs lint; on merge, `index.json` rebuilds and
   ships.

## Layout

```
apps/                  one TOML manifest per app
cmd/lint/              manifest validator (also CI)
cmd/build/             compiles apps/*.toml + GitHub stars/last-commit → index.json
cmd/scan-methods/      housekeeping: report likely-missing install methods
internal/manifest/     TOML schema + validation
internal/index/        wire types for index.json (mirrors the client's catalog types)
scripts/seed.py        the GitHub scraper (see scripts/README.md)
.github/workflows/     lint on PR; build + Pages publish on merge; weekly auto-seed
```

## Trust model

cliff is a directory. We don't sandbox or audit listed apps.
Installs run with the user's shell privileges, the same way `brew
install <foo>` does. If a listed app is credibly reported as
malicious it gets delisted on the next index build — minutes, not
days. That's the remedy.
