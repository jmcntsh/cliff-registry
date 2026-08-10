# Star snapshots

CI writes timestamped `YYYY-MM-DDTHHMMSSZ.json` observations at least once per
UTC day. These generated files are the durable source for the 7-day and 30-day
net GitHub star-growth fields in `index.json`.

Do not hand-edit snapshot files. See [`../../docs/hot-rankings.md`](../../docs/hot-rankings.md)
for metric and failure semantics.
