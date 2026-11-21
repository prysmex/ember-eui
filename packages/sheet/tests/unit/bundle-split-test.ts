import { module, test } from 'qunit';

// every source as text: the static import graph of <EuiSheet> is walked here
const sources = import.meta.glob('../../src/**/*.{ts,gts}', {
  query: '?raw',
  import: 'default',
  eager: true
}) as Record<string, string>;

const ROOT = '../../src/';

/** The relative modules a source imports statically (not `import type`, not `import()`). */
function staticImports(file: string): string[] {
  const source = sources[file] ?? '';
  const found: string[] = [];
  const re =
    /^(?:import|export)\s+(?!type\b)(?:[^'";]*?\sfrom\s+)?'(\.{1,2}\/[^']+)'/gm;
  for (const match of source.matchAll(re)) {
    const dir = file.slice(0, file.lastIndexOf('/') + 1);
    const parts = (dir + match[1]!).split('/');
    const out: string[] = [];
    for (const part of parts) {
      if (part === '..' && out.length && out[out.length - 1] !== '..')
        out.pop();
      else if (part !== '.') out.push(part);
    }
    found.push(out.join('/'));
  }
  return found;
}

/** Every module <EuiSheet>'s file reaches through static imports. */
function reachedFrom(entry: string): Set<string> {
  const seen = new Set<string>();
  const queue = [entry];
  while (queue.length) {
    const file = queue.pop()!;
    if (seen.has(file) || !(file in sources)) continue;
    seen.add(file);
    queue.push(...staticImports(file));
  }
  return seen;
}

module('Unit | Sheet | bundle split (readiness item 1)', function () {
  test('BS1 <EuiSheet> does not import the import screen or the barcode scan panel statically', function (assert) {
    const reached = reachedFrom(`${ROOT}components/eui-sheet.gts`);
    assert.true(reached.size > 50, `${reached.size} modules reached`);
    assert.true(
      reached.has(`${ROOT}-private/editors/barcode-editor.gts`),
      'the barcode editor is (the walk follows the field types)'
    );
    const unwanted = [...reached].filter(
      (file) =>
        file.includes('/components/eui-sheet-import.gts') ||
        file.includes('/-private/import/') ||
        file.endsWith('/barcode-scan-panel.gts')
    );
    assert.deepEqual(unwanted, []);
  });

  test('BS2 the scan panel is loaded by import() in the loader only', function (assert) {
    const naming = Object.entries(sources)
      .filter(([, source]) => source.includes('barcode-scan-panel'))
      .map(([file]) => file.replace(ROOT, ''));
    assert.deepEqual(naming.sort(), [
      '-private/editors/barcode-scan-loader.ts',
      '-private/editors/barcode-scan.gts'
    ]);
    const loader = sources[`${ROOT}-private/editors/barcode-scan-loader.ts`]!;
    assert.true(loader.includes("import('./barcode-scan-panel.gts')"));
    assert.false(
      /^import [^(]*'\.\/barcode-scan-panel\.gts'/m.test(
        loader.replace(/^import type .*$/gm, '')
      ),
      'no static import of the panel'
    );
  });
});
