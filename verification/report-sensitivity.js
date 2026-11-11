import { readFileSync } from 'node:fs';

const report = readFileSync(new URL('../reports/visits_per_branch.sql', import.meta.url), 'utf8')
  .trimEnd().replace(/;$/, '');
const variants = {
  baseline: report,
  strict_case: report.replaceAll('lower(e.event_type)', 'e.event_type'),
  include_unknown_members: report.replace('    JOIN members AS m ON m.member_id = e.member_id\n', ''),
  no_duration_cap: report.replace("      AND e.next_ts <= e.event_ts + interval '24 hours'\n", ''),
  one_event_per_ref: report.replace('FROM events AS e',
    'FROM (SELECT DISTINCT ON (source_ref) * FROM events ORDER BY source_ref, ingested_at, event_id) AS e'),
};

const ctes = Object.entries(variants).map(([name, query]) => {
  if (name !== 'baseline' && query === report) throw new Error('Report variant did not change: ' + name);
  return name + ' AS (\n' + query + '\n)';
});

console.log('WITH ' + ctes.join(',\n'));
console.log(`
SELECT b.branch_id, b.member_visits AS baseline,
       c.member_visits - b.member_visits AS strict_case_delta,
       m.member_visits - b.member_visits AS unknown_members_delta,
       d.member_visits - b.member_visits AS no_cap_delta,
       r.member_visits - b.member_visits AS unique_ref_delta
FROM baseline b
JOIN strict_case c USING (branch_id)
JOIN include_unknown_members m USING (branch_id)
JOIN no_duration_cap d USING (branch_id)
JOIN one_event_per_ref r USING (branch_id)
ORDER BY b.branch_id;`);
