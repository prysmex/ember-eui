// The owner gate on the AST (V03C-DESIGN.md 5, check 7; 6.1), next to the
// grep in gates.sh, which misses a call Prettier wraps:
//
//   node owner-gate.mjs <file>...
//
// In a module class (one with a `sheet` field), fails on:
// - `this` used as a value (not `this.x`), except as the first argument
//   of `later(...)` and `debounce(...)` (their target: the module is fine);
// - `this.isDestroying` / `this.isDestroyed` (a module is never destroyed);
// - a field initialiser that reads `this` outside a function (it would
//   run before the constructor stores `sheet`; 2.2).
import { readFileSync } from 'node:fs';
import { ts, stripTemplates } from './parse.mjs';

const failures = [];
let classes = 0;
for (const file of process.argv.slice(2)) {
  const { code } = stripTemplates(readFileSync(file, 'utf8'), file);
  const sf = ts.createSourceFile(
    file.replace(/\.gts$/, '.ts'),
    code,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TS
  );
  const at = (n) =>
    `${file}:${sf.getLineAndCharacterOfPosition(n.getStart(sf)).line + 1}`;
  for (const st of sf.statements) {
    if (!ts.isClassDeclaration(st)) continue;
    const hosted = st.members.some(
      (m) => ts.isPropertyDeclaration(m) && m.name.getText(sf) === 'sheet'
    );
    if (!hosted) continue;
    classes++;
    const visit = (n) => {
      if (n.kind === ts.SyntaxKind.ThisKeyword) {
        const p = n.parent;
        const isObject = ts.isPropertyAccessExpression(p) && p.expression === n;
        const isTarget =
          ts.isCallExpression(p) &&
          p.arguments[0] === n &&
          ts.isIdentifier(p.expression) &&
          (p.expression.text === 'later' || p.expression.text === 'debounce');
        if (!isObject && !isTarget)
          failures.push(
            `${at(n)}: this as a value: ${p.getText(sf).slice(0, 80)}`
          );
        if (isObject && /^(isDestroying|isDestroyed)$/.test(p.name.text))
          failures.push(`${at(n)}: this.${p.name.text}`);
      }
      ts.forEachChild(n, visit);
    };
    for (const m of st.members) {
      visit(m);
      if (ts.isPropertyDeclaration(m) && m.initializer) {
        const eager = (n) => {
          if (ts.isArrowFunction(n) || ts.isFunctionExpression(n)) return;
          if (n.kind === ts.SyntaxKind.ThisKeyword)
            failures.push(
              `${at(n)}: field ${m.name.getText(sf)} reads this at construction`
            );
          ts.forEachChild(n, eager);
        };
        eager(m.initializer);
      }
    }
  }
}
console.log(`owner gate (AST): ${classes} module classes`);
if (failures.length) {
  console.log(`FAIL: ${failures.length}`);
  for (const f of failures) console.log('  ' + f);
  process.exit(1);
}
console.log('owner gate (AST): OK');
