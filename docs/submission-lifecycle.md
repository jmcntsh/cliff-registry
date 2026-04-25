# Submission lifecycle

This defines a submit-now, enrich-later flow for authors and an
exception-only review flow for maintainers.

## Goals

- Minimize first-submit effort for authors.
- Publish useful listings quickly.
- Keep maintainer effort focused on edge cases.
- Support `.reel` enrichment after initial listing.

## Listing states

- `draft`: submission exists, no manifest merged.
- `provisional`: manifest merged with required core fields.
- `verified`: `.reel` provided and metadata validated.

## Author workflow

1. Submit repository URL.
2. Optionally add name, description, install details, and `.reel`.
3. Automation opens a draft PR when data is sufficient.
4. Author adds missing metadata and `.reel` later.
5. Maintainer promotes listing to `verified`.

## Maintainer workflow

1. Review new submission issue.
2. Accept automation draft PR or request missing install details.
3. Merge provisional manifest when lint passes.
4. Apply follow-up PR for `.reel` and metadata enrichment.

## Automation behavior

Workflow: `.github/workflows/submission-auto-pr.yml`

- Trigger: issue opened, edited, reopened, or labeled `submission`
- Reads issue-form fields
- Normalizes repo input to `owner/repo`
- Fetches repo metadata from GitHub API
- Infers install type from explicit input or repository files
- Writes `apps/<slug>.toml` and runs registry lint
- Opens a draft PR when ready
- Comments on the issue when additional input is required

Workflow: `.github/workflows/submission-reel-promote.yml`

- Trigger: submission issue edited/reopened/labeled
- Reads `.reel` field from the issue form
- Finds `apps/<slug>.toml` from submitted name/repo
- Adds or updates `demo = "..."` from the `.reel` link
- Runs lint and opens/updates a draft promotion PR

## Minimum requirements

`provisional` requires schema-valid manifest fields:

- `name`
- `description`
- `author`
- `homepage`
- `[install]` block

`verified` additionally requires:

- `.reel` details linked or added in registry workflow
- lint-valid metadata updates

## Policy notes

- Missing `.reel` does not block provisional listing.
- Missing optional metadata does not block provisional listing.
- Security reports are handled via delisting in next index publish.
