-- Load after 01_schema.sql into an empty, separate database.
INSERT INTO branches VALUES
    (1, 'West', 'Test City', 'America/Los_Angeles', '2020-01-01', '00:00', '23:59'),
    (2, 'Empty', 'Test City', 'America/New_York', '2020-01-01', '00:00', '23:59');
INSERT INTO devices VALUES ('in', 1, 'entrance'), ('out', 1, 'exit'), ('other-out', 2, 'exit');
INSERT INTO members (member_id) VALUES (1), (2);
INSERT INTO events (event_id, source_ref, member_id, event_type, event_ts, branch_id, device_id, ingested_at)
SELECT id, ref, member_id, kind, occurred, branch_id, device, occurred
FROM (VALUES
    -- Uppercase entry, exact replay and normal exit: one visit.
    (1, 'in:1', 1, 'CHECK_IN', '2024-04-01 18:00Z'::timestamptz, 1, 'in'),
    (2, 'in:1', 1, 'check_in', '2024-04-01 18:00Z', 1, 'in'),
    (3, 'out:1', 1, 'check_out', '2024-04-01 19:00Z', 1, 'out'),
    -- Same refs on a different day: another visit.
    (4, 'in:1', 1, 'check_in', '2024-04-02 18:00Z', 1, 'in'),
    (5, 'out:1', 1, 'check_out', '2024-04-02 19:00Z', 1, 'out'),
    -- Entry on Dec 31 local time; exit on Jan 1 local time: one visit.
    (6, 'in:2', 1, 'check_in', '2025-01-01 07:50Z', 1, 'in'),
    (7, 'out:2', 1, 'check_out', '2025-01-01 08:10Z', 1, 'out'),
    -- Entry before local 2024; a 2025 local entry; neither counts.
    (8, 'in:3', 1, 'check_in', '2024-01-01 07:50Z', 1, 'in'),
    (9, 'out:3', 1, 'check_out', '2024-01-01 08:10Z', 1, 'out'),
    (10, 'in:4', 1, 'check_in', '2025-01-01 08:30Z', 1, 'in'),
    (11, 'out:4', 1, 'check_out', '2025-01-01 09:10Z', 1, 'out'),
    -- Unknown member, long gap and cross-branch pair: no visits.
    (12, 'in:5', 99, 'check_in', '2024-06-01 18:00Z', 1, 'in'),
    (13, 'out:5', 99, 'check_out', '2024-06-01 19:00Z', 1, 'out'),
    (14, 'in:6', 2, 'check_in', '2024-07-01 18:00Z', 1, 'in'),
    (15, 'out:6', 2, 'check_out', '2024-07-03 19:00Z', 1, 'out'),
    (16, 'in:7', 2, 'check_in', '2024-07-05 18:00Z', 1, 'in'),
    (17, 'other-out:1', 2, 'check_out', '2024-07-05 19:00Z', 2, 'other-out'),
    -- Repeated entries and exits: count one completed visit.
    (18, 'in:8', 1, 'check_in', '2024-08-01 18:00Z', 1, 'in'),
    (19, 'in:9', 1, 'check_in', '2024-08-01 18:01Z', 1, 'in'),
    (20, 'out:7', 1, 'check_out', '2024-08-01 19:00Z', 1, 'out'),
    (21, 'out:8', 1, 'check_out', '2024-08-01 19:01Z', 1, 'out')
) AS fixture(id, ref, member_id, kind, occurred, branch_id, device);
