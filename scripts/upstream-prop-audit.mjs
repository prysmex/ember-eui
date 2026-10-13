// Compares the props upstream EUI declares for each component (from the
// installed @elastic/eui's eui.d.ts) with Ember EUI's Args/Blocks (from
// packages/core/declarations, so run `rollup --config` in packages/core first).
// Skips React-only and HTML-level props (children, refs, className, DOM
// events, plain HTML attributes); render props match blocks of the same
// name. The result is a candidate list: check each entry before acting.
// usage: node scripts/upstream-prop-audit.mjs . out.json
import { createRequire } from 'node:module';
import { readdirSync, statSync, writeFileSync, unlinkSync } from 'node:fs';
import { join, resolve } from 'node:path';

const repo = resolve(process.argv[2]);
const out = process.argv[3];
const require = createRequire(join(repo, 'packages/core/package.json'));
const ts = require('typescript');

const pnpm = join(repo, 'node_modules/.pnpm');
const euiDir = join(pnpm, readdirSync(pnpm).find((d) => /^@elastic\+eui@\d/.test(d)), 'node_modules/@elastic/eui');
const reactTypes = join(pnpm, readdirSync(pnpm).find((d) => d.startsWith('@types+react@18')), 'node_modules/@types/react');

// ---------- upstream ----------
const entry = join(repo, '.prop-audit-entry.ts');
writeFileSync(entry, "export * from '@elastic/eui';\n");
const upProgram = ts.createProgram([join(euiDir, 'eui.d.ts'), entry], {
  noEmit: true,
  skipLibCheck: true,
  jsx: ts.JsxEmit.React,
  baseUrl: repo,
  paths: { react: [join(reactTypes, 'index.d.ts')], 'react/*': [join(reactTypes, '*')] },
  types: []
});
const upChecker = upProgram.getTypeChecker();
const entrySf = upProgram.getSourceFile(entry);
const entrySym = upChecker.getSymbolAtLocation(entrySf);
const upExports = upChecker.getExportsOfModule(entrySym);

const isRef = (n) => /Ref$/.test(n);
// HTML attributes and DOM events: `...attributes` and `{{on}}` in Ember
const HTML = new Set(['name','value','role','rel','target','href','type','autoFocus','placeholder','disabled','tabIndex','form','lang','dir','hidden']);
const isDom = (n) => HTML.has(n) || /^on(Click|Change|Focus|Blur|KeyDown|KeyUp|MouseEnter|MouseLeave|MouseDown|MouseUp|Input|Submit)$/.test(n);
const COMMON = new Set(['children', 'className', 'css', 'data-test-subj', 'aria-label', 'aria-labelledby', 'aria-describedby', 'ref', 'key', 'style', 'id', 'title']);

function moduleNameOf(node) {
  for (let n = node; n; n = n.parent) {
    if (ts.isModuleDeclaration(n) && ts.isStringLiteral(n.name)) return n.name.text;
  }
  return '';
}

function propsTypeOf(sym) {
  const decl = sym.valueDeclaration ?? sym.declarations?.[0];
  if (!decl) return undefined;
  const type = upChecker.getTypeOfSymbolAtLocation(sym, decl);
  const call = type.getCallSignatures()[0];
  if (call && call.parameters[0]) {
    return upChecker.getTypeOfSymbolAtLocation(call.parameters[0], decl);
  }
  const ctor = type.getConstructSignatures()[0];
  if (ctor) {
    const inst = ctor.getReturnType();
    const p = inst.getProperty('props');
    if (p) return upChecker.getTypeOfSymbolAtLocation(p, decl);
  }
  return undefined;
}

const upstream = {};
for (const exp of upExports) {
  const name = exp.getName();
  if (!/^Eui[A-Z]/.test(name)) continue;
  const sym = exp.flags & ts.SymbolFlags.Alias ? upChecker.getAliasedSymbol(exp) : exp;
  let pt;
  try { pt = propsTypeOf(sym); } catch { continue; }
  if (!pt) continue;
  const props = new Set();
  const types = pt.isUnion() ? pt.types : [pt];
  for (const t of types) {
    for (const p of upChecker.getPropertiesOfType(t)) {
      const decls = p.declarations ?? [];
      const own = decls.some((d) => {
        const m = moduleNameOf(d);
        return m.startsWith('@elastic/eui/src/') && !m.endsWith('/components/common');
      });
      if (own && !COMMON.has(p.getName()) && !isRef(p.getName()) && !isDom(p.getName())) props.add(p.getName());
    }
  }
  if (props.size) upstream[name] = [...props].sort();
}

// ---------- ours ----------
const declDir = join(repo, 'packages/core/declarations/components');
const files = [];
(function walk(d) {
  for (const f of readdirSync(d)) {
    const p = join(d, f);
    if (statSync(p).isDirectory()) walk(p);
    else if (p.endsWith('.d.ts')) files.push(p);
  }
})(declDir);
const ourProgram = ts.createProgram(files, { noEmit: true, skipLibCheck: true, types: [] });
const ourChecker = ourProgram.getTypeChecker();
// barrel export name -> declaration file (classes are often named differently)
import { readFileSync } from 'node:fs';
const barrel = readFileSync(join(repo, 'packages/core/src/components.ts'), 'utf8');
const nameByFile = {};
for (const m of barrel.matchAll(/import (\w+) from '\.\/components\/([^']+)\.gts';/g)) {
  nameByFile[join(declDir, m[2].replace(/^/, '') + '.d.ts').replace('/components/components/', '/components/')] = m[1];
}
const ours = {};
for (const f of files) {
  const sf = ourProgram.getSourceFile(f);
  if (!sf) continue;
  // `export default EuiX;` names the file's component variable
  const defaultName = sf.statements.find(
    (st) => ts.isExportAssignment(st) && !st.isExportEquals && ts.isIdentifier(st.expression)
  )?.expression.text;
  for (const st of sf.statements) {
    // template-only: `declare const EuiX: TOC<EuiXSignature>; export default EuiX;`
    if (ts.isVariableStatement(st)) {
      for (const d of st.declarationList.declarations) {
        const tn = d.type;
        const arg = tn && (ts.isTypeReferenceNode(tn) || ts.isImportTypeNode(tn)) ? tn.typeArguments?.[0] : undefined;
        if (!arg || !ts.isIdentifier(d.name)) continue;
        const sig = ourChecker.getTypeFromTypeNode(arg);
        if (!sig.getProperty('Args') && !sig.getProperty('Blocks')) continue;
        const names = new Set();
        for (const key of ['Args', 'Blocks']) {
          const p = sig.getProperty(key);
          if (!p) continue;
          const t = ourChecker.getTypeOfSymbolAtLocation(p, arg);
          for (const q of ourChecker.getPropertiesOfType(t)) names.add(q.getName());
        }
        const isDefault = d.name.text === defaultName;
        const name = (isDefault && nameByFile[f]) || d.name.text;
        if (names.size && !ours[name]) ours[name] = [...names];
      }
      continue;
    }
    if (!ts.isClassDeclaration(st) || !st.name) continue;
    const isDefault = st.modifiers?.some((m) => m.kind === ts.SyntaxKind.DefaultKeyword);
    const name = (isDefault && nameByFile[f]) || st.name.text;
    const heritage = st.heritageClauses?.[0]?.types?.[0];
    const sigNode = heritage?.typeArguments?.[0];
    if (!sigNode) continue;
    const sig = ourChecker.getTypeFromTypeNode(sigNode);
    const names = new Set();
    for (const key of ['Args', 'Blocks']) {
      const p = sig.getProperty(key);
      if (!p) continue;
      const t = ourChecker.getTypeOfSymbolAtLocation(p, sigNode);
      for (const q of ourChecker.getPropertiesOfType(t)) names.add(q.getName());
    }
    if (names.size && !ours[name]) ours[name] = [...names];
  }
}

// ---------- diff ----------
const norm = (s) => s.toLowerCase().replace(/[-_]/g, '');
const report = {};
for (const [comp, props] of Object.entries(upstream)) {
  const mine = ours[comp];
  if (!mine) { report[comp] = { missingComponent: true }; continue; }
  const have = new Set(mine.map(norm));
  const missing = props.filter((p) => {
    const n = norm(p);
    if (have.has(n)) return false;
    // render props / node props are usually blocks
    const stripped = n.replace(/^render/, '');
    if (have.has(stripped)) return false;
    return true;
  });
  if (missing.length) report[comp] = { missing };
}
writeFileSync(out, JSON.stringify({ upstreamCount: Object.keys(upstream).length, oursCount: Object.keys(ours).length, report }, null, 2));
unlinkSync(entry);
console.log('upstream components', Object.keys(upstream).length, 'ours', Object.keys(ours).length);
console.log('components with differences', Object.keys(report).length);
