/*
 * Memory-leak audit (leak-infra): the pikaday modifier destroys its
 * instance, so the calendar (appended to <body>) and document listeners go
 * with the component. See internal/memory-leak-audit/leak-infra.md.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiPikaday from '#src/components/eui-pikaday.gts';

const N = 10;

class State {
  @tracked show = false;
  value = new Date(2024, 4, 17);
}

module('Integration | leak-infra | eui-pikaday', function (hooks) {
  setupRenderingTest(hooks);

  test('mount, open and unmount N times leaves no calendar and no document listener', async function (assert) {
    const live = new Set<string>();
    const proto = EventTarget.prototype;
    const add = proto.addEventListener;
    const remove = proto.removeEventListener;
    const ids = new WeakMap<object, number>();
    let next = 1;
    const id = (o: object) => ids.get(o) ?? (ids.set(o, next), next++);
    const tracked = (t: EventTarget) => t === window || t === document || t === document.body;
    proto.addEventListener = function (this: EventTarget, type: string, l: any, o?: any) {
      if (l && tracked(this)) live.add(`${id(this)}|${type}|${id(l)}|${typeof o === 'boolean' ? o : Boolean(o?.capture)}`);
      return add.call(this, type, l, o);
    };
    proto.removeEventListener = function (this: EventTarget, type: string, l: any, o?: any) {
      if (l && tracked(this)) live.delete(`${id(this)}|${type}|${id(l)}|${typeof o === 'boolean' ? o : Boolean(o?.capture)}`);
      return remove.call(this, type, l, o);
    };

    try {
      const state = new State();
      await render(
        <template>
          {{#if state.show}}
            <EuiPikaday @value={{state.value}} />
          {{/if}}
        </template>
      );
      for (let i = 0; i < N; i++) {
        state.show = true;
        await settled();
        await click('input.euiFieldText');
        state.show = false;
        await settled();
      }
      assert.dom('.pika-single', document.body).doesNotExist('no calendar left in <body>');
      assert.strictEqual(live.size, 0, 'no window/document listener left');
    } finally {
      proto.addEventListener = add;
      proto.removeEventListener = remove;
    }
  });
});
