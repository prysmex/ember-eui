// The verbatim-move check of V03C-DESIGN.md 5, check 6.
//
//   node verbatim.mjs --old <old eui-sheet.gts> --new <file>... [--pair <old>::<new>]...
//                     [--allow-action-to-arrow]
//
// --old: the component before the split (any earlier version; the paths
//   are normalised, so the stage 0 baseline works for every stage).
// --new: the component now and every file the old one's code moved to
//   (src/-private/sheet/*.ts, *.gts).
// --pair: another file whose code did not move but whose paths changed
//   (a -private component): its declarations and templates are compared
//   one to one.
//
// A member or top-level declaration is compared by its canonical form
// (parse.mjs): layout and parentheses ignored, `this.`, `this.sheet.` and
// `this.sheet.<module>.` the same. Its decorators, its kind (method,
// getter, arrow field, field, modifier) and its comments must be the same.
// A body that differs only by `this` → `this.sheet` as a value (an owner,
// 6.1) is listed as OWNER for a look, not failed.
// Exit 1 on any failure.
import { readFileSync } from 'node:fs';
import { parseFile } from './parse.mjs';
import { modules as moduleMap } from './module-map.mjs';

const args = process.argv.slice(2);
let oldFile;
const newFiles = [];
const pairs = [];
let allowActionToArrow = false;
for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === '--old') oldFile = args[++i];
  else if (a === '--new') {
    while (args[i + 1] && !args[i + 1].startsWith('--'))
      newFiles.push(args[++i]);
  } else if (a === '--pair') pairs.push(args[++i].split('::'));
  else if (a === '--allow-action-to-arrow') allowActionToArrow = true;
  else throw new Error('Unknown argument ' + a);
}
if (!oldFile || !newFiles.length) throw new Error('Need --old and --new');

const read = (f) => readFileSync(f, 'utf8');

// The module properties: fields of the new component set to `new X(this)`.
function moduleNames(files) {
  const names = new Set();
  for (const f of files) {
    const src = read(f);
    for (const m of src.matchAll(
      /^\s+(?:readonly\s+)?(\w+)\s*=\s*new\s+\w+(?:<[^>]*>)?\(this\);/gm
    ))
      names.add(m[1]);
  }
  return names;
}
const modules = moduleNames(newFiles);

const failures = [];
const owners = [];
let compared = 0;
const fail = (msg) => failures.push(msg);

function ownerNormal(c) {
  // `this.sheet` as a value reads as `THIS . sheet` (not followed by `.`).
  return c.replace(/THIS \. sheet(?! (\.|\?\.) )/g, 'this');
}

function compare(label, a, b) {
  compared++;
  if (a.kind !== b.kind) {
    const ok =
      allowActionToArrow &&
      a.kind === 'method' &&
      a.decorators === '@action' &&
      b.kind === 'arrow-field';
    if (!ok) fail(`${label}: kind ${a.kind} → ${b.kind}`);
  }
  if (a.decorators !== undefined && a.decorators !== b.decorators) {
    const ok =
      allowActionToArrow &&
      a.decorators === '@action' &&
      b.decorators === 'none';
    if (!ok) fail(`${label}: decorators ${a.decorators} → ${b.decorators}`);
  }
  if (a.static !== b.static) fail(`${label}: static ${a.static} → ${b.static}`);
  if (JSON.stringify(a.comments) !== JSON.stringify(b.comments)) {
    fail(
      `${label}: comments differ\n    old: ${JSON.stringify(a.comments)}\n    new: ${JSON.stringify(b.comments)}`
    );
  }
  if (a.canon === b.canon) return;
  if (ownerNormal(a.canon) === ownerNormal(b.canon)) {
    owners.push(label);
    return;
  }
  if (
    allowActionToArrow &&
    a.decorators === '@action' &&
    b.kind === 'arrow-field'
  ) {
    // `@action name(x) {` → `name = (x) => {`: compared after the header.
    const body = (c) => c.slice(c.indexOf('{'));
    if (body(a.canon) === body(b.canon)) return;
  }
  fail(`${label}: body differs\n${firstDiff(a.canon, b.canon)}`);
}

function firstDiff(a, b) {
  const x = a.split(' ');
  const y = b.split(' ');
  let i = 0;
  while (i < x.length && x[i] === y[i]) i++;
  const from = Math.max(0, i - 12);
  return `    old: …${x.slice(from, i + 12).join(' ')}\n    new: …${y.slice(from, i + 12).join(' ')}`;
}

function normalTemplate(t) {
  const mods = [...modules].join('|');
  let s = t;
  if (mods)
    s = s.replace(
      new RegExp(
        `((?:@sheet|this\\.sheet|this\\.args\\.sheet|this)\\.)(?:${mods})\\.`,
        'g'
      ),
      '$1'
    );
  return s.replace(/\s+/g, '');
}

// The component and the moved code.
const old = parseFile(read(oldFile), oldFile, modules);
const oldComponent = old.classes.find((c) => c.isComponent);
const pool = new Map(); // member name → [{ file, cls, m }]
const tops = new Map();
let newComponent;
const newTemplates = [];
for (const f of newFiles) {
  const p = parseFile(read(f), f, modules);
  for (const c of p.classes) {
    if (c.isComponent) {
      newComponent = c;
      for (const t of p.templates)
        if (t.type === 'class-member') newTemplates.push(t);
    }
    if (!c.isComponent && !c.isHosted) continue;
    for (const m of c.members) {
      if (c.isHosted && (m.name === 'sheet' || m.name === 'constructor'))
        continue;
      if (c.isComponent && modules.has(m.name)) continue;
      if (!pool.has(m.name)) pool.set(m.name, []);
      pool.get(m.name).push({ file: f, cls: c.name, m });
    }
  }
  for (const t of p.tops) {
    if (!tops.has(t.name)) tops.set(t.name, []);
    tops.get(t.name).push({ file: f, t });
  }
}
if (!newComponent) fail('No component class in --new files');

const short = (f) => f.replace(/^(.*\/)?packages\/sheet\//, '');
const moved = new Map(); // file → count

for (const m of oldComponent.members) {
  const found = pool.get(m.name) ?? [];
  if (found.length === 0) {
    fail(`member ${m.name}: missing`);
    continue;
  }
  if (found.length > 1) {
    fail(
      `member ${m.name}: declared ${found.length} times (${found.map((x) => `${short(x.file)} ${x.cls}`).join(', ')})`
    );
    continue;
  }
  const { file, cls, m: n } = found[0];
  compare(`member ${m.name} (${short(file)} ${cls})`, m, n);
  // Where the module map puts it: its module once that module exists, else the component.
  const planned = moduleMap.find((x) => x.members.includes(m.name));
  const want =
    planned && modules.has(planned.prop)
      ? `src/-private/sheet/${planned.file} ${planned.cls}`
      : `src/components/eui-sheet.gts ${oldComponent.name}`;
  const got = `${short(file)} ${cls}`;
  if (got !== want)
    fail(`member ${m.name}: in ${got}, the module map says ${want}`);
  if (cls !== newComponent?.name || !file.endsWith('eui-sheet.gts'))
    moved.set(short(file), (moved.get(short(file)) ?? 0) + 1);
}
for (const [name, found] of pool) {
  if (!oldComponent.members.some((m) => m.name === name)) {
    fail(
      `member ${name}: new (${found.map((x) => `${short(x.file)} ${x.cls}`).join(', ')})`
    );
  }
}

for (const t of old.tops) {
  const found = tops.get(t.name) ?? [];
  if (found.length !== 1) {
    fail(
      `top ${t.name}: found ${found.length} times${found.length ? ' (' + found.map((x) => short(x.file)).join(', ') + ')' : ''}`
    );
    continue;
  }
  compare(`top ${t.name} (${short(found[0].file)})`, t, found[0].t);
}
for (const [name, found] of tops) {
  if (!old.tops.some((t) => t.name === name))
    fail(`top ${name}: new (${found.map((x) => short(x.file)).join(', ')})`);
}

// The component's template: only paths may change.
const oldTpl = old.templates.filter((t) => t.type === 'class-member');
if (oldTpl.length !== newTemplates.length)
  fail(`component templates: ${oldTpl.length} → ${newTemplates.length}`);
oldTpl.forEach((t, i) => {
  compared++;
  const a = normalTemplate(t.contents);
  const b = normalTemplate(newTemplates[i]?.contents ?? '');
  if (a !== b) {
    let k = 0;
    while (a[k] === b[k]) k++;
    fail(
      `component template ${i}: differs\n    old: …${a.slice(Math.max(0, k - 60), k + 60)}\n    new: …${b.slice(Math.max(0, k - 60), k + 60)}`
    );
  }
});

// Files whose paths changed only.
for (const [a, b] of pairs) {
  const pa = parseFile(read(a), a, modules);
  const pb = parseFile(read(b), b, modules);
  const key = (c, m) => `${c.name}.${m.name}`;
  const ma = new Map();
  const mb = new Map();
  for (const c of pa.classes) for (const m of c.members) ma.set(key(c, m), m);
  for (const c of pb.classes) for (const m of c.members) mb.set(key(c, m), m);
  for (const t of pa.tops) ma.set('top ' + t.name, t);
  for (const t of pb.tops) mb.set('top ' + t.name, t);
  for (const [k, m] of ma) {
    if (!mb.has(k)) fail(`${short(b)} ${k}: missing`);
    else compare(`${short(b)} ${k}`, m, mb.get(k));
  }
  for (const k of mb.keys()) if (!ma.has(k)) fail(`${short(b)} ${k}: new`);
  if (pa.templates.length !== pb.templates.length)
    fail(
      `${short(b)} templates: ${pa.templates.length} → ${pb.templates.length}`
    );
  pa.templates.forEach((t, i) => {
    compared++;
    if (
      normalTemplate(t.contents) !==
      normalTemplate(pb.templates[i]?.contents ?? '')
    )
      fail(`${short(b)} template ${i}: differs`);
  });
}

console.log(`modules: ${[...modules].join(', ') || '(none)'}`);
console.log(
  `compared: ${compared} (members, top-level declarations, templates)`
);
for (const [f, n] of [...moved].sort())
  console.log(`  moved to ${f}: ${n} members`);
if (owners.length) {
  console.log(`OWNER (this → this.sheet as a value; look at each):`);
  for (const o of owners) console.log('  ' + o);
}
if (failures.length) {
  console.log(`FAIL: ${failures.length}`);
  for (const f of failures) console.log('  ' + f);
  process.exit(1);
}
console.log('verbatim: OK');
