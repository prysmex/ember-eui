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
