/*
 * Memory-leak audit (leak-infra): infrastructure outside the components —
 * modifiers, services, the Emotion cache, the focus-trap registry and the
 * flyout manager. Each test mounts and unmounts N times and checks that
 * long-lived roots return to their baseline.
 *
 * `todo` tests document a confirmed leak: they pass while the assertion
 * fails, and start failing (to be promoted to `test`) once it is fixed.
 * See internal/memory-leak-audit/leak-infra.md.
 */
import { module, test, todo } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled, waitUntil } from '@ember/test-helpers';
import { hash } from '@ember/helper';
import { htmlSafe } from '@ember/template';

import EuiButton from '#src/components/eui-button.gts';
import EuiCallOut from '#src/components/eui-call-out.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiFlyoutBody from '#src/components/eui-flyout-body.gts';
import EuiFieldText from '#src/components/eui-field-text.gts';
import EuiFormRow from '#src/components/eui-form-row.gts';
import EuiFocusTrap from '#src/components/eui-focus-trap.gts';
import EuiModal from '#src/components/eui-modal.gts';
import EuiPanel from '#src/components/eui-panel.gts';
import EuiText from '#src/components/eui-text.gts';
import containerQuery from '#src/modifiers/container-query.ts';
import outsideClickDetector from '#src/modifiers/outside-click-detector.ts';
import resizeObserver from '#src/modifiers/resize-observer.ts';
import { euiFlyoutManager } from '#src/-private/eui-flyout-context.ts';

import {
  LeakHarness,
  emotionCacheSize
} from '../helpers/leak-infra-harness.ts';

import type EuiEmotionService from '#src/services/eui-emotion.ts';
import type EuiFlyoutManagerService from '#src/services/eui-flyout-manager.ts';

const N = 10;

class State {
  @tracked show = false;
  @tracked value = 0;
  @tracked disabled = false;
  @tracked child = false;
  @tracked primary = '#0B64DD';
  onResize = () => {};
  get widthStyle() {
    return htmlSafe(`width: ${this.value}px`);
  }
  @tracked callback: (dimensions: { width: number; height: number }) => void =
    () => {};
}

/** Lets animations, observers and next-frame callbacks finish. */
async function idle() {
  await settled();
  await waitUntil(
    () =>
      document
        .getAnimations()
        .every((animation) => animation.playState !== 'running'),
    { timeout: 3000 }
  );
  await new Promise((resolve) =>
    requestAnimationFrame(() => setTimeout(resolve, 30))
  );
  await settled();
}

module('Integration | leak-infra', function (hooks) {
  setupRenderingTest(hooks);

  let harness: LeakHarness;

  hooks.beforeEach(function () {
    harness = new LeakHarness();
    harness.install();
  });

  hooks.afterEach(function () {
    harness.uninstall();
  });

  module('modifiers', function () {
    test('resizeObserver: mount/unmount N times disconnects every observer', async function (assert) {
      const state = new State();
      await render(
        <template>
          {{#if state.show}}
            <div {{resizeObserver onResize=state.onResize}}>x</div>
          {{/if}}
        </template>
      );
      for (let i = 0; i < N; i++) {
        state.show = true;
        await settled();
        state.show = false;
        await settled();
      }
      assert.strictEqual(harness.snapshot().resizeObservers, 0);
      assert.strictEqual(harness.createdResizeObservers, N);
    });

    todo('resizeObserver: a changed named arg replaces the observer instead of adding one (LI-1)', async function (assert) {
      const state = new State();
      state.show = true;
      const calls: number[] = [];
      await render(
        <template>
          {{#if state.show}}
            <div style={{state.widthStyle}} {{resizeObserver onResize=state.callback}}>x</div>
          {{/if}}
        </template>
      );
      // a new callback and a new size each time: setSize calls (and so
      // consumes) `onResize`, so the modifier re-runs on the next change
      for (let i = 1; i <= N; i++) {
        state.value = i * 10;
        state.callback = () => calls.push(i);
        await idle();
      }
      const whileMounted = harness.snapshot().resizeObservers;
      calls.length = 0;
      state.value = 500;
      await idle();
      const callsForOneResize = calls.length;
      state.show = false;
      await settled();
      const afterUnmount = harness.snapshot().resizeObservers;

      assert.deepEqual(
        { whileMounted, afterUnmount, created: harness.createdResizeObservers },
        { whileMounted: 1, afterUnmount: 0, created: 1 + N },
        `live observers while mounted: ${whileMounted}, after unmount: ${afterUnmount}, created: ${harness.createdResizeObservers}, onResize calls for one resize: ${callsForOneResize}`
      );
    });

    test('outsideClickDetector: arg updates and unmount leave no document listener', async function (assert) {
      const state = new State();
      await render(
        <template>
          {{#if state.show}}
            <div {{outsideClickDetector onOutsideClick=state.onResize isDisabled=state.disabled}}>x</div>
          {{/if}}
        </template>
      );
      for (let i = 0; i < N; i++) {
        state.show = true;
        await settled();
        state.disabled = !state.disabled;
        await settled();
        state.show = false;
        await settled();
      }
      assert.deepEqual(harness.listenerSummary(), []);
    });

    test('containerQuery: mount/unmount N times removes its adopted style sheets', async function (assert) {
      const state = new State();
      const baseline = document.adoptedStyleSheets.length;
      const noop = () => {};
      await render(
        <template>
          <div style="container-type: inline-size">
            {{#if state.show}}
              <div {{containerQuery "(width > 400px)" onChange=noop}}>x</div>
            {{/if}}
          </div>
        </template>
      );
      for (let i = 0; i < N; i++) {
        state.show = true;
        await settled();
        state.show = false;
        await settled();
      }
      assert.strictEqual(document.adoptedStyleSheets.length, baseline);
    });
    test('linkFormRowControl: rows with help text and errors disconnect their MutationObserver', async function (assert) {
      const state = new State();
      const errors = ['Required'];
      await render(
        <template>
          {{#if state.show}}
            <EuiFormRow @label="Name" @helpText="Help" @isInvalid={{true}} @error={{errors}}>
              <EuiFieldText />
            </EuiFormRow>
          {{/if}}
        </template>
      );
      for (let i = 0; i < N; i++) {
        state.show = true;
        await settled();
        state.show = false;
        await settled();
      }
      assert.strictEqual(harness.snapshot().mutationObservers, 0);
    });
  });

  module('emotion', function () {
    test('EuiEmotionProvider: mount/unmount N times removes media query listeners, global styles and CSS variables', async function (assert) {
      const state = new State();
      await render(
        <template>
          {{#if state.show}}
            <EuiEmotionProvider>x</EuiEmotionProvider>
          {{/if}}
        </template>
      );
      for (let i = 0; i < N; i++) {
        state.show = true;
        await settled();
        state.show = false;
        await settled();
      }
      assert.deepEqual(harness.listenerSummary(), [], 'no matchMedia listener left');
      assert.dom('style[data-emotion^="eui-global"]', document.head).doesNotExist();
      assert.dom('style[data-emotion^="eui-vars"]', document.head).doesNotExist();
    });

    test('the shared Emotion cache stops growing when the same components mount again', async function (assert) {
      const state = new State();
      const emotion = (this.owner.lookup('service:eui-emotion') as EuiEmotionService).context.cache;
      await render(
        <template>
          {{#if state.show}}
            <EuiEmotionProvider>
              <EuiButton>b</EuiButton>
              <EuiPanel>p</EuiPanel>
              <EuiCallOut @title="t">c</EuiCallOut>
              <EuiText>t</EuiText>
            </EuiEmotionProvider>
          {{/if}}
        </template>
      );
      // warm up: icons load lazily, their classes land on the second render
      for (let i = 0; i < 2; i++) {
        state.show = true;
        await idle();
        state.show = false;
        await idle();
      }
      const afterFirst = emotionCacheSize(emotion).inserted;
      const firstKeys = new Set(Object.keys(emotion.cache.inserted));
      const sizes: number[] = [];
      for (let i = 0; i < N; i++) {
        state.show = true;
        await settled();
        state.show = false;
        await settled();
        sizes.push(emotionCacheSize(emotion).inserted);
      }
      const added = Object.keys(emotion.cache.inserted).filter((k) => !firstKeys.has(k));
      assert.strictEqual(emotionCacheSize(emotion).inserted, afterFirst, `bounded at ${afterFirst} entries (per cycle: ${sizes.join(',')}; added: ${added.map((k) => `${k}=${String(emotion.cache.registered[`${emotion.cache.key}-${k}`] ?? emotion.cache.inserted[k]).slice(0, 200)}`).join(' | ')})`);
    });

    todo('a dynamic @css value adds one permanent cache entry per distinct value (LI-2)', async function (assert) {
      const state = new State();
      state.show = true;
      const emotion = (this.owner.lookup('service:eui-emotion') as EuiEmotionService).context.cache;
      await render(
        <template>
          {{#if state.show}}
            <EuiText @css={{hash width=state.value}}>t</EuiText>
          {{/if}}
        </template>
      );
      const before = emotionCacheSize(emotion).inserted;
      const rulesBefore = document.head.querySelectorAll('style[data-emotion]').length;
      for (let i = 1; i <= N * 5; i++) {
        state.value = i;
        await settled();
      }
      state.show = false;
      await settled();
      const growth = emotionCacheSize(emotion).inserted - before;
      const tags = document.head.querySelectorAll('style[data-emotion]').length - rulesBefore;
      assert.ok(growth < N, `cache growth after ${N * 5} distinct @css values and unmount: ${growth} entries, ${tags} <style> tags`);
    });

    todo('changing provider theme overrides adds a full set of component classes per distinct theme (LI-3)', async function (assert) {
      const state = new State();
      state.show = true;
      const emotion = (this.owner.lookup('service:eui-emotion') as EuiEmotionService).context.cache;
      await render(
        <template>
          {{#if state.show}}
            <EuiEmotionProvider @borealisOverrides={{hash colors=(hash LIGHT=(hash textParagraph=state.primary backgroundBasePlain=state.primary))}}>
              <EuiButton>b</EuiButton>
              <EuiPanel>p</EuiPanel>
              <EuiCallOut @title="t">c</EuiCallOut>
            </EuiEmotionProvider>
          {{/if}}
        </template>
      );
      const before = emotionCacheSize(emotion).inserted;
      for (let i = 1; i <= N; i++) {
        state.primary = `#0B64${String(i).padStart(2, '0')}`;
        await settled();
      }
      state.show = false;
      await settled();
      const growth = emotionCacheSize(emotion).inserted - before;
      assert.ok(growth < N, `cache growth after ${N} distinct themes and unmount: ${growth} entries`);
    });
  });

  module('focus traps', function () {
    test('EuiModal: open/close N times releases document listeners, scroll lock, isolation and body classes', async function (assert) {
      const state = new State();
      const bodyClass = document.body.className;
      const onClose = () => (state.show = false);
      await render(
        <template>
          <div id="outside">outside</div>
          {{#if state.show}}
            <EuiModal @onClose={{onClose}}><p>Hello</p></EuiModal>
          {{/if}}
        </template>
      );
      for (let i = 0; i < N; i++) {
        state.show = true;
        await idle();
        state.show = false;
        await idle();
      }
      assert.deepEqual(harness.listenerSummary(), [], 'no listener left on window/document/body');
      assert.strictEqual(harness.snapshot().resizeObservers, 0, 'no live ResizeObserver');
      assert.strictEqual(harness.snapshot().mutationObservers, 0, 'no live MutationObserver');
      assert.strictEqual(document.body.style.overflow, '', 'scroll lock released');
      assert.dom('#outside').doesNotHaveAttribute('aria-hidden');
      assert.strictEqual(document.body.className, bodyClass, 'body classes restored');
    });

    test('EuiFocusTrap: toggling @disabled and unmounting releases its trap', async function (assert) {
      const state = new State();
      await render(
        <template>
          {{#if state.show}}
            <EuiFocusTrap @disabled={{state.disabled}}><input /></EuiFocusTrap>
          {{/if}}
        </template>
      );
      for (let i = 0; i < N; i++) {
        state.show = true;
        await idle();
        state.disabled = !state.disabled;
        await idle();
        state.show = false;
        await idle();
      }
      assert.deepEqual(harness.listenerSummary(), []);
    });
  });

  module('flyout manager service', function () {
    test('managed flyouts opened, nested and unmounted while open leave the manager empty', async function (assert) {
      const state = new State();
      const manager: EuiFlyoutManagerService = euiFlyoutManager(this);
      const close = () => (state.show = false);
      const closeChild = () => (state.child = false);
      await render(
        <template>
          <EuiEmotionProvider>
            {{#if state.show}}
              <EuiFlyout @session="start" aria-label="Main" @onClose={{close}}>
                <EuiFlyoutBody>main</EuiFlyoutBody>
                {{#if state.child}}
                  <EuiFlyout @size="s" @flyoutMenuProps={{hash title="Child"}} @onClose={{closeChild}}>
                    <EuiFlyoutBody>child</EuiFlyoutBody>
                  </EuiFlyout>
                {{/if}}
              </EuiFlyout>
            {{/if}}
          </EuiEmotionProvider>
        </template>
      );
      const baseline = harness.listenerSummary();
      for (let i = 0; i < N; i++) {
        state.show = true;
        await idle();
        state.child = true;
        await idle();
        if (i % 2 === 0) manager.goBack();
        await idle();
        // unmount while open (child possibly still open)
        state.show = false;
        state.child = false;
        await idle();
      }
      const internals = manager as unknown as {
        pendingCloseMeta: Map<string, unknown>;
        containerUsers: Map<HTMLElement, number>;
        listeners: Set<unknown>;
        eventListeners: Set<unknown>;
        listeningToWindow: boolean;
      };
      assert.deepEqual(manager.state.sessions, [], 'no session');
      assert.deepEqual(manager.state.flyouts, [], 'no flyout');
      assert.deepEqual(manager.state.unmanagedFlyouts, [], 'no unmanaged flyout');
      assert.strictEqual(manager.historyItems.length, 0, 'no history item');
      assert.strictEqual(internals.pendingCloseMeta.size, 0, 'no pending close meta');
      assert.strictEqual(internals.containerUsers.size, 0, 'no container user');
      assert.false(internals.listeningToWindow, 'no window resize listener');
      assert.deepEqual(harness.listenerSummary(), baseline, 'only the provider\'s matchMedia listeners remain');
      assert.strictEqual(harness.snapshot().resizeObservers, 0, 'no live ResizeObserver');
    });

    test('closing the last session with Back resets the z-index counter (LI-4)', async function (assert) {
      const state = new State();
      const manager: EuiFlyoutManagerService = euiFlyoutManager(this);
      const emotion = (this.owner.lookup('service:eui-emotion') as EuiEmotionService).context.cache;
      const close = () => (state.show = false);
      await render(
        <template>
          <EuiEmotionProvider>
            {{#if state.show}}
              <EuiFlyout @session="start" aria-label="Main" @onClose={{close}}>
                <EuiFlyoutBody>main</EuiFlyoutBody>
              </EuiFlyout>
            {{/if}}
          </EuiEmotionProvider>
        </template>
      );
      state.show = true;
      await idle();
      manager.goBack();
      await idle();
      const before = emotionCacheSize(emotion).inserted;
      for (let i = 0; i < N; i++) {
        state.show = true;
        await idle();
        manager.goBack();
        await idle();
      }
      const growth = emotionCacheSize(emotion).inserted - before;
      assert.strictEqual(manager.state.sessions.length, 0, 'no session left');
      assert.strictEqual(manager.state.currentZIndex, 0, `z-index counter reset (got ${manager.state.currentZIndex}; Emotion cache grew by ${growth} entries over ${N} Back closes)`);
    });
  });
});
