-- Count completed visits by the branch-local date of entry.
-- Require a known member and an entrance/exit device registered to this branch.
-- Normalize event type case and collapse identical payloads for a source
-- reference. Keep differing payloads because a device can reuse a reference.
-- Pair adjacent entry/exit events for each member and branch. In a run of
-- repeated entries, only the last can pair. Unmatched exits are ignored.
-- Require positive duration and cap it at 24 hours to avoid pairing an
-- abandoned entry with a much later exit. This cap is a reporting assumption.
WITH access_events AS (
    SELECT DISTINCT ON (
        e.source_ref, e.member_id, e.branch_id, lower(e.event_type),
        e.event_ts, e.device_id, e.details
    )
        e.event_id, e.member_id, e.branch_id,
        lower(e.event_type) AS event_type, e.event_ts
    FROM events AS e
    JOIN members AS m ON m.member_id = e.member_id
    JOIN devices AS d ON d.device_id = e.device_id AND d.branch_id = e.branch_id
    WHERE (lower(e.event_type) = 'check_in' AND d.kind = 'entrance')
       OR (lower(e.event_type) = 'check_out' AND d.kind = 'exit')
    ORDER BY e.source_ref, e.member_id, e.branch_id, lower(e.event_type),
             e.event_ts, e.device_id, e.details, e.event_id
),
ordered_events AS (
    SELECT branch_id, event_type, event_ts,
           lead(event_type) OVER member_branch AS next_type,
           lead(event_ts) OVER member_branch AS next_ts
    FROM access_events
    WINDOW member_branch AS (
        PARTITION BY member_id, branch_id ORDER BY event_ts, event_id
    )
)
SELECT e.branch_id, count(*) AS pairs, min(e.event_ts AT TIME ZONE b.timezone) AS first_local_entry,
max(e.event_ts AT TIME ZONE b.timezone) AS last_local_entry,
min(e.next_ts-e.event_ts) AS min_gap,max(e.next_ts-e.event_ts) AS max_gap
FROM ordered_events e JOIN branches b USING (branch_id)
WHERE e.event_type='check_in' AND e.next_type='check_out'
AND e.next_ts-e.event_ts > interval '24 hours'
AND (e.event_ts AT TIME ZONE b.timezone) >= timestamp '2024-01-01'
AND (e.event_ts AT TIME ZONE b.timezone) < timestamp '2025-01-01'
GROUP BY e.branch_id;
