#!/usr/bin/env node
/**
 * Prints the shortest strong retaining path from the GC roots to every object
 * leak mode tagged with a `LeakTag` (tests/leak-detector.ts), grouped by path.
 *
 *   node scripts/heap-retainers.mjs <file.heapsnapshot> [--max 20] [--hops 14]
 *
 * Take the snapshot with `node scripts/leak-cdp.mjs --filter … --snapshot x.heapsnapshot`.
 */
import fs from 'node:fs';

const args = process.argv.slice(2);
const file = args[0];
const opt = (n, d) => (args.includes(`--${n}`) ? args[args.indexOf(`--${n}`) + 1] : d);
const maxPrint = Number(opt('max', '20'));
const hops = Number(opt('hops', '14'));

const snap = JSON.parse(fs.readFileSync(file, 'utf8'));
const { node_fields, edge_fields, node_types, edge_types } = snap.snapshot.meta;
const NF = node_fields.length;
const EF = edge_fields.length;
const nTypes = node_types[0];
const eTypes = edge_types[0];
const iType = node_fields.indexOf('type');
const iName = node_fields.indexOf('name');
const iEdgeCount = node_fields.indexOf('edge_count');
const eType = edge_fields.indexOf('type');
const eName = edge_fields.indexOf('name_or_index');
const eTo = edge_fields.indexOf('to_node');
const { nodes, edges, strings } = snap;
const nodeCount = nodes.length / NF;

const firstEdge = new Uint32Array(nodeCount + 1);
for (let n = 0, e = 0; n < nodeCount; n++) {
  firstEdge[n] = e;
  e += nodes[n * NF + iEdgeCount] * EF;
  firstEdge[n + 1] = e;
}
const name = (n) => strings[nodes[n * NF + iName]];
const type = (n) => nTypes[nodes[n * NF + iType]];
const edgeLabel = (e) => {
  const t = eTypes[edges[e + eType]];
  const v = edges[e + eName];
  if (t === 'element' || t === 'hidden') return `[${v}]`;
  const str = strings[v];
  const m = /in WeakMap \(table @(\d+)\)/.exec(str);
  return m ? `(WeakMap value, table @${m[1]})` : str;
};

// WeakMap entries: V8 emits "part of key (X @id) -> value (Y @id) pair in
// WeakMap" edges from the table. Re-route them from the key, so paths show
// what keeps the key alive instead of going through the WeakMap.
const iId = node_fields.indexOf('id');
const byId = new Map();
for (let n = 0; n < nodeCount; n++) byId.set(nodes[n * NF + iId], n);
const ephemeron = /part of key \(.*? @(\d+)\) -> value/;
const reroute = new Map(); // key node -> [edge offsets]
const tables = new Map(); // table node -> [{ e, key }]
const tableOf = new Map(); // edge offset -> table node
for (let n = 0; n < nodeCount; n++) {
  for (let e = firstEdge[n]; e < firstEdge[n + 1]; e += EF) {
    if (eTypes[edges[e + eType]] !== 'internal') continue;
    const m = ephemeron.exec(strings[edges[e + eName]]);
    if (!m) continue;
    const key = byId.get(Number(m[1]));
    if (key === undefined) continue;
    if (!reroute.has(key)) reroute.set(key, []);
    reroute.get(key).push(e);
    if (!tables.has(n)) tables.set(n, []);
    tables.get(n).push({ e, key });
    tableOf.set(e, n);
  }
}
const isEphemeron = (e) => eTypes[edges[e + eType]] === 'internal' && ephemeron.test(strings[edges[e + eName]]);

// BFS from the synthetic root over strong edges
const parent = new Int32Array(nodeCount).fill(-1);
const parentEdge = new Int32Array(nodeCount).fill(-1);
const seen = new Uint8Array(nodeCount);
const queue = new Uint32Array(nodeCount);
let qh = 0;
let qt = 0;
queue[qt++] = 0;
seen[0] = 1;
while (qh < qt) {
  const n = queue[qh++];
  const visit = (e) => {
    const to = edges[e + eTo] / NF;
    if (seen[to]) return;
    seen[to] = 1;
    parent[to] = n;
    parentEdge[to] = e;
    queue[qt++] = to;
  };
  for (let e = firstEdge[n]; e < firstEdge[n + 1]; e += EF) {
    const t = eTypes[edges[e + eType]];
    if (t === 'weak' || t === 'shortcut') continue;
    if (t === 'internal' && isEphemeron(e)) continue;
    visit(e);
  }
  // ephemerons: the value is live only when both the key and the table are
  for (const e of reroute.get(n) ?? []) if (seen[tableOf.get(e)]) visit(e);
  for (const { e, key } of tables.get(n) ?? []) if (seen[key]) visit(e);
}

// tagged objects: nodes with a `__leakTag` property pointing at a LeakTag
const tagged = [];
for (let n = 0; n < nodeCount; n++) {
  for (let e = firstEdge[n]; e < firstEdge[n + 1]; e += EF) {
    if (eTypes[edges[e + eType]] === 'property' && strings[edges[e + eName]] === '__leakTag') {
      const tag = edges[e + eTo] / NF;
      // read the tag's `test` / `kind` / `label` strings
      const info = {};
      for (let f = firstEdge[tag]; f < firstEdge[tag + 1]; f += EF) {
        const k = strings[edges[f + eName]];
        if (['test', 'kind', 'label'].includes(k)) info[k] = name(edges[f + eTo] / NF);
      }
      tagged.push({ n, info });
    }
  }
}

function pathTo(n) {
  const steps = [];
  let cur = n;
  while (cur > 0 && parent[cur] >= 0) {
    const e = parentEdge[cur];
    steps.push(`${type(parent[cur]) === 'object' || type(parent[cur]) === 'native' ? name(parent[cur]) : `(${type(parent[cur])}) ${name(parent[cur]).slice(0, 40)}`} .${edgeLabel(e)}`);
    cur = parent[cur];
  }
  return steps.reverse();
}

const groups = new Map();
let unreachable = 0;
for (const { n, info } of tagged) {
  if (!seen[n]) {
    unreachable++;
    continue;
  }
  const p = pathTo(n);
  const key = p.slice(-hops).join(' → ').replace(/\[\d+\]/g, '[i]');
  const g = groups.get(key) ?? { count: 0, examples: [], full: p };
  g.count++;
  if (g.examples.length < 3) g.examples.push(`${info.kind}:${info.label} (${info.test})`);
  groups.set(key, g);
}

console.log(`snapshot nodes: ${nodeCount}, tagged objects: ${tagged.length}, unreachable (only weakly held): ${unreachable}`);
let i = 0;
for (const [, g] of [...groups.entries()].sort((a, b) => b[1].count - a[1].count)) {
  if (i++ >= maxPrint) break;
  console.log(`\n## ${g.count} object(s), e.g. ${g.examples.join(' | ')}`);
  console.log('   ' + g.full.join('\n   → '));
}

// --id <node id>: also print the path to that node (e.g. a WeakMap table)
if (args.includes('--id')) {
  for (const id of opt('id', '').split(',')) {
    const n = byId.get(Number(id));
    console.log(`\n## path to @${id} (${n === undefined ? 'missing' : name(n)})`);
    if (n !== undefined) console.log('   ' + pathTo(n).join('\n   → '));
  }
}
