// Memory-leak audit fixes: listeners and timers are released on teardown.
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { clearRender, render, settled, triggerEvent, waitUntil } from '@ember/test-helpers';

import EuiBasicTable from '#src/components/eui-basic-table.gts';
import EuiColorStops from '#src/components/eui-color-stops.gts';
import EuiGlobalToastList from '#src/components/eui-global-toast-list.gts';
import EuiRange from '#src/components/eui-range.gts';

type Counter = { copy: number; mousemove: number; restore(): void };

/** Document `copy`/`mousemove` listeners added and not removed. */
function trackDocument(): Counter {
  const add = document.addEventListener.bind(document);
  const remove = document.removeEventListener.bind(document);
  const live = new Map<string, Set<unknown>>();
  const set = (t: string) => live.get(t) ?? live.set(t, new Set()).get(t)!;
  (document as any).addEventListener = (t: string, fn: any, o?: any) => (set(t).add(fn), add(t, fn, o));
  (document as any).removeEventListener = (t: string, fn: any, o?: any) => (set(t).delete(fn), remove(t, fn, o));
  return {
    get copy() {
      return set('copy').size;
    },
    get mousemove() {
      return set('mousemove').size;
    },
    restore() {
      (document as any).addEventListener = add;
      (document as any).removeEventListener = remove;
    }
  };
}

module('Integration | Leaks | guards', function (hooks) {
  setupRenderingTest(hooks);

  test('basic table: the shared copy listener is ref-counted and removed with the last table', async function (assert) {
    const doc = trackDocument();
    class S {
      @tracked a = true;
      @tracked b = true;
    }
    const s = new S();
    const items = [{ id: 1, name: 'A' }];
    const columns = [{ field: 'name', name: 'Name' }];
    try {
      await render(
        <template>
          {{#if s.a}}<EuiBasicTable @items={{items}} @columns={{columns}} />{{/if}}
          {{#if s.b}}<EuiBasicTable @items={{items}} @columns={{columns}} />{{/if}}
        </template>
      );
      assert.strictEqual(doc.copy, 1, 'one listener for two tables');
      s.a = false;
      await settled();
      assert.strictEqual(doc.copy, 1, 'still attached while a table is mounted');
      s.b = false;
      await settled();
      assert.strictEqual(doc.copy, 0, 'removed with the last table');
    } finally {
      doc.restore();
    }
  });

  test('color stops thumb: unmounting mid-drag removes the document drag listeners', async function (assert) {
    const doc = trackDocument();
    const stops = [{ stop: 0, color: '#54B399' }, { stop: 50, color: '#D36086' }];
    const noop = () => {};
    try {
      await render(<template><EuiColorStops @label="Stops" @colorStops={{stops}} @onChange={{noop}} /></template>);
      await triggerEvent('[data-test-subj="euiColorStopThumb"]', 'mousedown', { clientX: 5, clientY: 5 });
      assert.strictEqual(doc.mousemove, 1, 'drag started');
      await clearRender();
      assert.strictEqual(doc.mousemove, 0, 'mousemove listener removed on teardown');
    } finally {
      doc.restore();
    }
  });

  test('global toast list: timers of toasts removed from @toasts are cleared', async function (assert) {
    class S {
      @tracked toasts = [{ id: 'a', title: 'A' }];
    }
    const s = new S();
    const dismissed: unknown[] = [];
    const dismiss = (t: unknown) => dismissed.push(t);
    await render(
      <template><EuiGlobalToastList @toasts={{s.toasts}} @toastLifeTimeMs={{700}} @dismissToast={{dismiss}} /></template>
    );
    await waitUntil(() => document.querySelector('.euiToast'));
    s.toasts = [];
    await settled();
    await new Promise((resolve) => setTimeout(resolve, 1200));
    assert.deepEqual(dismissed, [], 'no dismissal for a toast the app removed');
  });

  test('range: a pending blur timer is cancelled on teardown', async function (assert) {
    let blurred = 0;
    const onBlur = () => blurred++;
    const noop = () => {};
    await render(<template><EuiRange @value={{40}} @onChange={{noop}} @onBlur={{onBlur}} @showInput="inputWithPopover" /></template>);
    // dispatch directly: `triggerEvent` would wait for the pending timer
    document.querySelector('input.euiFieldNumber, input[type=number]')!.dispatchEvent(new FocusEvent('blur'));
    await clearRender();
    await new Promise((resolve) => setTimeout(resolve, 350));
    assert.strictEqual(blurred, 0, 'onBlur not called after teardown');
  });
});
