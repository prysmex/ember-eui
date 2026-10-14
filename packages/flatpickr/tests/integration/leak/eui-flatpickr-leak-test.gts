/*
 * Memory-leak audit (leak-infra): flatpickr instances must be destroyed
 * with the component, so their calendar (appended to <body>) and their
 * window/document listeners go too. See
 * internal/memory-leak-audit/leak-infra.md.
 */
import { module, test, todo } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';
import { run } from '@ember/runloop';
import { tracked } from '@glimmer/tracking';

import EuiFlatpickr from '#src/components/eui-flatpickr.gjs';

const N = 10;

class State {
  @tracked show = false;
  @tracked date: Date[] | Date | null = new Date(2024, 4, 17);
  onChange = (dates: Date[]) => (this.date = dates);
}

/** Listeners on window/document/body: added minus removed. */
function trackListeners() {
  const live = new Set<string>();
  const ids = new WeakMap<object, number>();
  let next = 1;
  const id = (o: object) => ids.get(o) ?? (ids.set(o, next), next++);
  const targets: EventTarget[] = [window, document, document.body];
  const proto = EventTarget.prototype;
  const add = proto.addEventListener;
  const remove = proto.removeEventListener;
  const key = (t: EventTarget, type: string, l: object, o?: boolean | EventListenerOptions) =>
    `${id(t)}|${type}|${id(l)}|${typeof o === 'boolean' ? o : Boolean(o?.capture)}`;
  proto.addEventListener = function (this: EventTarget, type: string, l: any, o?: any) {
    if (l && targets.includes(this)) live.add(key(this, type, l, o));
    return add.call(this, type, l, o);
  };
  proto.removeEventListener = function (this: EventTarget, type: string, l: any, o?: any) {
    if (l && targets.includes(this)) live.delete(key(this, type, l, o));
    return remove.call(this, type, l, o);
  };
  return {
    get size() {
      return live.size;
    },
    restore() {
      proto.addEventListener = add;
      proto.removeEventListener = remove;
    }
  };
}

module('Integration | leak-infra | eui-flatpickr', function (hooks) {
  setupRenderingTest(hooks);

  let listeners: ReturnType<typeof trackListeners>;
  hooks.beforeEach(() => (listeners = trackListeners()));
  hooks.afterEach(() => listeners.restore());

  test('mount/unmount N times destroys every flatpickr instance', async function (assert) {
    const state = new State();
    await render(
      <template>
        {{#if state.show}}
          <EuiFlatpickr @date={{state.date}} @onChange={{state.onChange}} @dateFormat="Y-m-d" />
        {{/if}}
      </template>
    );
    for (let i = 0; i < N; i++) {
      state.show = true;
      await settled();
      state.show = false;
      await settled();
    }
    assert.dom('.flatpickr-calendar', document.body).doesNotExist('no calendar left in <body>');
    assert.strictEqual(listeners.size, 0, 'no window/document listener left');
  });

  todo('unmounted while a string @locale loads, the picker is never created (LI-6)', async function (assert) {
    const state = new State();
    await render(
      <template>
        {{#if state.show}}
          <EuiFlatpickr @date={{state.date}} @onChange={{state.onChange}} @dateFormat="Y-m-d" @locale="es" />
        {{/if}}
      </template>
    );
    for (let i = 0; i < N; i++) {
      // render (setup awaits the locale chunk), then unmount before it resolves
      run(() => (state.show = true));
      run(() => (state.show = false));
      await settled();
    }
    const calendars = document.querySelectorAll('.flatpickr-calendar').length;
    assert.deepEqual(
      { calendars, listeners: listeners.size },
      { calendars: 0, listeners: 0 },
      `orphaned calendars in <body>: ${calendars}, window/document listeners: ${listeners.size}`
    );
    document.querySelectorAll('.flatpickr-calendar').forEach((el) => el.remove());
  });
});
