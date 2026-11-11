# How I used AI

I used Codex to help turn the assignment into a plan and a working solution. It profiled the PostgreSQL data, drafted the SQL reports and JavaScript checks, created synthetic fixtures, and helped write the findings and setup instructions.

I guided the work by choosing JavaScript and Playwright, setting review checkpoints before commits, and reviewing the changes before approving them. I also spotted a database password in an early run example and asked for it to be removed. The instructions now use environment variables, and Git ignores the local `.env` file.

The data changed one of our early assumptions. We considered treating each source reference as a unique event, but profiling showed that the same reference could have different payloads. The report now collapses identical replays and keeps distinct events that reuse a reference. I reviewed the proposed approach and its effect on the visit counts.

## How the work was checked

Codex ran the branch report in read-only PostgreSQL sessions against both the supplied data and a synthetic fixture with known results. The fixture exercised replays, reused references, incomplete visits, and the local year boundary. Codex also changed one reporting rule at a time to measure its effect on the visit totals.

For the Playwright suite, Codex checked that clean fixture data passed, warnings alone kept the run successful, and deliberately invalid data triggered the blocking checks. On the supplied dataset, the suite flagged 828 access events that referenced unknown members.
