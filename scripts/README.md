# Seeding scripts

This directory holds tools that maintain `cliff-registry` automatically.

## `seed.py` — automated catalog expansion

Runs nightly via `.github/workflows/auto-seed.yml`. Pulls candidate
CLI/TUI repos from GitHub Search, filters out non-apps, and emits ready-
to-lint TOML manifests for the `apps/` directory.

The TUI's hotness algorithm does the real curation. This script's job
is to keep the funnel topped up; it is intentionally permissive.

### Local usage

```sh
python3 scripts/seed.py --dry-run --apps-dir apps --ledger scripts/seen-ledger.json
```

Useful flags:

- `--min-stars 20` — lower bound for the GitHub Search query.
- `--max-new 20` — cap on manifests emitted per run.
- `--dry-run` — score and report; do not write manifests or update ledger.
- `--no-verify-registry` — skip the HEAD checks against PyPI/npm/crates.io.

### Outputs

All under `--out-dir` (default `/tmp/seed`):

- `manifests/*.toml` — new app manifests, ready to copy into `apps/`.
- `candidates.json` — every repo evaluated this run, with the verdict.
- `review.csv` — same data, spreadsheet-friendly.
- `ledger.next.json` — proposed updated ledger (the script writes this
  back to `--ledger` unless `--dry-run` is set).

## `seen-ledger.json` — persistent memory

Records every repo the seeder has ever evaluated, so each run only does
work on truly new candidates. Format:

```json
{
  "version": 1,
  "updated_at": "<ISO8601 UTC>",
  "entries": {
    "owner/repo": {
      "decision": "accepted" | "rejected" | "deferred",
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
- `rejected` — failed a check (category, install mapping, package
  verification). The `reason` field tags which one.
- `deferred` — would have been accepted but hit `--max-new` cap; will
  be retried next run.

To force re-evaluation of a repo, delete its entry from the ledger.
