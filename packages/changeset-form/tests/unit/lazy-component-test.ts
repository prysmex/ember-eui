import { module, test } from 'qunit';
import { settled } from '@ember/test-helpers';

import { LazyComponent } from '#src/-private/lazy-component.ts';

const Control = { name: 'Control' };

module('Unit | -private | lazy-component', function () {
  test('imports on the first read, once, and settled() waits for it', async function (assert) {
    let imports = 0;
    const lazy = new LazyComponent(() => {
      imports++;
      return Promise.resolve({ default: Control });
    });

    assert.strictEqual(imports, 0, 'nothing is imported up front');
    assert.strictEqual(lazy.component, undefined, 'undefined while importing');
    assert.strictEqual(lazy.component, undefined);
    assert.strictEqual(imports, 1, 'one import however many reads');

    await settled();

    assert.strictEqual(lazy.component, Control);
    assert.strictEqual(imports, 1);
  });

  test('load() imports ahead of a render', async function (assert) {
    const lazy = new LazyComponent(() => Promise.resolve({ default: Control }));

    await lazy.load();

    assert.strictEqual(lazy.component, Control);
  });

  test('a failed import is tried again on the next read', async function (assert) {
    let imports = 0;
    const lazy = new LazyComponent(() => {
      imports++;
      return imports === 1
        ? Promise.reject(new Error('offline'))
        : Promise.resolve({ default: Control });
    });

    await assert.rejects(lazy.load(), /offline/);
    assert.strictEqual(lazy.component, undefined);

    await settled();

    assert.strictEqual(lazy.component, Control);
    assert.strictEqual(imports, 2);
  });
});
