import { module, test } from 'qunit';

// the core's sources as text (ESLint enforces the same rule; this fails in the test run)
const sources = import.meta.glob('../../src/core/**/*.ts', {
  query: '?raw',
  import: 'default',
  eager: true
}) as Record<string, string>;

// every source (V02-DESIGN.md 7.1: the connector is typed structurally)
const allSources = import.meta.glob('../../src/**/*.{ts,gts}', {
  query: '?raw',
  import: 'default',
  eager: true
}) as Record<string, string>;

const FORBIDDEN = [
  "from '@ember",
  "from '@glimmer",
  "from 'ember-",
  "from '@ember-eui"
];

module('Unit | Sheet | core boundary', function () {
  test('B1 src/core has no Ember imports', function (assert) {
    const files = Object.keys(sources);
    assert.true(files.length >= 10, `${files.length} core files read`);
    for (const [file, source] of Object.entries(sources)) {
      const found = FORBIDDEN.filter((marker) => source.includes(marker));
      assert.deepEqual(found, [], file);
    }
  });

  test('B2 no source imports EmberSearchUi, not even its types', function (assert) {
    const files = Object.keys(allSources);
    assert.true(
      files.some((file) => file.includes('/search-ui/')),
      `${files.length} files read, the connector among them`
    );
    for (const [file, source] of Object.entries(allSources)) {
      assert.false(
        /from '(ember-search-ui|@elastic\/search-ui)/.test(source),
        file
      );
    }
  });
});
