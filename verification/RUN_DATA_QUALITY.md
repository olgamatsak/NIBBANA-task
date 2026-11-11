# Run the data quality checks

From the assignment directory, install the locked dependencies with `npm ci`.
Run `npm test` with the standard PostgreSQL connection environment variables.
Set `PGPASSWORD` in your shell to the database password before running the command below. An ignored Compose `.env` file is read by Docker Compose. Export the value separately for `npm test`.

```sh
PGHOST=127.0.0.1 PGPORT=55432 PGDATABASE=fittrack PGUSER=fittrack npm test
```

The suite runs read-only queries and requires no browser. Unknown access members,
invalid branch or device mappings, unrecognized event types and invalid branch
time zones fail the run. Event casing and conflicting source references are
warnings because the visit report normalizes casing and retains distinct
payloads when references are reused.

To verify the exit codes, load `db/init/01_schema.sql` and
`verification/data_quality_fixture.sql` into an empty database and point
`PGDATABASE` at it. The clean run should pass all five checks. In that fixture
database, run `UPDATE events SET member_id = 999 WHERE event_id = 1;` and repeat.
The unknown-member check should fail and report one affected row.

The supplied data produced one failed check with 828 unknown-member access
events. It also reported 181 noncanonical event types and 3,036 conflicting
source references.
