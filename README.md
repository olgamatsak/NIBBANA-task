# FitTrack data quality

This project contains a read-only PostgreSQL data quality suite and the 2024
visits-by-branch report.

## Run the suite

Use Node.js, npm and PostgreSQL 17. Install dependencies with `npm ci`.
Set `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` and `PGPASSWORD` in your shell
for a database loaded with the assignment schema and data. Then run:

```sh
npm test
```

The tests use Playwright Test with node-postgres. No browser installation is
required. Exit code 0 means the blocking checks passed. A nonzero exit code
means a blocking check or execution failed. The supplied dataset is expected
to fail the member-reference check. See [fixture instructions](verification/RUN_DATA_QUALITY.md)
for a clean run and a deliberate failure.

## Start PostgreSQL locally

Place the supplied assignment's database initialization files in `db/init/`.
Export `PGPASSWORD` with a local password before starting a new volume. An
existing volume uses the password configured when it was initialized.

```sh
export FITTRACK_DB_PORT=55432
docker compose up -d --wait
export PGHOST=127.0.0.1 PGPORT="$FITTRACK_DB_PORT" PGDATABASE=fittrack PGUSER=fittrack
npm ci
npm test
```

## Run the visit report

With the same PostgreSQL variables set and the PostgreSQL client installed:

```sh
PGOPTIONS='-c default_transaction_read_only=on' psql -X -v ON_ERROR_STOP=1 -f reports/visits_per_branch.sql
```

See [data quality findings](DATA_QUALITY.md) for evidence and report impact and
[AI usage](AI_USAGE.md) for contributions and verification.

Time spent: approximately 3 hours.
