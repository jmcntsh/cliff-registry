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

## Add a reel for your app

If you've already recorded a `.reel` for an app you maintain:

1. Fork this repo.
2. Drop your file at `reels/<slug>.reel` (where `<slug>` is the
   manifest filename without `.toml`). GitHub's web UI accepts
   drag-and-drop into the file editor — no clone required.
3. Open a PR.

CI checks whether your GitHub account is a collaborator on the
repo named in the manifest's `homepage` field. If yes, the PR
gets an `attested-owner` label and a maintainer can merge on
sight. If no, the PR is held for manual review — not rejected,
just slower. Either way, leave a comment with anything reviewers
should know (e.g. "I'm a maintainer of `org/foo` but not a public
member of the org; here's a link to my recent commits").

There's no `cliff record` subcommand to learn. Bring a `.reel`,
drop it in, done. See `scripts/record-reel.sh` for how the
existing reels were captured if you need a recipe.

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
