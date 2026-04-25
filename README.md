# cliff-registry

App manifests for [cliff](https://cliff.sh).

CI compiles `apps/*.toml` into `index.json` and publishes it to
<https://registry.cliff.sh/index.json>, which the cliff client
fetches.

## Add an app

Fastest path:

1. Open a submission issue with a repo URL:
   - `https://github.com/jmcntsh/cliff-registry/issues/new?template=new-app.yml`
   - or from CLI: `cliff submit <owner/repo>`
2. Automation opens a draft provisional PR when it can infer install details.
3. Add `.reel` later to promote the listing to verified.

Manual path:

1. Fork.
2. Add a TOML file under `apps/<name>.toml`. See the existing
   manifests for shape; full schema in
   [`docs/manifest.md`](docs/manifest.md).
3. `go run ./cmd/lint ./apps` to validate locally.
4. Open a PR. CI runs lint; on merge, `index.json` rebuilds and
   ships.

See [`docs/submission-lifecycle.md`](docs/submission-lifecycle.md) for
state rules and maintainer policy.

## Layout

```
apps/                  one TOML manifest per app
cmd/lint/              manifest validator (also CI)
cmd/build/             compiles apps/*.toml + GitHub stars/last-commit → index.json
internal/manifest/     TOML schema + validation
internal/index/        wire types for index.json (mirrors the client's catalog types)
.github/workflows/     lint on PR; build + Pages publish on merge to main
```

## Trust model

cliff is a directory. We don't sandbox or audit listed apps.
Installs run with the user's shell privileges, the same way `brew
install <foo>` does. If a listed app is credibly reported as
malicious it gets delisted on the next index build — minutes, not
days. That's the remedy.
