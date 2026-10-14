// Heap-snapshot analysis for the leak crawler.
//
//   node --max-old-space-size=4096 tests/leak/analyze.mjs diff before.heapsnapshot after.heapsnapshot [--top=40] [--paths=3] [--match=Regex]
//
// Node ids are stable across snapshots of one page session, so objects whose
// id is in "after" but not in "before" are the ones created between the two
// snapshots that survived GC. Reports them grouped by constructor, the
// detached DOM among them, and shortest retainer paths from the GC roots
// for sample objects of the top groups.
import { readFileSync } from 'node:fs';

const [cmd, fileA, fileB, ...rest] = process.argv.slice(2);
const opts = Object.fromEntries(rest.map((a) => a.replace(/^--/, '').split('=')));
const TOP = Number(opts.top ?? 40);
const PATHS = Number(opts.paths ?? 3);
let afterSummary;

function load(file) {
  const snap = JSON.parse(readFileSync(file, 'utf8'));
  const m = snap.snapshot.meta;
  const nf = m.node_fields;
  const ef = m.edge_fields;
  const g = {
    strings: snap.strings,
    nodes: snap.nodes,
    edges: snap.edges,
    NF: nf.length,
    EF: ef.length,
    nType: nf.indexOf('type'),
    nName: nf.indexOf('name'),
    nId: nf.indexOf('id'),
    nSize: nf.indexOf('self_size'),
    nEdges: nf.indexOf('edge_count'),
    nDet: nf.indexOf('detachedness'),
    eType: ef.indexOf('type'),
    eName: ef.indexOf('name_or_index'),
    eTo: ef.indexOf('to_node'),
    nodeTypes: m.node_types[0],
    edgeTypes: m.edge_types[0],
  };
  g.count = g.nodes.length / g.NF;
  g.firstEdge = new Uint32Array(g.count + 1);
  for (let i = 0, e = 0; i < g.count; i++) {
    g.firstEdge[i] = e;
    e += g.nodes[i * g.NF + g.nEdges] * g.EF;
  }
  g.firstEdge[g.count] = g.edges.length;
  return g;
}

const typeOf = (g, i) => g.nodeTypes[g.nodes[i * g.NF + g.nType]];
const nameOf = (g, i) => g.strings[g.nodes[i * g.NF + g.nName]];
const idOf = (g, i) => g.nodes[i * g.NF + g.nId];
const sizeOf = (g, i) => g.nodes[i * g.NF + g.nSize];
const detOf = (g, i) => (g.nDet >= 0 ? g.nodes[i * g.NF + g.nDet] : 0);
function label(g, i) {
  const t = typeOf(g, i);
  let n = nameOf(g, i);
  if (t === 'string' || t === 'concatenated string' || t === 'sliced string') n = 'string';
  if (t === 'number') n = 'number';
  if (t === 'code') n = `(code)`;
  if (t === 'array') n = `(${n || 'array'})`;
  if (t === 'hidden') n = `(hidden) ${n.slice(0, 40)}`;
  if (t === 'closure') n = `closure ${n || '(anonymous)'}`;
  if (n.length > 80) n = n.slice(0, 80) + '…';
  return `${t === 'native' ? 'native ' : ''}${n}`;
}

// BFS from the root over strong edges; parent[] gives the shortest path.
function retainerTree(g) {
  const parent = new Int32Array(g.count).fill(-1);
  const parentEdge = new Int32Array(g.count).fill(-1);
  const seen = new Uint8Array(g.count);
  const queue = new Uint32Array(g.count);
  let head = 0;
  let tail = 0;
  queue[tail++] = 0;
  seen[0] = 1;
  while (head < tail) {
    const i = queue[head++];
    for (let e = g.firstEdge[i]; e < g.firstEdge[i + 1]; e += g.EF) {
      const et = g.edgeTypes[g.edges[e + g.eType]];
      if (et === 'weak' || et === 'shortcut') continue;
      // WeakMap entries: V8 emits the value edge from both the backing
      // table and the key. Follow only the key's, so paths name the key.
      if (et === 'internal' && typeOf(g, i) === 'array' && g.strings[g.edges[e + g.eName]].includes('part of key')) continue;
      const to = g.edges[e + g.eTo] / g.NF;
      if (seen[to]) continue;
      seen[to] = 1;
      parent[to] = i;
      parentEdge[to] = e;
      queue[tail++] = to;
    }
  }
  return { parent, parentEdge };
}

function edgeName(g, e) {
  const et = g.edgeTypes[g.edges[e + g.eType]];
  const v = g.edges[e + g.eName];
  if (et === 'element' || et === 'hidden') return `[${v}]`;
  return et === 'internal' ? `{${g.strings[v]}}` : `.${g.strings[v]}`;
}

function pathTo(g, tree, i, max = Number(opts.maxpath ?? 18)) {
  const parts = [];
  let cur = i;
  while (cur > 0 && tree.parent[cur] >= 0 && parts.length < 60) {
    parts.push(`${edgeName(g, tree.parentEdge[cur])} -> ${label(g, cur)}`);
    cur = tree.parent[cur];
  }
  if (cur !== 0) parts.push('(unreachable from root via strong edges)');
  parts.reverse();
  // keep the root side (who holds it) and the leaf
  if (parts.length > max) return [...parts.slice(0, max - 4), `… ${parts.length - max + 2} more …`, ...parts.slice(-2)];
  return parts;
}

if (cmd === 'diff') {
  console.error('loading', fileA);
  const A = load(fileA);
  const idsA = new Set();
  for (let i = 0; i < A.count; i++) idsA.add(idOf(A, i));
  const totalA = A.count;
  const summaryA = new Map();
  const sizeA = new Map();
  for (let i = 0; i < A.count; i++) {
    const k = label(A, i);
    summaryA.set(k, (summaryA.get(k) ?? 0) + 1);
    sizeA.set(k, (sizeA.get(k) ?? 0) + sizeOf(A, i));
  }
  const detA = countDetached(A);
  // free A
  A.nodes = A.edges = A.strings = null;
  console.error('loading', fileB);
  const B = load(fileB);
  const groups = new Map();
  let newCount = 0;
  let newSize = 0;
  for (let i = 0; i < B.count; i++) {
    if (idsA.has(idOf(B, i))) continue;
    const t = typeOf(B, i);
    if (t === 'synthetic') continue;
    newCount++;
    newSize += sizeOf(B, i);
    const k = label(B, i);
    let gr = groups.get(k);
    if (!gr) groups.set(k, (gr = { count: 0, size: 0, samples: [] }));
    gr.count++;
    gr.size += sizeOf(B, i);
    if (gr.samples.length < 5000) gr.samples.push(i);
  }
  const detB = countDetached(B);
  console.log(`# ${fileA} -> ${fileB}`);
  console.log(`nodes: ${totalA} -> ${B.count}; new surviving objects: ${newCount} (${(newSize / 1024).toFixed(0)} KB self size)`);
  console.log(`detached DOM nodes: ${detA.total} -> ${detB.total}`);
  const detTop = [...detB.byName].sort((a, b) => b[1] - a[1]).slice(0, 15);
  console.log(`detached by name (after): ${detTop.map(([n, c]) => `${n}=${c}`).join(', ')}`);
  // net growth: ids churn when objects are re-created, so the count delta
  // per constructor is the more honest signal
  const sizeB = new Map();
  for (let i = 0; i < B.count; i++) {
    const k = label(B, i);
    sizeB.set(k, (sizeB.get(k) ?? 0) + sizeOf(B, i));
  }
  summaryAfter(B, '');
  const net = [...afterSummary].map(([k, c]) => [k, c - (summaryA.get(k) ?? 0), (sizeB.get(k) ?? 0) - (sizeA.get(k) ?? 0)]);
  for (const [k, c] of summaryA) if (!afterSummary.has(k)) net.push([k, -c, -(sizeA.get(k) ?? 0)]);
  console.log('\n## Net growth by constructor (count after - before), top by count');
  for (const [k, dc, ds] of net.sort((a, b) => b[1] - a[1]).slice(0, TOP)) {
    console.log(`${String(dc).padStart(7)}  ${(ds / 1024).toFixed(1).padStart(9)} KB  ${k}`);
  }
  console.log('\n## Net growth by constructor, top by self size');
  for (const [k, dc, ds] of net.sort((a, b) => b[2] - a[2]).slice(0, 15)) {
    console.log(`${String(dc).padStart(7)}  ${(ds / 1024).toFixed(1).padStart(9)} KB  ${k}`);
  }
  console.log('\n## New surviving objects by constructor (top by count)');
  const sorted = [...groups].sort((a, b) => b[1].count - a[1].count);
  for (const [k, v] of sorted.slice(0, TOP)) {
    console.log(`${String(v.count).padStart(7)}  ${String((v.size / 1024).toFixed(1)).padStart(9)} KB  ${k}  (total after ${summaryAfter(B, k)}, before ${summaryA.get(k) ?? 0})`);
  }
  if (PATHS > 0) {
    console.error('computing retainer tree');
    const tree = retainerTree(B);
    const re = opts.match ? new RegExp(opts.match) : null;
    const interesting = sorted.filter(([k]) =>
      re
        ? re.test(k)
        : !/^(string|number|\(code\)|\(hidden\)|\(system\)|\(array\)|\(object properties\)|\(object elements\)|system |\(compiled code\)|\(concatenated string\))/.test(k),
    );
    console.log('\n## Retainer paths (shortest strong path from GC root) for sample new objects');
    for (const [k, v] of interesting.slice(0, Number(opts.groups ?? 12))) {
      console.log(`\n### ${k}  x${v.count}`);
      const seenPaths = new Set();
      let shown = 0;
      const samples = opts.bysize ? [...v.samples].sort((a, b) => sizeOf(B, b) - sizeOf(B, a)) : v.samples;
      for (const i of samples) {
        if (opts.bysize) console.log(`  [${(sizeOf(B, i) / 1024).toFixed(0)} KB]`);
        const p = pathTo(B, tree, i);
        const key = p.map((s) => s.replace(/\[\d+\]/g, '[n]').replace(/@\d+/g, '')).join('|');
        if (seenPaths.has(key)) continue;
        seenPaths.add(key);
        console.log('  ' + p.join('\n    '));
        console.log('');
        if (++shown >= PATHS) break;
      }
    }
    // detached DOM: paths for the detached nodes that are new
    if (!opts.match) {
      console.log('\n## Retainer paths of new detached DOM nodes');
      let shown = 0;
      const seenPaths = new Set();
      for (let i = 0; i < B.count && shown < Number(opts.detpaths ?? 8); i++) {
        if (detOf(B, i) !== 2 || idsA.has(idOf(B, i))) continue;
        const p = pathTo(B, tree, i);
        // collapse to the JS-side holder: drop the DOM-internal tail
        const key = p.slice(0, 8).map((s) => s.replace(/\[\d+\]/g, '[n]')).join('|');
        if (seenPaths.has(key)) continue;
        seenPaths.add(key);
        console.log(`\n${label(B, i)}:\n  ` + p.join('\n    '));
        shown++;
      }
    }
  }
}

function countDetached(g) {
  const byName = new Map();
  let total = 0;
  for (let i = 0; i < g.count; i++) {
    const n = nameOf(g, i);
    if (detOf(g, i) === 2 || n.startsWith('Detached ')) {
      total++;
      const k = n.replace(/^Detached /, '').split(' ')[0];
      byName.set(k, (byName.get(k) ?? 0) + 1);
    }
  }
  return { total, byName };
}

function summaryAfter(B, k) {
  if (!afterSummary) {
    afterSummary = new Map();
    for (let i = 0; i < B.count; i++) {
      const kk = label(B, i);
      afterSummary.set(kk, (afterSummary.get(kk) ?? 0) + 1);
    }
  }
  return afterSummary.get(k) ?? 0;
}
