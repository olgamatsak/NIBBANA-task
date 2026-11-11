# FitTrack data quality assignment

Use JavaScript, Playwright Test and node-postgres (`pg`) for the database checks. Playwright Test runs the suite without a browser. Use the standard `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` and `PGPASSWORD` variables. The planned entry point is `npm test`.

Commit this plan and its updates to the NIBBANA-task repository. Present implementation changes and verification results to Olga for review and wait for her approval before committing or pushing them.

## Skills

- Playwright Best Practices for fixtures, assertions and test reporting.
- Supabase Postgres Best Practices for SQL and query plan review.
- Verification Before Completion for rerunning commands and recording observed results.

## 1. Set up PostgreSQL and profile the source data — complete

Verified that PostgreSQL 17 started, all four seed table counts matched the supplied archive, and the profiling queries ran in a read-only session. The detailed queries and results are in the local workspace.

## 2. Define and verify the required visit report — complete and committed

Implemented the standalone PostgreSQL 17 query and ran it with `psql -f` in read-only sessions against the supplied database and a separate database with the same schema. The supplied data returned one row per branch. The separate fixture matched the expected counts for replayed events, reused references, uppercase check-ins, incomplete visits, local year boundaries and a branch with zero visits.

## 3. Build and verify the data quality suite — complete and committed

Implemented the read-only JavaScript suite with Playwright Test and node-postgres. `npm test` passed on clean fixture data and returned exit code 1 on both the deliberately flawed fixture and the supplied data. The failing runs reported the expected integrity issue with affected row counts.

## 4. Document findings and prepare review — committed

Prepared the setup guide, data quality findings, AI usage notes and reproducible evidence queries. Verified dependency installation, database initialization, expected suite failure on supplied data and report output on a fresh database. The reviewed documentation and evidence scripts are committed. The README records approximately 3 hours spent.
