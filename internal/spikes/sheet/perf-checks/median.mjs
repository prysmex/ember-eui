// Medians of the RESULT lines in a run.sh output directory.
//   node median.mjs <dir>
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const dir = process.argv[2];
const groups = new Map();
for (const f of readdirSync(dir)
  .filter((f) => f.endsWith('.log'))
  .sort()) {
  const line = readFileSync(join(dir, f), 'utf8')
    .split('\n')
    .find((l) => l.startsWith('RESULT '));
  if (!line) {
    console.log(`${f}: no RESULT line`);
    continue;
  }
  const key = f.replace(/-\d+\.log$/, '');
  if (!groups.has(key)) groups.set(key, []);
  groups.get(key).push(JSON.parse(line.slice(7)));
}
const median = (xs) => {
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.floor(s.length / 2)];
};
for (const [key, rows] of groups) {
  const fields = Object.keys(rows[0]).filter(
    (k) => typeof rows[0][k] === 'number'
  );
  const out = fields.map(
    (k) =>
      `${k} ${median(rows.map((r) => r[k]))} [${rows.map((r) => r[k]).join(', ')}]`
  );
  console.log(`${key} (n=${rows.length}): ${out.join('; ')}`);
}
