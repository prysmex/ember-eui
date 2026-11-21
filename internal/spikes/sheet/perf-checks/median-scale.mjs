// Medians (and the values) of run-scale.sh's results.jsonl, per build and case.
//   node median-scale.mjs <out-dir> [metric,...]
import { readFileSync } from 'node:fs';
const [dir, only] = process.argv.slice(2);
const rows = readFileSync(`${dir}/results.jsonl`, 'utf8')
  .trim()
  .split('\n')
  .map((l) => JSON.parse(l));
const metrics = {
  mount: (r) => r.mount,
  'scroll step': (r) => r.scrollStep?.median,
  'scroll p90': (r) => r.scrollFrames?.p90,
  'scroll >50': (r) => r.scrollFrames?.over50,
  'drag move': (r) => r.drag?.moveMedian,
  'drag up': (r) => r.drag?.up,
  paste: (r) => r.paste?.total,
  'paste to onChange': (r) => r.paste?.toOnChange,
  'paste apply': (r) => r.paste?.apply,
  undo: (r) => r.undo?.total,
  'undo to onChange': (r) => r.undo?.toOnChange,
  'undo apply': (r) => r.undo?.apply,
  'rewalks scroll': (r) => r.counts?.scroll?.rewalks,
  'rewalks drag': (r) => r.counts?.drag?.rewalks,
  'rewalks paste': (r) => r.counts?.paste?.rewalks,
  'rewalks undo': (r) => r.counts?.undo?.rewalks,
  'rewalks mount': (r) => r.counts?.mount?.rewalks
};
const pick = only ? only.split(',') : Object.keys(metrics);
const groups = new Map();
for (const r of rows) {
  const k = `${r.args}`;
  if (!groups.has(k)) groups.set(k, new Map());
  const g = groups.get(k);
  if (!g.has(r.build)) g.set(r.build, []);
  g.get(r.build).push(r);
}
const med = (xs) => {
  const s = xs.filter((x) => x != null).sort((a, b) => a - b);
  return s.length ? s[Math.floor((s.length - 1) / 2)] : null;
};
for (const [args, g] of groups) {
  console.log(`\n== ${args}`);
  const builds = [...g.keys()];
  console.log('metric'.padEnd(20) + builds.map((b) => b.padStart(26)).join(''));
  for (const m of pick) {
    const cells = builds.map((b) => {
      const vals = g.get(b).map(metrics[m]);
      const v = med(vals);
      return v == null
        ? ''.padStart(26)
        : `${v} (${vals.join('/')})`.padStart(26);
    });
    if (cells.some((c) => c.trim())) console.log(m.padEnd(20) + cells.join(''));
  }
}
