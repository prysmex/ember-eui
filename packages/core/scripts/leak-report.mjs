#!/usr/bin/env node
/**
 * Summarizes the JSON written by leak mode (tests/leak-detector.ts).
 *
 *   node scripts/leak-report.mjs [leak-report.json] [--json out.json] [--all]
 *
 * Stack frames pointing into dist-tests/assets/*.js are mapped back to source
 * files with the build's source maps (EUI_LEAKS=1 enables them in
 * vite.config.mjs). Items are grouped by their first frame in EUI source
 * (`src/…`), or the first non-detector frame otherwise.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const args = process.argv.slice(2);
const input = path.resolve(root, args.find((a) => !a.startsWith('--')) ?? 'leak-report.json');
const jsonOut = args.includes('--json') ? args[args.indexOf('--json') + 1] : null;
const showAll = args.includes('--all');
const report = JSON.parse(fs.readFileSync(input, 'utf8'));

// --- source maps --------------------------------------------------------------
const B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
const b64 = Object.fromEntries([...B64].map((c, i) => [c, i]));
function decodeVlq(str) {
  const out = [];
  let shift = 0;
  let value = 0;
  for (const c of str) {
    const d = b64[c];
    value += (d & 31) << shift;
    if (d & 32) shift += 5;
    else {
      out.push(value & 1 ? -(value >>> 1) : value >>> 1);
      value = 0;
      shift = 0;
    }
  }
  return out;
}
const maps = new Map();
function loadMap(file) {
  if (maps.has(file)) return maps.get(file);
  const p = path.join(root, 'dist-tests', 'assets', file + '.map');
  let m = null;
  if (fs.existsSync(p)) {
    const raw = JSON.parse(fs.readFileSync(p, 'utf8'));
    const lines = [];
    let src = 0;
    let sl = 0;
    let sc = 0;
    for (const line of raw.mappings.split(';')) {
      let col = 0;
      const segs = [];
      for (const seg of line.split(',')) {
        if (!seg) continue;
        const v = decodeVlq(seg);
        col += v[0];
        if (v.length >= 4) {
          src += v[1];
          sl += v[2];
          sc += v[3];
          segs.push([col, src, sl, sc]);
        }
      }
      lines.push(segs);
    }
    m = { sources: raw.sources, lines };
  }
  maps.set(file, m);
  return m;
}
function resolve(file, line, col) {
  const m = loadMap(file);
  if (!m) return null;
  const segs = m.lines[line - 1];
  if (!segs || !segs.length) return null;
  let best = segs[0];
  for (const s of segs) {
    if (s[0] <= col - 1) best = s;
    else break;
  }
  let source = m.sources[best[1]] ?? '?';
  source = source.replace(/^(\.\.\/)+/, '').replace(/^.*node_modules\/\.pnpm\/[^/]+\/node_modules\//, '');
  return `${source}:${best[2] + 1}`;
}

function frames(stack) {
  return (stack || '')
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean)
    .map((l) => {
      const m = l.match(/at (?:(.*?) \()?.*?\/assets\/([^/:]+\.js):(\d+):(\d+)\)?$/);
      if (!m) return { fn: l.replace(/^at /, ''), loc: null };
      const loc = resolve(m[2], Number(m[3]), Number(m[4]));
      return { fn: m[1] ?? '<anonymous>', loc: loc ?? `${m[2]}:${m[3]}` };
    });
}

const isDetector = (f) => /leak-detector/.test(f.loc ?? f.fn);
function where(stack) {
  const fs_ = frames(stack).filter((f) => !isDetector(f));
  const src = fs_.find((f) => f.loc && /(^|\/)src\//.test(f.loc) && !/packages\/core\/tests\//.test(f.loc));
  const first = src ?? fs_[0];
  return {
    key: first ? `${first.fn} @ ${first.loc ?? '?'}` : '(no stack)',
    src: Boolean(src),
    frames: fs_.slice(0, 12).map((f) => `${f.fn} @ ${f.loc ?? '?'}`)
  };
}

// --- group --------------------------------------------------------------------
const groups = new Map();
for (const t of report.tests) {
  for (const item of t.items) {
    const w = item.stack ? where(item.stack) : { key: item.detail, src: false, frames: [] };
    const k = `${item.kind} | ${item.kind === 'body-child' ? item.detail.replace(/\(\d+ descendants\)/, '') : item.detail.replace(/\d+ target\(s\) alive, \d+ connected: .*/, '')} | ${w.key}`;
    const g = groups.get(k) ?? {
      kind: item.kind,
      detail: item.detail,
      category: item.category,
      origin: w.key,
      inSrc: w.src,
      frames: w.frames,
      tests: []
    };
    g.tests.push(`${t.module} :: ${t.name}`);
    groups.set(k, g);
  }
}
const post = new Map();
for (const t of report.tests) {
  for (const [kind, p] of Object.entries(t.post ?? {})) {
    const w = where(p.stack);
    const k = `${kind} | ${w.key}`;
    const g = post.get(k) ?? { kind, origin: w.key, frames: w.frames, callbacks: 0, tests: [] };
    g.callbacks += p.count;
    g.tests.push(`${t.module} :: ${t.name}`);
    post.set(k, g);
  }
}

const sorted = [...groups.values()].sort((a, b) => b.tests.length - a.tests.length);
const out = [];
out.push(`# Leak report ${report.createdAt}`);
out.push(`tests: ${report.testCount}, gc: ${report.hasGc}, renderTreeError: ${report.renderTreeError}, WeakRefs captured: ${JSON.stringify(report.capturedRefs ?? {})}`);
out.push(`final heap: ${(report.finalHeap / 1e6).toFixed(1)} MB, final counts: ${JSON.stringify(report.finalCounts)}`);
out.push('');
out.push('## Heap samples (every 100 tests, after gc)');
for (const s of report.heapSamples) out.push(`- #${s.seq}: ${(s.heap / 1e6).toFixed(1)} MB ${JSON.stringify(s.counts)}`);
out.push('');
out.push(`## Outstanding after teardown (${sorted.length} distinct origins)`);
for (const g of sorted) {
  out.push(`\n### [${g.kind}] ${g.detail}${g.category ? ` {${g.category}}` : ''}`);
  out.push(`origin: ${g.origin}`);
  out.push(`tests (${g.tests.length}): ${g.tests.slice(0, showAll ? 1e9 : 5).join(' | ')}${g.tests.length > 5 && !showAll ? ' | …' : ''}`);
  out.push('stack:\n    ' + g.frames.join('\n    '));
}
out.push('');
out.push(`## Callbacks that ran after their test finished (${post.size})`);
for (const g of [...post.values()].sort((a, b) => b.callbacks - a.callbacks)) {
  out.push(`\n### [${g.kind}] ${g.callbacks} callbacks, ${g.tests.length} tests`);
  out.push(`origin: ${g.origin}`);
  out.push(`tests: ${g.tests.slice(0, 5).join(' | ')}`);
  out.push('stack:\n    ' + g.frames.join('\n    '));
}
out.push('');
const surv = report.survivors ?? [];
out.push(`## Survivors after gc (${surv.length} tests)`);
const byKind = {};
for (const s of surv) for (const [k, v] of Object.entries(s.alive)) byKind[k] = (byKind[k] ?? 0) + v.length;
out.push(`by kind: ${JSON.stringify(byKind)}`);
const compCounts = {};
for (const s of surv) for (const c of s.alive.component ?? []) compCounts[c] = (compCounts[c] ?? 0) + 1;
out.push(
  'components: ' +
    Object.entries(compCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 60)
      .map(([k, v]) => `${k}×${v}`)
      .join(', ')
);
for (const s of surv.slice(0, showAll ? 1e9 : 40)) {
  out.push(`- #${s.seq} ${s.module} :: ${s.name} — ${Object.entries(s.alive).map(([k, v]) => `${k}: ${v.length} (${[...new Set(v)].slice(0, 6).join(', ')})`).join('; ')}`);
}
out.push('');
if (report.growth?.length) {
  out.push(`## Growth (${report.growth[0].cycles} cycles after 5 warm-up, gc before each sample)`);
  out.push('| scenario | B/cycle | B/cycle (2nd half) | counter deltas |');
  out.push('|---|---:|---:|---|');
  for (const g of report.growth) {
    const d = Object.entries(g.countDelta).filter(([, v]) => v).map(([k, v]) => `${k} ${v > 0 ? '+' : ''}${v}`).join(', ') || '0';
    out.push(`| ${g.name} | ${g.bytesPerCycle} | ${g.bytesPerCycleSecondHalf} | ${d} |`);
  }
}
console.log(out.join('\n'));
if (jsonOut) fs.writeFileSync(jsonOut, JSON.stringify({ groups: sorted, post: [...post.values()] }, null, 2));
