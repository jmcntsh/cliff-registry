# Seeding scripts

## `seed.py` — automated catalog expansion

Runs Mondays via `.github/workflows/auto-seed.yml`. Searches GitHub for
new CLI/TUI repos, evaluates them against a small category filter,
writes manifests directly into `apps/`, runs `cmd/lint`, and (in
`--commit` mode) commits + pushes the result to `main`.

The TUI's hotness algorithm does the real curation post-merge. This
script's job is to keep the funnel topped up.

### Local usage

```sh
# Preview only — touches nothing.
python3 scripts/seed.py --dry-run

# Write manifests into apps/, run lint, commit + push to main.
python3 scripts/seed.py --commit

# Same as --commit but stop short of `git push` (for inspection).
python3 scripts/seed.py --commit --dry-push
```

Useful flags:

- `--min-stars 20` — lower bound for the Search query.
- `--max-new 20` — cap on new manifests emitted per run.
- `--full-scan` — ignore the recency fast-path; scan all topics.
- `--no-verify-registry` — skip HEAD checks against PyPI/npm/crates.io.

### How a run is shaped

1. Load `scripts/seen-ledger.json` (or start empty).
2. Take its `updated_at` timestamp; pass `pushed:>=<that date - 1 day>`
   to GitHub Search. Most weeks this returns a small handful of repos.
3. Skip anything in the ledger or already in `apps/` by homepage.
4. For survivors: category-check, suggest an install type, optionally
   HEAD-check the package registry, render a manifest.
5. With `--commit`: shell out to `go run ./cmd/lint ./apps`. If lint
   fails, delete the manifests this run wrote and exit non-zero. If
   lint passes, update the ledger, `git add`, commit, push.

The recency fast-path means a "nothing changed" Monday completes in
seconds without any disk writes.

## `seen-ledger.json` — persistent memory

Records every repo the seeder has reached a TERMINAL verdict on
(`accepted` or `rejected`). Format:

```json
{
  "version": 1,
  "updated_at": "<ISO8601 UTC>",
  "entries": {
    "owner/repo": {
      "decision": "accepted" | "rejected",
      "reason": "<short tag>",
      "install_type": "go" | "cargo" | "pipx" | "npm" | "",
      "first_seen": "YYYY-MM-DD",
      "last_seen": "YYYY-MM-DD"
    }
  }
}
```

Decisions:

- `accepted` — passed all checks; manifest was emitted.
- `rejected` — failed category check, had no install mapping, or its
  package wasn't published. The `reason` field tags which.

`deferred` (would-have-been-accepted-but-hit-cap) is **not** ledgered;
those repos remain re-evaluable on the next run.

To force re-evaluation of a single repo, delete its entry from the
ledger and re-run the seeder. To force a full rescan ignoring the
recency filter, run with `--full-scan`.
