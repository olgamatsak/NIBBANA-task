-- Load after 01_schema.sql into a separate database.
INSERT INTO branches VALUES
  (1, 'West', 'Test City', 'America/Los_Angeles', '2020-01-01', '00:00', '23:59');
INSERT INTO devices VALUES ('in', 1, 'entrance'), ('out', 1, 'exit');
INSERT INTO members (member_id, status) VALUES (1, 'active');
INSERT INTO events (event_id, source_ref, member_id, event_type, event_ts, branch_id, device_id, ingested_at)
VALUES
  (1, 'in:1', 1, 'check_in', '2024-04-01 18:00Z', 1, 'in', '2024-04-01 18:00Z'),
  (2, 'out:1', 1, 'check_out', '2024-04-01 19:00Z', 1, 'out', '2024-04-01 19:00Z');
