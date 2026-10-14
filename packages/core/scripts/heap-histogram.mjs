#!/usr/bin/env node
/**
 * Aggregates a heap snapshot by node type + constructor name (self size and
 * count). With two snapshots, prints the growth between them.
 *
 *   node scripts/heap-histogram.mjs a.heapsnapshot [b.heapsnapshot] [--top 40]
 */
import fs from 'node:fs';

const args = process.argv.slice(2);
const files = args.filter((a) => !a.startsWith('--') && !/^\d+$/.test(a));
const top = Number(args.includes('--top') ? args[args.indexOf('--top') + 1] : 40);

function histogram(file) {
  const snap = JSON.parse(fs.readFileSync(file, 'utf8'));
  const { node_fields, node_types } = snap.snapshot.meta;
  const NF = node_fields.length;
  const iType = node_fields.indexOf('type');
  const iName = node_fields.indexOf('name');
  const iSize = node_fields.indexOf('self_size');
  const types = node_types[0];
  const h = new Map();
  let total = 0;
  for (let i = 0; i < snap.nodes.length; i += NF) {
    const type = types[snap.nodes[i + iType]];
    let name = snap.strings[snap.nodes[i + iName]];
    if (type === 'string' || type === 'concatenated string' || type === 'sliced string') name = '';
    if (type === 'code' || type === 'hidden' || type === 'array') name = name.slice(0, 30);
    if (type === 'native') name = name.replace(/ .*/, '');
    const key = `${type}:${name.slice(0, 60)}`;
    const e = h.get(key) ?? { count: 0, size: 0 };
    e.count++;
    e.size += snap.nodes[i + iSize];
    total += snap.nodes[i + iSize];
    h.set(key, e);
  }
  return { h, total };
}

const a = histogram(files[0]);
if (files.length === 1) {
  console.log(`total self size ${(a.total / 1e6).toFixed(1)} MB`);
  for (const [k, v] of [...a.h].sort((x, y) => y[1].size - x[1].size).slice(0, top)) {
    console.log(`${(v.size / 1e6).toFixed(2).padStart(8)} MB ${String(v.count).padStart(8)}  ${k}`);
  }
} else {
  const b = histogram(files[1]);
  console.log(`total ${(a.total / 1e6).toFixed(1)} MB -> ${(b.total / 1e6).toFixed(1)} MB`);
  const rows = [];
  for (const [k, v] of b.h) {
    const o = a.h.get(k) ?? { count: 0, size: 0 };
    rows.push([k, v.size - o.size, v.count - o.count]);
  }
  for (const [k, ds, dc] of rows.sort((x, y) => y[1] - x[1]).slice(0, top)) {
    console.log(`${(ds / 1e6).toFixed(2).padStart(8)} MB ${String(dc).padStart(8)}  ${k}`);
  }
}
