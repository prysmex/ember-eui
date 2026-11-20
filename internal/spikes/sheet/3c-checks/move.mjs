// Moves one stage's members out of the component into their modules
// (V03C-DESIGN.md 3.2, 5), rewriting only the paths:
//
//   node move.mjs --src <packages/sheet/src> --stage N [--tops name=prop,...]
//
// - A moved member's `this.x` becomes `this.x` (x is the module's own),
//   `this.sheet.<module>.x` (x is another module's) or `this.sheet.x`
//   (x stays on the component). `this.<module>.x` (a module of an earlier
//   stage) becomes `this.sheet.<module>.x`.
// - A member that stays: `this.x` becomes `this.<module>.x`.
// - Modules of earlier stages: `this.sheet.x` becomes `this.x` or
//   `this.sheet.<module>.x`.
// - The component's template: `this.x` becomes `this.<module>.x`.
// - `-private` files: `sheet.x` and `@sheet.x` become `sheet.<module>.x`.
// - `--tops`: top-level declarations to move above a module's class.
// A bare `this` in a moved member is printed, not changed: each is an
// owner to look at (6.1). Imports are not written: add them by hand.
// Then run Prettier and `lint:types`.
import { readFileSync, writeFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { ts } from './parse.mjs';
import { modules } from './module-map.mjs';

const args = process.argv.slice(2);
const opt = (k) => args[args.indexOf(k) + 1];
const SRC = opt('--src');
const STAGE = Number(opt('--stage'));
const topsArg = args.includes('--tops') ? opt('--tops') : '';
const movedTops = new Map(
  topsArg ? topsArg.split(',').map((x) => x.split('=')) : []
);

const live = modules.filter((m) => m.stage <= STAGE);
const now = modules.filter((m) => m.stage === STAGE);
const earlier = new Set(
  modules.filter((m) => m.stage < STAGE).map((m) => m.prop)
);
const ownerOf = new Map();
for (const m of live) for (const n of m.members) ownerOf.set(n, m.prop);
const movingNow = new Map();
for (const m of now) for (const n of m.members) movingNow.set(n, m.prop);

/** The source with each `<template>` replaced by TS of the same length. */
function blankTemplates(src, filename) {
  if (!filename.endsWith('.gts')) return { code: src, ranges: [] };
  const { Preprocessor } = (await_ct ??= loadContentTag());
  const parsed = new Preprocessor().parse(src, { filename });
  let code = src;
  const ranges = [];
  for (const t of parsed) {
    const s = t.range.startUtf16Codepoint;
    const e = t.range.endUtf16Codepoint;
    const fill = t.type === 'class-member' ? 'static __template = 0;' : '0';
    code = code.slice(0, s) + fill.padEnd(e - s, ' ') + code.slice(e);
    ranges.push({ s, e, type: t.type });
  }
  return { code, ranges };
}
let await_ct;
function loadContentTag() {
  const NM = process.env.CHECKS_NODE_MODULES;
  const pnpm = join(NM, '.pnpm');
  const v = readdirSync(pnpm)
    .filter((d) => d.startsWith('content-tag@'))
    .sort()
    .at(-1);
  return (
    ts.sys && require_(join(pnpm, v, 'node_modules/content-tag/pkg/node.cjs'))
  );
}
import { createRequire } from 'node:module';
const require_ = createRequire(import.meta.url);

function applyEdits(text, edits, base = 0) {
  const sorted = [...edits].sort((a, b) => b.s - a.s);
  let out = text;
  for (const e of sorted)
    out = out.slice(0, e.s - base) + e.text + out.slice(e.e - base);
  return out;
}

const isThis = (n) => n.kind === ts.SyntaxKind.ThisKeyword;

// ---- The component ----
const compPath = join(SRC, 'components/eui-sheet.gts');
const src = readFileSync(compPath, 'utf8');
const { code, ranges } = blankTemplates(src, compPath);
const sf = ts.createSourceFile(
  'c.ts',
  code,
  ts.ScriptTarget.Latest,
  true,
  ts.ScriptKind.TS
);
const cls = sf.statements.find(
  (s) => ts.isClassDeclaration(s) && s.name?.text === 'EuiSheet'
);
const lineOf = (pos) => sf.getLineAndCharacterOfPosition(pos).line + 1;
const nameOf = (m) =>
  ts.isConstructorDeclaration(m) ? 'constructor' : m.name?.getText(sf);

const compEdits = [];
const moved = new Map(now.map((m) => [m.prop, []])); // prop → [{ text }]
const warnings = [];

for (const m of cls.members) {
  const name = nameOf(m);
  if (name === '__template') continue;
  const dest = movingNow.get(name) ?? null;
  const edits = [];
  const visit = (n) => {
    if (
      ts.isClassDeclaration(n) ||
      ts.isClassExpression(n) ||
      ts.isFunctionExpression(n) ||
      ts.isFunctionDeclaration(n)
    ) {
      warnings.push(
        `${name}: nested ${ts.SyntaxKind[n.kind]} at line ${lineOf(n.getStart(sf))}: check by hand`
      );
    }
    if (ts.isPropertyAccessExpression(n) && isThis(n.expression)) {
      const x = n.name.text;
      const t0 = n.expression.getStart(sf);
      const t1 = n.expression.getEnd();
      if (dest) {
        if (earlier.has(x)) {
          // `this.<module>.y`
          const parent = n.parent;
          if (
            x === dest &&
            ts.isPropertyAccessExpression(parent) &&
            parent.expression === n
          ) {
            edits.push({ s: t0, e: n.getEnd(), text: 'this' });
          } else if (x !== dest) {
            edits.push({ s: t0, e: t1, text: 'this.sheet' });
          } else {
            warnings.push(
              `${name}: bare this.${x} (own module) at line ${lineOf(t0)}`
            );
          }
          return; // do not descend: `this.<module>` handled
        }
        const owner = ownerOf.get(x);
        if (owner === dest) {
          // own member: unchanged
        } else if (owner) {
          edits.push({ s: t0, e: t1, text: `this.sheet.${owner}` });
        } else {
          edits.push({ s: t0, e: t1, text: 'this.sheet' });
        }
        return;
      }
      const owner = movingNow.get(x);
      if (owner) edits.push({ s: t0, e: t1, text: `this.${owner}` });
      return;
    }
    if (isThis(n) && dest) {
      const lineStart = code.lastIndexOf('\n', n.getStart(sf)) + 1;
      const lineEnd = code.indexOf('\n', n.getStart(sf));
      warnings.push(
        `${name} → ${dest}: bare this at line ${lineOf(n.getStart(sf))}: ${code.slice(lineStart, lineEnd).trim()}`
      );
    }
    ts.forEachChild(n, visit);
  };
  visit(m);
  if (dest) {
    const s = m.pos;
    const e = m.end;
    moved.get(dest).push(applyEdits(src.slice(s, e), edits, s));
    compEdits.push({ s, e, text: '' });
  } else {
    compEdits.push(...edits);
  }
}

// Top-level declarations moving to a module.
const topsFor = new Map(now.map((m) => [m.prop, []]));
for (const st of sf.statements) {
  let names = [];
  if (ts.isVariableStatement(st))
    names = st.declarationList.declarations.map((d) => d.name.getText(sf));
  else if (st.name && !ts.isClassDeclaration(st)) names = [st.name.text];
  const hit = names.find((n) => movedTops.has(n));
  if (!hit) continue;
  const prop = movedTops.get(hit);
  if (!topsFor.has(prop))
    throw new Error(`--tops ${hit}=${prop}: not a module of this stage`);
  topsFor.get(prop).push(src.slice(st.pos, st.end));
  compEdits.push({ s: st.pos, e: st.end, text: '' });
}

// The template.
const names = [...movingNow.keys()].sort((a, b) => b.length - a.length);
const nameRe = new RegExp(`\\bthis\\.(${names.join('|')})\\b`, 'g');
for (const r of ranges.filter((r) => r.type === 'class-member')) {
  const text = src
    .slice(r.s, r.e)
    .replace(nameRe, (_, x) => `this.${movingNow.get(x)}.${x}`);
  compEdits.push({ s: r.s, e: r.e, text });
}

// Module fields and imports.
const existingFields = [
  ...src.matchAll(/^  readonly (\w+) = new \w+<T>\(this\);$/gm)
];
const fieldLines = now
  .map((m) => `  readonly ${m.prop} = new ${m.cls}<T>(this);`)
  .join('\n');
if (existingFields.length) {
  const last = existingFields.at(-1);
  const at = last.index + last[0].length;
  compEdits.push({ s: at, e: at, text: '\n' + fieldLines });
} else {
  const anchor = src.indexOf(
    "  @service('eui-i18n') declare euiI18n: EuiI18n;"
  );
  const at = src.indexOf('\n', anchor);
  compEdits.push({
    s: at,
    e: at,
    text:
      '\n\n  /* The feature modules (V03C-DESIGN.md 3.2): each owns its state. */\n' +
      fieldLines
  });
}
const importLines = now
  .map((m) => `import ${m.cls} from '../-private/sheet/${m.file}';`)
  .join('\n');
const lastValueImport = [...src.matchAll(/^import (?!type)[^;]*;$/gms)].at(-1);
{
  const at = lastValueImport.index + lastValueImport[0].length;
  compEdits.push({ s: at, e: at, text: '\n' + importLines });
}

writeFileSync(compPath, applyEdits(src, compEdits));

// ---- New module files ----
for (const m of now) {
  const path = join(SRC, '-private/sheet', m.file);
  if (existsSync(path)) throw new Error(path + ' exists');
  const body = moved.get(m.prop).join('');
  const tops = topsFor.get(m.prop).join('');
  const text =
    `/** ${m.cls}: ${m.prop} (V03C-DESIGN.md 3.2). */\n` +
    `import type EuiSheet from '../../components/eui-sheet.gts';\n` +
    `${tops}\n\n` +
    `export default class ${m.cls}<T extends object> {\n` +
    `  sheet: EuiSheet<T>;\n\n` +
    `  constructor(sheet: EuiSheet<T>) {\n    this.sheet = sheet;\n  }\n` +
    `${body}\n}\n`;
  writeFileSync(path, text);
  console.log(`wrote ${path}: ${moved.get(m.prop).length} members`);
}

// ---- Modules of earlier stages ----
const dir = join(SRC, '-private/sheet');
for (const f of readdirSync(dir).filter((f) => f.endsWith('.ts'))) {
  const mod = modules.find((m) => m.file === f);
  if (!mod || mod.stage >= STAGE) continue;
  const path = join(dir, f);
  const text = readFileSync(path, 'utf8');
  const msf = ts.createSourceFile(
    f,
    text,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TS
  );
  const edits = [];
  const visit = (n) => {
    if (
      ts.isPropertyAccessExpression(n) &&
      ts.isPropertyAccessExpression(n.expression) &&
      n.expression.name.text === 'sheet' &&
      isThis(n.expression.expression)
    ) {
      const owner = movingNow.get(n.name.text);
      if (owner === mod.prop)
        edits.push({
          s: n.expression.getStart(msf),
          e: n.expression.getEnd(),
          text: 'this'
        });
      else if (owner)
        edits.push({
          s: n.expression.getStart(msf),
          e: n.expression.getEnd(),
          text: `this.sheet.${owner}`
        });
      return;
    }
    ts.forEachChild(n, visit);
  };
  visit(msf);
  if (edits.length) {
    writeFileSync(path, applyEdits(text, edits));
    console.log(`re-pointed ${edits.length} paths in ${f}`);
  }
}

// ---- -private components and helpers ----
const privRe = new RegExp(
  `(@sheet|\\bsheet)(\\??\\.)(${names.join('|')})\\b`,
  'g'
);
const privDir = join(SRC, '-private');
const walkDir = (d) =>
  readdirSync(d, { withFileTypes: true }).flatMap((e) =>
    e.isDirectory()
      ? e.name === 'sheet'
        ? []
        : walkDir(join(d, e.name))
      : [join(d, e.name)]
  );
for (const path of [...walkDir(privDir), ...walkDir(join(SRC, 'search-ui'))]) {
  if (!/\.(ts|gts)$/.test(path)) continue;
  const text = readFileSync(path, 'utf8');
  let count = 0;
  const next = text.replace(privRe, (_, a, dot, x) => {
    count++;
    return `${a}${dot}${movingNow.get(x)}.${x}`;
  });
  if (count) {
    writeFileSync(path, next);
    console.log(`re-pointed ${count} paths in ${path.slice(SRC.length + 1)}`);
  }
}

for (const w of warnings) console.log('LOOK ' + w);
