// Memory-leak audit (leak-components): teardown checks for component families.
// Tests marked `skip` document a confirmed/suspected finding in
// internal/memory-leak-audit/leak-components.md and fail today.
import { module, test, skip } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';
import { clearRender, click, render, settled, triggerEvent, waitUntil } from '@ember/test-helpers';

import EuiAspectRatio from '#src/components/eui-aspect-ratio.gts';
import EuiAvatar from '#src/components/eui-avatar.gts';
import EuiButton from '#src/components/eui-button.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiGlobalToastList from '#src/components/eui-global-toast-list.gts';
import EuiPopover from '#src/components/eui-popover.gts';
import EuiSaturation from '#src/components/eui-saturation.gts';
import EuiSuperDatePicker from '#src/components/eui-super-date-picker.gts';
import EuiTextColor from '#src/components/eui-text-color.gts';
import EuiToken from '#src/components/eui-token.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';

import type EuiToasterService from '#src/services/eui-toaster.ts';

type Target = Window | Document;

/** Counts listeners added to `target` and not yet removed, per event type. */
function trackListeners(target: Target) {
  const add = target.addEventListener.bind(target);
  const remove = target.removeEventListener.bind(target);
  const key = (type: string, fn: unknown, options: unknown) =>
    `${type}|${options === true || (options as { capture?: boolean } | undefined)?.capture ? 'c' : ''}`;
  const entries = new Map<string, Set<unknown>>();

  (target as { addEventListener: unknown }).addEventListener = (type: string, fn: EventListener, options?: unknown) => {
    const k = key(type, fn, options);
    (entries.get(k) ?? entries.set(k, new Set()).get(k)!).add(fn);
    return add(type, fn, options as boolean);
  };
  (target as { removeEventListener: unknown }).removeEventListener = (type: string, fn: EventListener, options?: unknown) => {
    entries.get(key(type, fn, options))?.delete(fn);
    return remove(type, fn, options as boolean);
  };

  return {
    count: (type: string, capture = false) => entries.get(`${type}|${capture ? 'c' : ''}`)?.size ?? 0,
    restore() {
      (target as { addEventListener: unknown }).addEventListener = add;
      (target as { removeEventListener: unknown }).removeEventListener = remove;
    }
  };
}

class PopoverState {
  @tracked isOpen = false;
  open = () => (this.isOpen = true);
  close = () => (this.isOpen = false);
}

module('Integration | Leaks | components teardown', function (hooks) {
  setupRenderingTest(hooks);

  test('flyout: window listeners are back to baseline after unmount', async function (assert) {
    const win = trackListeners(window);
    class S {
      @tracked open = true;
    }
    const state = new S();
    const noop = () => {};

    try {
      await render(<template>{{#if state.open}}<EuiFlyout @onClose={{noop}}>x</EuiFlyout>{{/if}}</template>);
      state.open = false;
      await settled();
      assert.strictEqual(win.count('keydown'), 0, 'keydown');
      assert.strictEqual(win.count('resize'), 0, 'resize');
      assert.strictEqual(win.count('scroll'), 0, 'scroll');
    } finally {
      win.restore();
    }
  });

  test('super date picker: auto refresh stops after teardown', async function (assert) {
    let refreshes = 0;
    const onRefresh = () => {
      refreshes++;
    };
    const noop = () => {};

    await render(
      <template>
        <EuiSuperDatePicker
          @onTimeChange={{noop}}
          @onRefresh={{onRefresh}}
          @isPaused={{false}}
          @refreshInterval={{30}}
        />
      </template>
    );
    await waitUntil(() => refreshes >= 2, { timeout: 2000 });
    await clearRender();
    const after = refreshes;
    await new Promise((resolve) => setTimeout(resolve, 200));
    assert.strictEqual(refreshes, after, 'no refresh after teardown');
  });

  test('global toast list: pending dismissal timers do not fire after teardown', async function (assert) {
    const toaster = this.owner.lookup('service:eui-toaster') as EuiToasterService;
    const dismissed: unknown[] = [];
    const dismiss = (toast: unknown) => dismissed.push(toast);

    await render(<template><EuiGlobalToastList @toastLifeTimeMs={{80}} @dismissToast={{dismiss}} /></template>);
    toaster.show({ id: 'a', title: 'A' });
    await waitUntil(() => document.querySelector('.euiToast'));
    await clearRender();
    await new Promise((resolve) => setTimeout(resolve, 500));
    assert.deepEqual(dismissed, [], 'no dismissal callback after teardown');
  });

  test('tooltip: unmounting while visible leaves no window listeners', async function (assert) {
    const win = trackListeners(window);
    class S {
      @tracked show = true;
    }
    const state = new S();

    try {
      await render(
        <template>
          {{#if state.show}}
            <EuiToolTip @content="tip" @repositionOnScroll={{true}}><button type="button" class="a">a</button></EuiToolTip>
          {{/if}}
        </template>
      );
      await triggerEvent('.euiToolTipAnchor', 'mouseover');
      await waitUntil(() => document.querySelector('.euiToolTip'));
      state.show = false;
      await settled();
      assert.strictEqual(document.querySelector('.euiToolTip'), null, 'portal removed');
      assert.strictEqual(win.count('resize'), 0, 'resize');
      assert.strictEqual(win.count('scroll', true), 0, 'scroll (capture)');
    } finally {
      win.restore();
    }
  });

  test('popover: unmounting while open leaves no window listeners or portal', async function (assert) {
    const win = trackListeners(window);
    const state = new PopoverState();
    class S {
      @tracked show = true;
    }
    const mounted = new S();

    try {
      await render(
        <template>
          {{#if mounted.show}}
            <EuiPopover @isOpen={{state.isOpen}} @closePopover={{state.close}} @repositionOnScroll={{true}}>
              <:button><EuiButton class="trigger" {{on "click" state.open}}>Open</EuiButton></:button>
              <:content><p>content</p></:content>
            </EuiPopover>
          {{/if}}
        </template>
      );
      await click('.trigger');
      await waitUntil(() => document.querySelector('.euiPopover__panel'));
      mounted.show = false;
      await settled();
      assert.strictEqual(document.querySelector('.euiPopover__panel'), null, 'panel removed');
      assert.strictEqual(win.count('resize'), 0, 'resize');
      assert.strictEqual(win.count('scroll', true), 0, 'scroll (capture)');
    } finally {
      win.restore();
    }
  });

  // F-POP-1: registerPanel(null) is never called (the panel is wired with
  // `didInsert` only), so a closed popover keeps a stale, detached panel and
  // never reports `panelRef(null)`.
  skip('popover: closing it reports panelRef(null)', async function (assert) {
    const state = new PopoverState();
    const panelRefs: Array<HTMLElement | null> = [];
    const panelRef = (el: HTMLElement | null) => panelRefs.push(el);

    await render(
      <template>
        <EuiPopover @isOpen={{state.isOpen}} @closePopover={{state.close}} @panelRef={{panelRef}}>
          <:button><EuiButton class="trigger" {{on "click" state.open}}>Open</EuiButton></:button>
          <:content><p>content</p></:content>
        </EuiPopover>
      </template>
    );
    await click('.trigger');
    await waitUntil(() => document.querySelector('.euiPopover__panel'));
    state.close();
    await waitUntil(() => !document.querySelector('.euiPopover__panel'));
    assert.strictEqual(panelRefs[panelRefs.length - 1], null, 'panelRef(null) after the panel is removed');
  });

  // F-POP-1 (same cause): the window resize listener stays while closed.
  skip('popover: closing it removes the window resize listener', async function (assert) {
    const win = trackListeners(window);
    const state = new PopoverState();

    try {
      await render(
        <template>
          <EuiPopover @isOpen={{state.isOpen}} @closePopover={{state.close}}>
            <:button><EuiButton class="trigger" {{on "click" state.open}}>Open</EuiButton></:button>
            <:content><p>content</p></:content>
          </EuiPopover>
        </template>
      );
      const baseline = win.count('resize');
      await click('.trigger');
      await waitUntil(() => document.querySelector('.euiPopover__panel'));
      assert.strictEqual(win.count('resize'), baseline + 1, 'listener added while open');
      state.close();
      await waitUntil(() => !document.querySelector('.euiPopover__panel'));
      assert.strictEqual(win.count('resize'), baseline, 'listener removed once closed');
    } finally {
      win.restore();
    }
  });

  // F-SAT-1: document mousemove/mouseup listeners added on mousedown are only
  // removed on mouseup; unmounting mid-drag leaves them (and the component).
  skip('saturation: unmounting mid-drag removes the document drag listeners', async function (assert) {
    const doc = trackListeners(document);
    const onChange = () => {};

    try {
      await render(<template><div style="width: 100px; height: 100px"><EuiSaturation @onChange={{onChange}} /></div></template>);
      await triggerEvent('.euiSaturation', 'mousedown', { clientX: 10, clientY: 10 });
      assert.strictEqual(doc.count('mousemove'), 1, 'drag started');
      await clearRender();
      assert.strictEqual(doc.count('mousemove'), 0, 'mousemove listener removed on teardown');
      assert.strictEqual(doc.count('mouseup'), 0, 'mouseup listener removed on teardown');
    } finally {
      doc.restore();
    }
  });

  // F-EMO-1: the emotion cache keeps one rule per distinct style object for
  // the root provider's lifetime, so data-driven styles (avatar image URL,
  // custom colors) grow it with every distinct value ever rendered.
  const ruleCount = () =>
    [...document.querySelectorAll<HTMLStyleElement>('style[data-emotion]')].reduce(
      (total, style) => total + (style.sheet?.cssRules.length ?? 0),
      0
    );

  // Per-instance values go inline like upstream's `style`, so new values add
  // no style rules (F-EMO-1).
  test('avatar: per-instance image URLs and colors add no style rules', async function (assert) {
    class S {
      @tracked urls: string[] = ['/img/warmup.png'];
      @tracked colors: string[] = ['#000001'];
    }
    const state = new S();
    await render(
      <template>
        {{#each state.urls as |url|}}<EuiAvatar @name="A" @imageUrl={{url}} />{{/each}}
        {{#each state.colors as |color|}}<EuiAvatar @name="B" @color={{color}} />{{/each}}
      </template>
    );
    const before = ruleCount();
    state.urls = Array.from({ length: 30 }, (_, i) => `/img/${i}.png`);
    state.colors = Array.from({ length: 30 }, (_, i) => `#${(0x100000 + i * 997).toString(16)}`);
    await settled();
    assert.strictEqual(ruleCount(), before, 'no rule per URL or color');
    const avatars = [...document.querySelectorAll<HTMLElement>('.euiAvatar')];
    assert.true(avatars[0]!.style.backgroundImage.includes('/img/0.png'), 'the image is applied inline');
    assert.strictEqual(avatars[30]!.style.backgroundColor, 'rgb(16, 0, 0)', 'the color is applied inline');
  });

  test('text color, token and aspect ratio: per-instance values add no style rules', async function (assert) {
    class S {
      @tracked values: number[] = [];
    }
    const state = new S();
    const hex = (i: number) => `#${(0x100000 + i * 997).toString(16)}`;
    await render(
      <template>
        {{#each state.values as |i|}}
          <EuiTextColor @color={{hex i}}>x</EuiTextColor>
          <EuiToken @iconType="tokenString" @color={{hex i}} />
          <EuiAspectRatio @width={{i}} @height={{9}} @maxWidth={{i}}><div /></EuiAspectRatio>
        {{/each}}
      </template>
    );
    // the first set inserts the components' static classes (and icons)
    state.values = Array.from({ length: 30 }, (_, i) => i + 1);
    await settled();
    await waitUntil(() => document.querySelector('.euiToken svg'));
    const before = ruleCount();
    state.values = Array.from({ length: 30 }, (_, i) => i + 100);
    await settled();
    assert.strictEqual(ruleCount(), before, 'no rule per value');
    assert.strictEqual(document.querySelector<HTMLElement>('.euiTextColor')!.style.color, 'rgb(17, 133, 116)', 'text color inline');
    assert.strictEqual(document.querySelector<HTMLElement>('.euiToken')!.style.backgroundColor, 'rgb(17, 133, 116)', 'token color inline');
    assert.strictEqual(document.querySelector<HTMLElement>('.euiAspectRatio')!.style.aspectRatio, '100 / 9', 'ratio inline');
  });
});
