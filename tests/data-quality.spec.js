import { test as base, expect } from '@playwright/test';
import pg from 'pg';

const test = base.extend({
  db: async ({}, use) => {
    const db = new pg.Client({
      connectionTimeoutMillis: 5000,
      options: '-c default_transaction_read_only=on -c statement_timeout=15000',
    });
    await db.connect();
    try {
      await use(db);
    } finally {
      await db.end();
    }
  },
});

const checks = [
  {
    name: 'branches have a recognized time zone',
    sql: `SELECT count(*)::text AS affected
          FROM branches b
          WHERE NOT EXISTS (SELECT 1 FROM pg_timezone_names t WHERE t.name = b.timezone)`,
  },
  {
    name: 'access events reference a known member',
    sql: `SELECT count(*)::text AS affected
          FROM events e LEFT JOIN members m USING (member_id)
          WHERE lower(e.event_type) IN ('check_in', 'check_out', 'friend_visit')
            AND m.member_id IS NULL`,
  },
  {
    name: 'access events match their branch and device role',
    sql: `SELECT count(*)::text AS affected
          FROM events e
          LEFT JOIN branches b ON b.branch_id = e.branch_id
          LEFT JOIN devices d ON d.device_id = e.device_id
          WHERE lower(e.event_type) IN ('check_in', 'check_out', 'friend_visit')
            AND (b.branch_id IS NULL OR d.device_id IS NULL
              OR d.branch_id IS DISTINCT FROM e.branch_id
              OR d.kind IS DISTINCT FROM CASE lower(e.event_type)
                WHEN 'check_in' THEN 'entrance'
                WHEN 'check_out' THEN 'exit'
                WHEN 'friend_visit' THEN 'front_desk'
              END)`,
  },
  {
    name: 'all event types are recognized after case normalization',
    sql: `SELECT count(*)::text AS affected FROM events
          WHERE lower(event_type) NOT IN (
            'check_in', 'check_out', 'friend_visit', 'membership_started',
            'membership_reactivated', 'membership_cancelled', 'tier_changed'
          )`,
  },
];

for (const { name, sql } of checks) {
  test(name, async ({ db }) => {
    const { rows: [{ affected }] } = await db.query(sql);
    expect(affected, `Blocking data quality issue: ${name}. Affected rows: ${affected}`).toBe('0');
  });
}

test('report event casing and reused source references', async ({ db }, testInfo) => {
  const { rows: [counts] } = await db.query(`
    WITH reused_refs AS (
      SELECT source_ref
      FROM events
      GROUP BY source_ref
      HAVING count(DISTINCT (
        member_id, branch_id, lower(event_type), event_ts, device_id, details
      )) > 1
    )
    SELECT
      (SELECT count(*) FROM events WHERE event_type <> lower(event_type)) AS noncanonical_event_types,
      (SELECT count(*) FROM reused_refs) AS conflicting_source_refs
  `);

  for (const [finding, count] of Object.entries(counts)) {
    if (count !== '0') {
      const description = `${finding}: ${count}`;
      testInfo.annotations.push({ type: 'warning', description });
      console.warn(description);
    }
  }
});
