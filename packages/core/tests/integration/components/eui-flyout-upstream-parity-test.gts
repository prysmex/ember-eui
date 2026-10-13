/**
 * EuiFlyout Escape and z-index parity with upstream EUI 123.1.0
 * (`flyout.component.tsx` `shouldCloseOnEscape` / `managedFlyoutIndex`,
 * `use_flyout_z_index.ts`, `manager/reducer.ts`).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { hash } from '@ember/helper';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import { euiFlyoutManager } from '#src/-private/eui-flyout-context.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiFlyoutCloseMeta } from '#src/components/eui-flyout.gts';
import type EuiFlyoutManagerService from '#src/services/eui-flyout-manager.ts';

const light = resolveBorealisTheme('light').euiTheme;
const FLYOUT_LEVEL = Number(light.levels.flyout);

const $ = (selector: string): HTMLElement => {
  const element = document.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
};
const z = (selector: string) => Number(getComputedStyle($(selector)).zIndex);
const maskLevels = () =>
  [...document.querySelectorAll('.euiOverlayMask')]
    .map((mask) => Number(getComputedStyle(mask).zIndex))
    .sort((a, b) => a - b);

class Flyouts {
  @tracked a = false;
  @tracked b = false;
  @tracked child = false;
  @tracked inner = false;
  closes: Array<[string, string | undefined]> = [];

  closer = (name: 'a' | 'b' | 'child' | 'inner') => (_event?: Event, meta?: EuiFlyoutCloseMeta) => {
    this.closes.push([name, meta?.reason]);
    this[name] = false;
  };
  closeA = this.closer('a');
  closeB = this.closer('b');
  closeChild = this.closer('child');
  closeInner = this.closer('inner');
}

/** Waits for the flyouts to register and settle their stages. */
async function managed() {
  await settled();
  await waitUntil(
    () => document.getAnimations().every((animation) => animation.playState !== 'running'),
    { timeout: 3000 }
  );
  await new Promise((resolve) => requestAnimationFrame(() => setTimeout(resolve, 30)));
  await settled();
}

module('Integration | Component | EuiFlyout upstream parity', function (hooks) {
  setupRenderingTest(hooks);

  let manager: EuiFlyoutManagerService;

  hooks.beforeEach(function () {
    manager = euiFlyoutManager(this);
  });

  module('Escape', function () {
    test('closes the hidden main flyout of an earlier session too (upstream)', async function (assert) {
      const state = new Flyouts();
      state.a = true;

      await render(
        <template>
          <EuiEmotionProvider>
            {{#if state.a}}
              <EuiFlyout @session="start" @flyoutMenuProps={{hash title="A"}} @onClose={{state.closeA}} data-test-subj="a">a</EuiFlyout>
            {{/if}}
            {{#if state.b}}
              <EuiFlyout @session="start" @flyoutMenuProps={{hash title="B"}} @onClose={{state.closeB}} data-test-subj="b">b</EuiFlyout>
            {{/if}}
          </EuiEmotionProvider>
        </template>
      );
      await managed();
      state.b = true;
      await managed();
      assert.strictEqual(manager.state.sessions.length, 2);
      assert.strictEqual(
        manager.state.flyouts.find((f) => f.flyoutId === $('[data-test-subj="a"]').id)?.activityStage,
        'inactive',
        'A is backgrounded'
      );

      await triggerKeyEvent(document, 'keydown', 'Escape');
      await managed();
      assert.deepEqual(
        state.closes.map(([name, reason]) => `${name}:${reason}`).sort(),
        ['a:escape', 'b:escape'],
        'every main flyout without a child closes'
      );
      assert.strictEqual(manager.state.sessions.length, 0);
      assert.strictEqual(manager.state.flyouts.length, 0);
      assert.strictEqual(manager.state.currentZIndex, 0);
    });

    test('while the latest session has a child, only that child closes', async function (assert) {
      const state = new Flyouts();
      state.a = true;

      await render(
        <template>
          <EuiEmotionProvider>
            {{#if state.a}}
              <EuiFlyout @session="start" @flyoutMenuProps={{hash title="A"}} @onClose={{state.closeA}} data-test-subj="a">a</EuiFlyout>
            {{/if}}
            {{#if state.b}}
              <EuiFlyout @session="start" @size="m" @flyoutMenuProps={{hash title="B"}} @onClose={{state.closeB}} data-test-subj="b">
                {{#if state.child}}
                  <EuiFlyout @size="s" @flyoutMenuProps={{hash title="Child"}} @onClose={{state.closeChild}} data-test-subj="child">child</EuiFlyout>
                {{/if}}
              </EuiFlyout>
            {{/if}}
          </EuiEmotionProvider>
        </template>
      );
      await managed();
      state.b = true;
      await managed();
      state.child = true;
      await managed();
      assert.strictEqual(manager.state.sessions[1]!.childFlyoutId, $('[data-test-subj="child"]').id);

      await triggerKeyEvent(document, 'keydown', 'Escape');
      await managed();
      assert.deepEqual(state.closes, [['child', 'escape']], 'the hidden A and the main B stay');

      await triggerKeyEvent(document, 'keydown', 'Escape');
      await managed();
      assert.deepEqual(
        state.closes.slice(1).map(([name, reason]) => `${name}:${reason}`).sort(),
        ['a:escape', 'b:escape']
      );
    });

    test('standard flyouts over each other all close (upstream: always close)', async function (assert) {
      const state = new Flyouts();
      state.a = true;

      await render(
        <template>
          {{#if state.a}}
            <EuiFlyout @onClose={{state.closeA}} data-test-subj="a">a</EuiFlyout>
          {{/if}}
          {{#if state.b}}
            <EuiFlyout @onClose={{state.closeB}} data-test-subj="b">b</EuiFlyout>
          {{/if}}
        </template>
      );
      await managed();
      state.b = true;
      await managed();

      await triggerKeyEvent(document, 'keydown', 'Escape');
      assert.deepEqual(state.closes, [['a', 'escape'], ['b', 'escape']]);
    });

    test('a pushed flyout does not close', async function (assert) {
      const state = new Flyouts();
      state.a = true;

      await render(
        <template>
          {{#if state.a}}
            <EuiFlyout @type="push" @pushMinBreakpoint="xs" @onClose={{state.closeA}}>a</EuiFlyout>
          {{/if}}
        </template>
      );
      await managed();
      await triggerKeyEvent(document, 'keydown', 'Escape');
      assert.deepEqual(state.closes, []);
    });
  });

  module('z-index', function () {
    test('a standard flyout opened over another stacks 2 levels higher (addUnmanagedFlyout)', async function (assert) {
      const state = new Flyouts();
      state.a = true;

      await render(
        <template>
          {{#if state.a}}
            <EuiFlyout @onClose={{state.closeA}} data-test-subj="a">a</EuiFlyout>
          {{/if}}
          {{#if state.b}}
            <EuiFlyout @onClose={{state.closeB}} data-test-subj="b">b</EuiFlyout>
          {{/if}}
        </template>
      );
      await managed();
      assert.strictEqual(z('[data-test-subj="a"]'), FLYOUT_LEVEL);
      assert.deepEqual(maskLevels(), [FLYOUT_LEVEL - 2]);
      assert.strictEqual(manager.state.currentZIndex, 2);

      state.b = true;
      await managed();
      assert.strictEqual(z('[data-test-subj="a"]'), FLYOUT_LEVEL, 'the first keeps its level');
      assert.strictEqual(z('[data-test-subj="b"]'), FLYOUT_LEVEL + 2);
      assert.deepEqual(maskLevels(), [FLYOUT_LEVEL - 2, FLYOUT_LEVEL], 'masks 2 below each flyout');
      assert.strictEqual(manager.state.currentZIndex, 4);

      state.b = false;
      state.a = false;
      await managed();
      assert.strictEqual(manager.state.currentZIndex, 0, 'resets once all are closed');
    });

    test('standard flyouts rendered together share the base level', async function (assert) {
      const state = new Flyouts();
      state.a = true;
      state.b = true;

      await render(
        <template>
          {{#if state.a}}
            <EuiFlyout @onClose={{state.closeA}} data-test-subj="a">a</EuiFlyout>
          {{/if}}
          {{#if state.b}}
            <EuiFlyout @onClose={{state.closeB}} data-test-subj="b">b</EuiFlyout>
          {{/if}}
        </template>
      );
      await managed();
      assert.strictEqual(z('[data-test-subj="a"]'), FLYOUT_LEVEL);
      assert.strictEqual(z('[data-test-subj="b"]'), FLYOUT_LEVEL, 'both read the z-index before either registered');
    });

    test('sessions stack 3 levels higher; a child sits 1 below its main; standard flyouts over a session stack above it', async function (assert) {
      const state = new Flyouts();
      state.a = true;

      await render(
        <template>
          <EuiEmotionProvider>
            {{#if state.a}}
              <EuiFlyout @session="start" @flyoutMenuProps={{hash title="A"}} @onClose={{state.closeA}} data-test-subj="a">a</EuiFlyout>
            {{/if}}
            {{#if state.b}}
              <EuiFlyout @session="start" @size="m" @flyoutMenuProps={{hash title="B"}} @onClose={{state.closeB}} data-test-subj="b">
                {{#if state.child}}
                  <EuiFlyout @size="s" @flyoutMenuProps={{hash title="Child"}} @onClose={{state.closeChild}} data-test-subj="child">child</EuiFlyout>
                {{/if}}
              </EuiFlyout>
            {{/if}}
            {{#if state.inner}}
              <EuiFlyout @onClose={{state.closeInner}} data-test-subj="standard">standard</EuiFlyout>
            {{/if}}
          </EuiEmotionProvider>
        </template>
      );
      await managed();
      assert.strictEqual(z('[data-test-subj="a"]'), FLYOUT_LEVEL);
      state.b = true;
      await managed();
      assert.strictEqual(z('[data-test-subj="b"]'), FLYOUT_LEVEL + 3);
      assert.strictEqual(z('[data-test-subj="a"]'), FLYOUT_LEVEL + 3, 'managed flyouts take the latest session\'s z-index (upstream currentSession.zIndex)');
      state.child = true;
      await managed();
      assert.strictEqual(z('[data-test-subj="child"]'), FLYOUT_LEVEL + 2);
      assert.strictEqual(manager.state.currentZIndex, 6);

      state.inner = true;
      await managed();
      assert.strictEqual(z('[data-test-subj="standard"]'), FLYOUT_LEVEL + 6, 'a standard flyout outside the sessions reads the current z-index');
      assert.deepEqual(manager.state.unmanagedFlyouts.length, 1);
    });

    test('a standard flyout nested in a managed one takes the session z-index and is not tracked (EuiFlyoutIsManagedProvider)', async function (assert) {
      const state = new Flyouts();
      state.a = true;

      await render(
        <template>
          <EuiEmotionProvider>
            {{#if state.a}}
              <EuiFlyout @session="start" @flyoutMenuProps={{hash title="A"}} @onClose={{state.closeA}} data-test-subj="a">
                {{#if state.inner}}
                  <EuiFlyout @session="never" @onClose={{state.closeInner}} data-test-subj="never">
                    {{#if state.child}}
                      <EuiFlyout @session="never" @onClose={{state.closeChild}} data-test-subj="deeper">deeper</EuiFlyout>
                    {{/if}}
                  </EuiFlyout>
                {{/if}}
              </EuiFlyout>
            {{/if}}
          </EuiEmotionProvider>
        </template>
      );
      await managed();
      state.inner = true;
      await managed();
      state.child = true;
      await managed();

      assert.dom('[data-test-subj="never"]', document.body).doesNotHaveAttribute('data-managed-flyout');
      assert.strictEqual(z('[data-test-subj="never"]'), FLYOUT_LEVEL, 'the session z-index (0)');
      assert.strictEqual(z('[data-test-subj="deeper"]'), FLYOUT_LEVEL, 'deeper nesting stays in the managed context');
      assert.strictEqual(manager.state.unmanagedFlyouts.length, 0);
      assert.strictEqual(manager.state.currentZIndex, 3);

      await triggerKeyEvent(document, 'keydown', 'Escape');
      await managed();
      assert.deepEqual(
        state.closes.map(([name]) => name).sort(),
        ['a', 'child', 'inner'],
        'no child in the session: all close'
      );
    });
  });
});
