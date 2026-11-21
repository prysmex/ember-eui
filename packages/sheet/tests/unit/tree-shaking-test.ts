import { module, test } from 'qunit';

// the package's own files, as text (the same cast as bundle-split-test.ts)
const files = import.meta.glob(
  ['../../package.json', '../../rollup.config.mjs'],
  {
    query: '?raw',
    import: 'default',
    eager: true
  }
) as Record<string, string>;

const sources = import.meta.glob('../../src/**/*.{ts,gts}', {
  query: '?raw',
  import: 'default',
  eager: true
}) as Record<string, string>;

module('Unit | Sheet | tree shaking', function () {
  // An app-js entry puts the component in every host's app tree: a host
  // built with `staticInvokables: false`, or a classic build, bundles it
  // (and all it imports) whether it renders it or not. Hosts import the
  // components; loose-mode templates opt in with a re-export in their own
  // app tree (docs/sheet.md). `pnpm size --compat` measures it.
  test('TS1 package.json publishes no app-js', function (assert) {
    const pkg = JSON.parse(files['../../package.json']!) as {
      'ember-addon': Record<string, unknown>;
      sideEffects: string[];
    };
    assert.strictEqual(pkg['ember-addon']['version'], 2);
    assert.false('app-js' in pkg['ember-addon'], 'no ember-addon.app-js');
    assert.deepEqual(pkg.sideEffects, ['*.css', './tests/**']);
  });

  test('TS2 the build does not write app-js back', function (assert) {
    const rollup = files['../../rollup.config.mjs']!;
    assert.true(rollup.includes('addon.publicEntrypoints('));
    assert.false(
      /^\s*addon\.appReexports\(/m.test(rollup),
      'no addon.appReexports()'
    );
  });

  // `sideEffects` says the modules have none: a top-level call (a
  // registration, a global listener) would be dropped with the module or
  // keep it alive.
  test('TS3 no source module calls a function at its top level', function (assert) {
    const found = Object.entries(sources).flatMap(([file, source]) =>
      [...source.matchAll(/^(?:await\s+)?[A-Za-z_$][\w$.]*\s*\(/gm)].map(
        (match) => `${file.replace('../../src/', '')}: ${match[0]}`
      )
    );
    assert.true(Object.keys(sources).length > 100, 'the sources are read');
    assert.deepEqual(found, []);
  });
});
