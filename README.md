# cliff-registry

App manifests for [cliff](https://cliff.sh).

CI compiles `apps/*.toml` into `index.json` and publishes it to
<https://registry.cliff.sh/index.json>, which the cliff client
fetches. A daily workflow records public GitHub star-count snapshots
and publishes static 7-day and 30-day net-growth rankings; it does not
collect Cliff usage or user telemetry.

## How apps get in

A scheduled scraper (`scripts/seed.py`, run weekly by
`.github/workflows/auto-seed.yml`) searches GitHub for new TUIs, CLIs,
terminal games, and visual terminal apps, filters out non-apps (libraries, awesome-lists,
templates), maps each repo's language to an install method, verifies
the package is actually published, and commits the resulting manifests
to `main`. The same workflow then rebuilds and publishes `index.json`
from the new commit. This explicit publish step is required because
GitHub does not start another workflow for a push made with
`GITHUB_TOKEN`.

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
internal/stars/        GitHub metadata client + deterministic growth calculation
data/stars/            generated, timestamped star-count observations
scripts/seed.py        the GitHub scraper (see scripts/README.md)
.github/workflows/     lint on PR; daily build + Pages publish; weekly auto-seed
```

The `registry` workflow also supports manual dispatch, which can
republish the current `main` branch without changing the catalog.
Ranking semantics and failure handling are defined in
[`docs/hot-rankings.md`](docs/hot-rankings.md).

## Trust model

cliff is a directory. We don't sandbox or audit listed apps.
Installs run with the user's shell privileges, the same way `brew
install <foo>` does. If a listed app is credibly reported as
malicious it gets delisted on the next index build — minutes, not
days. That's the remedy.
