// Regression tests for the modifier / popover leak fixes
// (internal/memory-leak-audit/README.md rows 1, 4, 11, 12, 13, 14 and LH-06).
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { run } from '@ember/runloop';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import { click, render, settled, triggerEvent, waitUntil } from '@ember/test-helpers';

import EuiButton from '#src/components/eui-button.gts';
import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiOverlayMask from '#src/components/eui-overlay-mask.gts';
import EuiPopover from '#src/components/eui-popover.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';
import outsideClickDetector from '#src/modifiers/outside-click-detector.ts';

const WIDE = htmlSafe('transition: width 2s linear; width: 200px');
const NARROW = htmlSafe('transition: width 2s linear; width: 100px');

/** Counts `addEventListener` calls on `target` per event type. */
function countAdds(target: EventTarget) {
  const add = target.addEventListener.bind(target);
  const remove = target.removeEventListener.bind(target);
  const adds = new Map<string, number>();
  const live = new Map<string, Set<unknown>>();

  (target as { addEventListener: unknown }).addEventListener = (type: string, fn: EventListener, options?: unknown) => {
    adds.set(type, (adds.get(type) ?? 0) + 1);
    (live.get(type) ?? live.set(type, new Set()).get(type)!).add(fn);
    return add(type, fn, options as boolean);
  };
  (target as { removeEventListener: unknown }).removeEventListener = (type: string, fn: EventListener, options?: unknown) => {
    live.get(type)?.delete(fn);
    return remove(type, fn, options as boolean);
  };

  return {
    adds: (type: string) => adds.get(type) ?? 0,
    live: (type: string) => live.get(type)?.size ?? 0,
    restore() {
      (target as { addEventListener: unknown }).addEventListener = add;
      (target as { removeEventListener: unknown }).removeEventListener = remove;
    }
  };
}

module('Integration | Leaks | modifiers and popover teardown', function (hooks) {
  setupRenderingTest(hooks);

  // README #14 (LI-5)
  test('outsideClickDetector: arg updates neither set up again nor drop the latest args', async function (assert) {
    const doc = countAdds(document);
    const state = new (class {
      @tracked disabled = false;
      @tracked show = true;
      calls: string[] = [];
      @tracked onOutside = () => this.calls.push('first');
    })();

    try {
      await render(
        <template>
          {{#if state.show}}
            <div class="inside" {{outsideClickDetector onOutsideClick=state.onOutside isDisabled=state.disabled}}>x</div>
          {{/if}}
          <div class="outside">y</div>
        </template>
      );
      for (let i = 0; i < 10; i++) {
        state.disabled = !state.disabled;
        await settled();
      }
      assert.strictEqual(doc.adds('mouseup'), 1, 'document listeners added once');

      state.onOutside = () => state.calls.push('latest');
      await settled();
      await triggerEvent('.outside', 'mouseup');
      assert.deepEqual(state.calls, ['latest'], 'the latest onOutsideClick runs');

      state.disabled = true;
      await settled();
      await triggerEvent('.outside', 'mouseup');
      assert.deepEqual(state.calls, ['latest'], 'the latest isDisabled is honoured');

      state.show = false;
      await settled();
      assert.strictEqual(doc.live('mouseup'), 0, 'removed on teardown');
      assert.strictEqual(doc.live('touchend'), 0, 'removed on teardown');
    } finally {
      doc.restore();
    }
  });

  // README #4 (F-POP-1): consumers that hold the panel see it go away
  test('popover: panelRef(null) is sent on close and on unmount while open', async function (assert) {
    const state = new (class {
      @tracked isOpen = false;
      @tracked show = true;
      open = () => (this.isOpen = true);
      close = () => (this.isOpen = false);
    })();
    const refs: Array<HTMLElement | null> = [];
    const panelRef = (el: HTMLElement | null) => refs.push(el);

    await render(
      <template>
        {{#if state.show}}
          <EuiPopover @isOpen={{state.isOpen}} @closePopover={{state.close}} @panelRef={{panelRef}}>
            <:button><EuiButton class="trigger" {{on "click" state.open}}>Open</EuiButton></:button>
            <:content><p>content</p></:content>
          </EuiPopover>
        {{/if}}
      </template>
    );
    await click('.trigger');
    await waitUntil(() => document.querySelector('.euiPopover__panel'));
    state.close();
    await waitUntil(() => !document.querySelector('.euiPopover__panel'));
    await settled();
    assert.deepEqual(refs.map((r) => (r ? 'panel' : null)), ['panel', null], 'closed');

    await click('.trigger');
    await waitUntil(() => document.querySelector('.euiPopover__panel'));
    state.show = false;
    await settled();
    assert.deepEqual(refs.map((r) => (r ? 'panel' : null)), ['panel', null, 'panel', null], 'unmounted while open');
  });

  // README #13 (LH-04)
  test('popover: the reposition frame loop stops when the popover is destroyed', async function (assert) {
    const state = new (class {
      @tracked show = true;
      @tracked wide = false;
      close = () => {};
    })();
    const raf = window.requestAnimationFrame;
    let loopFrames = 0;

    window.requestAnimationFrame = (cb: FrameRequestCallback) => {
      if (cb.name === 'onFrame') loopFrames++;
      return raf(cb);
    };

    try {
      await render(
        <template>
          {{#if state.show}}
            <EuiPopover @isOpen={{true}} @closePopover={{state.close}}>
              <:button><EuiButton>Open</EuiButton></:button>
              <:content>
                <div class="grow" style={{if state.wide WIDE NARROW}}>content</div>
              </:content>
            </EuiPopover>
          {{/if}}
        </template>
      );
      await waitUntil(() => document.querySelector('.euiPopover__panel'));
      loopFrames = 0;
      state.wide = true;
      await settled();
      await waitUntil(() => loopFrames > 2, { timeout: 1000 });
      state.show = false;
      await settled();
      await new Promise((resolve) => raf(() => raf(() => resolve(null))));
      const afterDestroy = loopFrames;
      await new Promise((resolve) => setTimeout(resolve, 150));
      assert.strictEqual(loopFrames, afterDestroy, 'no frames requested after destroy');
    } finally {
      window.requestAnimationFrame = raf;
    }
  });

  // README #12 (F-MISC-4)
  test('overlay mask: maskRef(null) is sent on teardown', async function (assert) {
    const state = new (class {
      @tracked show = true;
    })();
    const refs: Array<HTMLDivElement | null> = [];
    const maskRef = (el: HTMLDivElement | null) => refs.push(el);

    await render(<template>{{#if state.show}}<EuiOverlayMask @maskRef={{maskRef}} />{{/if}}</template>);
    assert.ok(refs[0] instanceof HTMLDivElement, 'called with the mask');
    state.show = false;
    await settled();
    assert.deepEqual(refs.slice(1), [null], 'then with null');
  });

  // README #11 (F-TIP-1)
  test('tooltip: destroyed in the same tick as @attachTo is set, it adds no listeners to it', async function (assert) {
    const target = document.createElement('button');
    document.body.append(target);
    const listeners = countAdds(target);
    const state = new (class {
      @tracked show = false;
    })();

    try {
      await render(
        <template>
          {{#if state.show}}<EuiToolTip @content="tip" @attachTo={{target}} />{{/if}}
        </template>
      );
      run(() => (state.show = true));
      assert.ok(document.querySelector('.euiToolTipAnchor, span'), 'rendered');
      run(() => (state.show = false));
      await settled();
      await new Promise((resolve) => setTimeout(resolve, 20));
      assert.strictEqual(listeners.live('mousemove'), 0, 'mousemove');
      assert.strictEqual(listeners.live('focusin'), 0, 'focusin');
      assert.strictEqual(listeners.live('focusout'), 0, 'focusout');
    } finally {
      listeners.restore();
      target.remove();
    }
  });

  // LH-06
  test('combo box: unmounting while the list is open does not throw', async function (assert) {
    const state = new (class {
      @tracked show = true;
    })();
    const options = Array.from({ length: 20 }, (_, i) => `Option ${i}`);
    const none: string[] = [];
    const noop = () => {};

    await render(
      <template>
        {{#if state.show}}
          <EuiComboBox @options={{options}} @selectedOptions={{none}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox>
        {{/if}}
      </template>
    );
    await click('.euiComboBox__inputWrap');
    await waitUntil(() => document.querySelector('.euiComboBoxOptionsList'));
    state.show = false;
    await settled();
    assert.strictEqual(document.querySelector('.euiComboBoxOptionsList'), null, 'list removed');
  });
});
