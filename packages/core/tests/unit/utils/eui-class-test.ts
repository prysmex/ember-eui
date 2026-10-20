import { module, test } from 'qunit';
import { serializeStyles } from '@emotion/serialize';

import {
  EuiThemeContext,
  createEuiEmotionCache
} from '#src/utils/emotion/context.ts';
import { euiClass } from '#src/utils/eui/styles.ts';

import type { EuiEmotionCache } from '#src/utils/emotion/context.ts';

function setup() {
  const cache: EuiEmotionCache = createEuiEmotionCache({ key: 'memo' });
  const context = new EuiThemeContext(() => ({ cache }));
  let serialized = 0;
  const css = cache.css;

  cache.css = (...args: Parameters<typeof css>) => {
    serialized++;
    return css(...args);
  };

  return { cache, context, serialized: () => serialized };
}

const row = serializeStyles([{ display: 'flex', label: 'row' }]);
const selected = serializeStyles([{ fontWeight: 700, label: 'selected' }]);

module('Unit | utils | eui | euiClass', function () {
  test('the same styles serialize once per cache', function (assert) {
    const { context, serialized } = setup();
    const first = euiClass(context, row, { padding: 4 }, undefined, false);

    for (let i = 0; i < 100; i++) {
      assert.strictEqual(
        euiClass(context, row, { padding: 4 }, undefined, false),
        first
      );
    }

    assert.strictEqual(serialized(), 1);

    const other = euiClass(context, row, selected, { padding: 4 });

    assert.notStrictEqual(other, first, 'other styles get their own class');
    assert.strictEqual(euiClass(context, row, selected, { padding: 4 }), other);
    assert.strictEqual(serialized(), 2);
    assert.notStrictEqual(
      euiClass(context, row, { padding: 5 }),
      first,
      'plain objects are keyed by their values'
    );
  });

  test('object literals with the same content find the same class', function (assert) {
    const { context, serialized } = setup();
    const first = euiClass(context, row, { '&:hover': { color: 'red' }, gap: 2 });

    assert.strictEqual(
      euiClass(context, row, { '&:hover': { color: 'red' }, gap: 2 }),
      first
    );
    assert.notStrictEqual(
      euiClass(context, row, { '&:hover': { color: 'blue' }, gap: 2 }),
      first
    );
    assert.notStrictEqual(
      euiClass(context, row, { gap: 2, '&:hover': { color: 'red' } }),
      first,
      'the order of the properties is part of the css'
    );
    assert.strictEqual(serialized(), 3);
  });

  test('styles that cannot be keyed are serialized every time', function (assert) {
    const { context, serialized } = setup();
    const withFunction = { color: () => 'red' } as unknown as object;

    euiClass(context, row, withFunction);
    euiClass(context, row, withFunction);

    assert.strictEqual(serialized(), 2);
  });

  test('a flushed cache inserts the rules again', function (assert) {
    const { cache, context } = setup();
    const className = euiClass(context, row);
    const name = className.slice('memo-'.length);

    assert.true(cache.cache.inserted[name] !== undefined);

    cache.flush();

    assert.strictEqual(euiClass(context, row), className);
    assert.true(cache.cache.inserted[name] !== undefined, 'inserted again');
  });

  // the memo must never change a class: compare with the cache's own css()
  test('returns what serializing the styles returns, for any mix', function (assert) {
    const { cache, context } = setup();
    const registered = euiClass(context, selected);
    const pieces: unknown[] = [
      row,
      selected,
      registered,
      'color: red;',
      undefined,
      false,
      { padding: 4 },
      { '&:hover': { color: 'red' } },
      [row, { gap: 2 }],
      [[selected], undefined]
    ];

    for (const a of pieces) {
      for (const b of pieces) {
        for (const c of [undefined, row, { margin: 1 }]) {
          const styles = [a, b, c] as Parameters<typeof euiClass>[1][];
          const memoized = euiClass(context, ...styles);

          assert.strictEqual(
            euiClass(context, ...styles),
            memoized,
            'the same class the second time'
          );
          assert.strictEqual(cache.css(styles), memoized);
        }
      }
    }
  });
});
