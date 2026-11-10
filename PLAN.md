# FitTrack data quality assignment

Use JavaScript, Playwright Test and node-postgres (`pg`) for the database checks. Playwright Test runs the suite without a browser. Use the standard `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` and `PGPASSWORD` variables. The planned entry point is `npm test`.

Commit this plan and its updates to the NIBBANA-task repository. Present implementation changes and verification results to Olga for review and wait for her approval before committing or pushing them.

## Skills

- Playwright Best Practices for fixtures, assertions and test reporting.
- Supabase Postgres Best Practices for SQL and query plan review.
- Verification Before Completion for rerunning commands and recording observed results.

## 1. Set up PostgreSQL and profile the source data — complete

Verified that PostgreSQL 17 started, all four seed table counts matched the supplied archive, and the profiling queries ran in a read-only session. The detailed queries and results are in the local workspace.

## 2. Define and verify the required visit report

Document how the query pairs entry and exit events, handles exact replays and conflicting source references, treats unknown members and unmatched events, and assigns visits to a branch-local date. Write `reports/visits_per_branch.sql` as a single standalone PostgreSQL 17 query that returns one row per branch, including branches with zero visits.

Run it with `psql -f` in a read-only session against the supplied data and a separate database with the same schema. Check expected results for exact replays, reference collisions, uppercase check-ins, unmatched events, a visit crossing the local year boundary and a branch with zero visits.

## 3. Build and verify the data quality suite

Use Playwright Test with JavaScript and `pg` to query the four source tables read-only. Fail the run on findings that make reports unreliable and surface lower-impact findings with counts. Verify that `npm test` exits 0 on clean fixture data, exits nonzero on a blocking fixture, and gives actionable diagnostics on the supplied data.

## 4. Document findings and prepare review

- `DATA_QUALITY.md` records each finding's SQL evidence, count, severity, estimated report impact, likely cause, questions for source teams and suggested monitoring.
- `README.md` explains setup, the test command, database configuration and time spent.
- `AI_USAGE.md` records how AI contributed, which suggestions were corrected or rejected, and how the results were verified.
- Rerun the documented commands from a clean setup and reconcile each reported count against its query. Present the local changes, verification results and open decisions for review. Consider the daily visits bonus after the required work is verified.
