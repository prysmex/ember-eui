/**
 * Checks the built packages (run `pnpm build:packages` first) for imports
 * that make ember-eui expensive to import:
 *
 *   node --test scripts/dist-hygiene.test.mjs
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

/** `{ file, specifier, dynamic }` for every import and re-export of a package's dist. */
function distImports(pkg) {
  const dist = join(root, 'packages', pkg, 'dist');
  assert.ok(existsSync(dist), `build ${pkg} first`);
  const imports = [];
  for (const file of readdirSync(dist, { recursive: true })) {
    if (!file.endsWith('.js')) continue;
    const code = readFileSync(join(dist, file), 'utf8');
    for (const [, specifier] of code.matchAll(
      /^(?:import|export)\b[^'"]*?(?:from\s*)?['"]([^'"]+)['"]/gm
    )) {
      imports.push({ file, specifier, dynamic: false });
    }
    for (const [, specifier] of code.matchAll(
      /\bimport\(\s*['"]([^'"]+)['"]\s*\)/g
    )) {
      imports.push({ file, specifier, dynamic: true });
    }
  }
  return imports;
}

const describe = (found) =>
  found.map(({ file, specifier }) => `${file}: ${specifier}`).join('\n');

test('core does not import CommonJS lodash or the theme packages', () => {
  const found = distImports('core').filter(({ specifier }) =>
    /^(lodash(\/|$)|@elastic\/eui-theme-)/.test(specifier)
  );
  assert.equal(found.length, 0, describe(found));
});

test('flatpickr imports flatpickr only when a picker is set up', () => {
  const found = distImports('flatpickr').filter(
    ({ specifier, dynamic }) => /^flatpickr(\/|$)/.test(specifier) && !dynamic
  );
  assert.equal(found.length, 0, describe(found));
  assert.ok(
    distImports('flatpickr').some(
      ({ specifier, dynamic }) => specifier === 'flatpickr' && dynamic
    )
  );
});

test('markdown format loads its parser on first render', () => {
  const format = distImports('core').filter(
    ({ file }) => file === 'components/eui-markdown-format.js'
  );
  assert.ok(format.length > 0);
  const found = format.filter(({ specifier }) =>
    /^(unified|remark-|rehype-|refractor|node-emoji|emoticon)|markdown-default-plugins|markdown-engine\.js$/.test(
      specifier
    )
  );
  assert.equal(found.length, 0, describe(found));
});

test('nothing imports node-emoji or remark-emoji (they require CommonJS lodash)', () => {
  const found = distImports('core').filter(({ specifier }) =>
    /^(node-emoji|remark-emoji)$/.test(specifier)
  );
  assert.equal(found.length, 0, describe(found));
});

test('the code language loaders are imported with the first language', () => {
  const found = distImports('core').filter(
    ({ specifier, dynamic }) => /\/languages\.js$/.test(specifier) && !dynamic
  );
  assert.equal(found.length, 0, describe(found));
});

test('the icon loaders are imported with the first icon that loads', () => {
  const found = distImports('core').filter(
    ({ specifier, dynamic }) => /\/icons\.js$/.test(specifier) && !dynamic
  );
  assert.equal(found.length, 0, describe(found));
});

test('every icon type has a public module', () => {
  const dir = join(root, 'packages/core/dist/icons');
  for (const type of ['search', 'magnify', 'cross', 'logoElastic', 'empty']) {
    assert.ok(existsSync(join(dir, `${type}.js`)), type);
  }
});
