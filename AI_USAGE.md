# AI usage

Codex helped inspect the assignment archive, organize the implementation plan,
draft the PostgreSQL queries and JavaScript tests, and write the documentation.
Olga chose JavaScript and Playwright, required review before implementation
commits, and asked to keep credentials out of shared files. Codex proposed the
pairing rules, warning and blocking criteria, and synthetic verification cases.

Olga corrected an AI-written example that included the local database password.
The example now reads it from the environment, and Docker Compose requires the
same environment variable. The profiling results also corrected an initial
deduplication idea. Repeated source references frequently had different payloads,
so the report collapses identical normalized payloads and keeps distinct ones.

Codex ran the report with `psql -f` in read-only sessions against the supplied
database and a separate synthetic database. The fixture matched expected counts
for replays, reused references, incomplete pairs and the local year boundary.
The Playwright suite passed on clean fixture data and failed on a fixture with
one deliberately invalid member reference. It also identified the expected
failure on the supplied data. Report sensitivity was checked by changing one
rule per query and comparing branch counts against the baseline.
