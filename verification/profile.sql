\echo 'Database and seed counts'
BEGIN READ ONLY;
SELECT version();
SELECT 'branches' AS table_name, count(*) AS rows FROM branches
UNION ALL SELECT 'devices', count(*) FROM devices
UNION ALL SELECT 'members', count(*) FROM members
UNION ALL SELECT 'events', count(*) FROM events;

\echo 'Event coverage in UTC'
SET LOCAL TIME ZONE 'UTC';
SELECT event_type, count(*) AS rows, min(event_ts) AS first_event, max(event_ts) AS last_event
FROM events GROUP BY event_type ORDER BY event_type;

\echo 'Repeated source references'
WITH repeats AS (
  SELECT source_ref, count(*) AS rows,
         count(DISTINCT (member_id, event_type, event_ts, branch_id, device_id, details)) AS payloads
  FROM events GROUP BY source_ref HAVING count(*) > 1
)
SELECT count(*) AS repeated_refs, sum(rows - 1) AS extra_rows,
       count(*) FILTER (WHERE payloads > 1) AS conflicting_refs
FROM repeats;

\echo 'Event references and device mismatches'
SELECT
  count(*) FILTER (WHERE m.member_id IS NULL) AS missing_or_unknown_member,
  count(*) FILTER (WHERE e.branch_id IS NOT NULL AND b.branch_id IS NULL) AS unknown_branch,
  count(*) FILTER (WHERE e.event_type IN ('check_in', 'check_out', 'friend_visit')
                    AND e.branch_id IS NULL) AS access_missing_branch,
  count(*) FILTER (WHERE e.event_type IN ('check_in', 'check_out', 'friend_visit')
                    AND d.device_id IS NULL) AS access_missing_or_unknown_device,
  count(*) FILTER (WHERE d.device_id IS NOT NULL AND d.branch_id IS DISTINCT FROM e.branch_id) AS wrong_device_branch,
  count(*) FILTER (WHERE d.device_id IS NOT NULL AND d.kind IS DISTINCT FROM
    CASE e.event_type WHEN 'check_in' THEN 'entrance' WHEN 'check_out' THEN 'exit'
         WHEN 'friend_visit' THEN 'front_desk' END
    AND e.event_type IN ('check_in', 'check_out', 'friend_visit')) AS wrong_device_kind
FROM events e
LEFT JOIN members m USING (member_id)
LEFT JOIN branches b ON b.branch_id = e.branch_id
LEFT JOIN devices d USING (device_id);

\echo 'Access sequence signals after removing exact repeated event payloads'
WITH access_events AS (
  SELECT DISTINCT ON (e.source_ref, e.member_id, e.event_type, e.event_ts, e.branch_id, e.device_id, e.details)
         e.event_id, e.member_id, e.branch_id, e.event_type, e.event_ts
  FROM events e
  JOIN members m USING (member_id)
  JOIN devices d ON d.device_id = e.device_id AND d.branch_id = e.branch_id
  WHERE (e.event_type = 'check_in' AND d.kind = 'entrance')
     OR (e.event_type = 'check_out' AND d.kind = 'exit')
  ORDER BY e.source_ref, e.member_id, e.event_type, e.event_ts, e.branch_id, e.device_id, e.details, e.event_id
), sequence AS (
  SELECT *,
         lag(event_type) OVER visits AS previous_type,
         lead(event_type) OVER visits AS next_type,
         lead(event_ts) OVER visits AS next_ts
  FROM access_events
  WINDOW visits AS (PARTITION BY member_id, branch_id ORDER BY event_ts, event_id)
)
SELECT count(*) FILTER (WHERE event_type = 'check_in' AND next_type IS DISTINCT FROM 'check_out')
         AS check_ins_without_immediate_checkout,
       count(*) FILTER (WHERE event_type = 'check_out' AND previous_type IS DISTINCT FROM 'check_in')
         AS checkouts_without_immediate_check_in,
       count(*) FILTER (WHERE event_type = 'check_in' AND next_type = 'check_out' AND next_ts = event_ts)
         AS same_timestamp_pairs
FROM sequence;

\echo 'Member status versus latest membership state event'
WITH latest AS (
  SELECT DISTINCT ON (member_id) member_id, event_type
  FROM events WHERE event_type IN ('membership_started', 'membership_reactivated', 'membership_cancelled')
  ORDER BY member_id, event_ts DESC, event_id DESC
)
SELECT count(*) FILTER (WHERE l.member_id IS NULL) AS no_membership_state_event,
       count(*) FILTER (WHERE l.member_id IS NOT NULL AND m.status IS DISTINCT FROM
         CASE WHEN l.event_type = 'membership_cancelled' THEN 'cancelled' ELSE 'active' END) AS status_mismatches
FROM members m LEFT JOIN latest l USING (member_id);

\echo 'Nonstandard event spelling by device and UTC date'
SELECT branch_id, device_id, min(event_ts::date) AS first_utc_date,
       max(event_ts::date) AS last_utc_date, count(*) AS rows
FROM events WHERE event_type <> lower(event_type)
GROUP BY branch_id, device_id ORDER BY rows DESC, branch_id, device_id;

\echo 'Repeat patterns by device'
WITH repeats AS (
  SELECT source_ref, count(*) AS rows, count(DISTINCT device_id) AS devices,
         min(device_id) AS device_id,
         count(DISTINCT (member_id, event_type, event_ts, branch_id, device_id, details)) AS payloads
  FROM events GROUP BY source_ref HAVING count(*) > 1
)
SELECT CASE WHEN devices > 1 THEN '(multiple devices)' ELSE coalesce(device_id, '(CRM)') END AS source,
       count(*) AS repeated_refs, sum(rows - 1) AS extra_rows,
       count(*) FILTER (WHERE payloads > 1) AS conflicting_refs
FROM repeats GROUP BY 1 ORDER BY conflicting_refs DESC, repeated_refs DESC, source;

\echo 'Missing and unknown member references by event type'
SELECT e.event_type, count(*) FILTER (WHERE e.member_id IS NULL) AS null_member,
       count(*) FILTER (WHERE e.member_id IS NOT NULL) AS unknown_member
FROM events e LEFT JOIN members m USING (member_id)
WHERE m.member_id IS NULL GROUP BY e.event_type ORDER BY e.event_type;

ROLLBACK;
