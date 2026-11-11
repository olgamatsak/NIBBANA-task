# FitTrack data quality findings

The 2024 visits report counts **71,220 completed visits across eight branches** under the rules documented in the SQL. Hold publication pending investigation of the unresolved member references. The reported counts below describe how the same data behaves under different rules. They do not establish which events represent real visits.

| Finding | Severity | Evidence | Effect on the 2024 visits report | Likely cause to verify |
|---|---|---|---|---|
| Access events reference absent member IDs | Blocking | 828 events: 414 entries and 414 exits, including one uppercase entry. None of the 828 has a null member ID. | Allowing unknown member IDs adds 404 candidate visits across all eight branches. The report currently excludes them. | The access system may have sent IDs missing from the CRM extract or used a different ID mapping. |
| Source references repeat with differing payloads | Warning | 3,736 repeated references account for 3,756 rows beyond the first row per reference. 3,036 references have differing payloads. Repeats occur on all 24 devices. | Keeping only the earliest ingested event for each reference reduces the count by 1,434, about 2.0%. The report collapses identical normalized payloads and retains conflicting payloads. | Devices may reset or reuse counters. Identical payloads may be retries. Confirm the actual uniqueness scope before enforcing one row per reference. |
| Riverwalk sends uppercase entry events | Warning | 181 `CHECK_IN` rows came from D04-IN between April 8 and 15 UTC. | A strict lowercase filter removes 179 completed visits from Riverwalk. Normalization recovers those pairs under the report rules. | The concentration on one device and one week suggests a temporary serialization or firmware change. |
| Mission Bay has implausibly long candidate visits | High | 1,038 adjacent entry/exit pairs exceed 24 hours. All are at Mission Bay, with local entries from June 6 to August 4. Gaps range from just over 24 hours to over 47 days. | Removing the cap adds 1,038 to Mission Bay, raising its count from 8,598 to 9,636. The 24-hour cap is a report assumption that should be confirmed with operations. | The cluster is consistent with missing access events or incorrect event timestamps. The data alone cannot distinguish those causes. |
| CRM snapshot differs from membership history | Warning for this report | 54 member statuses disagree with the latest start, reactivation or cancellation. Two members lack a state event. | No direct effect on this report, which validates member identity and counts paired access events regardless of current membership status. A membership activity report would need to reconstruct state from events. | The snapshot and event stream may have different refresh times or gaps in the lifecycle feed. |

The initial access sequence check also flagged 1,090 entries and 361 exits without the expected neighboring event. That scan uses exact event labels and is a diagnostic signal. Those counts cannot be added to the visit deltas because casing, ordering and incomplete pairs overlap. The sensitivity scenarios change one rule at a time. Their deltas should not be added together.

## Reproduce the evidence

With the standard PostgreSQL connection variables set, run these from the repository root against the supplied dataset:

```sh
PGOPTIONS='-c default_transaction_read_only=on' psql -X -v ON_ERROR_STOP=1 -f verification/profile.sql
PGOPTIONS='-c default_transaction_read_only=on' psql -X -v ON_ERROR_STOP=1 -f verification/long-visit-pairs.sql
node verification/report-sensitivity.js > /tmp/fittrack-report-sensitivity.sql
PGOPTIONS='-c default_transaction_read_only=on' psql -X -v ON_ERROR_STOP=1 -f /tmp/fittrack-report-sensitivity.sql
```

## Questions and monitoring

- **Access-control team.** Is the device sequence unique across restarts? Can you match replayed messages by a stable event ID? What changed on D04-IN in April, and were any Mission Bay devices offline or reporting clock drift in June–August?
- **CRM team.** Do member snapshots and access events use the same identifier namespace and extract cutoff? Can you reconcile the 828 events and explain why two members lack a state event?
- **Monitor each load.** Track unknown member references, device role and branch mismatches, event type variants, replay and collision rates, unmatched entries and exits, and long visit gaps by device and branch. Compare CRM snapshot status with event history at the same cutoff. Show the counts alongside the publication decision.
