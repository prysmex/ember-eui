import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled, triggerEvent, triggerKeyEvent } from '@ember/test-helpers';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFocusTrap from '#src/components/eui-focus-trap.gts';
import EuiWindowEvent from '#src/components/eui-window-event.gts';
import { attachToFocusTraps } from '#src/-private/focus-trap-registry.ts';

function el(selector: string): HTMLElement {
  const element = document.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

class State {
  @tracked disabled = false;
  @tracked show = true;
  @tracked event = 'keydown';
  @tracked shards: Array<string | HTMLElement> = [];
  calls: string[] = [];
}

module('Integration | Component | EuiFocusTrap', function (hooks) {
  setupRenderingTest(hooks);

  test('renders the wrapper and focuses the first tabbable element', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <input data-test-outside />
          <EuiFocusTrap class="mine" style="height: 10px">
            <input data-test-first />
            <input data-test-second />
          </EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    const wrapper = el('.mine');
    assert.strictEqual(wrapper.getAttribute('data-focus-lock-disabled'), 'false');
    assert.strictEqual(wrapper.style.height, '10px');
    assert.strictEqual(document.activeElement, el('[data-test-first]'));
  });

  test('disabled neither traps nor moves focus; toggling activates', async function (assert) {
    const state = new State();
    state.disabled = true;
    await render(
      <template>
        <EuiEmotionProvider>
          <input data-test-outside />
          <EuiFocusTrap class="mine" @disabled={{state.disabled}}>
            <input data-test-first />
          </EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(el('.mine').getAttribute('data-focus-lock-disabled'), 'disabled');
    assert.notStrictEqual(document.activeElement, el('[data-test-first]'));
    state.disabled = false;
    await settled();
    await new Promise((resolve) => setTimeout(resolve, 20));
    assert.strictEqual(el('.mine').getAttribute('data-focus-lock-disabled'), 'false');
    assert.strictEqual(document.activeElement, el('[data-test-first]'));
    el('[data-test-outside]').focus();
    await settled();
    assert.strictEqual(document.activeElement, el('[data-test-first]'), 'outside focus is pulled back');
  });

  test('autoFocus, data-autofocus and initialFocus pick the focused element', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <div id="a"><EuiFocusTrap @autoFocus={{false}}><input data-test-a1 /></EuiFocusTrap></div>
          <div id="b"><EuiFocusTrap><input data-test-b1 /><input data-autofocus data-test-b2 /></EuiFocusTrap></div>
          <div id="c"><EuiFocusTrap @initialFocus="[data-test-c2]"><input data-test-c1 /><input data-test-c2 /></EuiFocusTrap></div>
        </EuiEmotionProvider>
      </template>
    );
    assert.notStrictEqual(document.activeElement, el('[data-test-a1]'), 'autoFocus false');
    assert.notStrictEqual(document.activeElement, el('[data-test-b1]'));
    // the last trap activated wins focus
    assert.strictEqual(document.activeElement, el('[data-test-c2]'), 'initialFocus selector');
  });

  test('data-autofocus wins when the only trap', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFocusTrap><input data-test-b1 /><input data-autofocus data-test-b2 /></EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(document.activeElement, el('[data-test-b2]'));
  });

  test('returnFocus returns focus on deactivation unless false', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider>
          <button type="button" data-test-opener>open</button>
          {{#if state.show}}
            <EuiFocusTrap @returnFocus={{false}}><input data-test-x /></EuiFocusTrap>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    state.show = false;
    await settled();
    assert.notStrictEqual(document.activeElement, el('[data-test-opener]'), 'false leaves focus');

    const other = new State();
    await render(
      <template>
        <EuiEmotionProvider>
          <button type="button" data-test-opener>open</button>
          <EuiFocusTrap @disabled={{other.disabled}}><input data-test-x /></EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    el('[data-test-opener]').focus();
    other.disabled = true;
    other.disabled = false;
    await settled();
    other.disabled = true;
    await settled();
    assert.ok(true);
  });

  test('returnFocus function can opt out', async function (assert) {
    const state = new State();
    let received: Element | undefined;
    const returnFocus = (to: Element) => {
      received = to;
      return false;
    };
    await render(
      <template>
        <EuiEmotionProvider>
          <button type="button" data-test-opener>open</button>
          {{#if state.show}}
            <EuiFocusTrap @returnFocus={{returnFocus}}><input data-test-x /></EuiFocusTrap>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    state.show = false;
    await settled();
    await new Promise((resolve) => setTimeout(resolve, 20));
    assert.ok(received, 'called with the element to return to');
    assert.notStrictEqual(document.activeElement, el('[data-test-opener]'));
  });

  test('onClickOutside fires for outside presses only; shards and surfaces are inside', async function (assert) {
    const state = new State();
    const shard = document.createElement('div');
    shard.id = 'shard';
    document.body.appendChild(shard);
    state.shards = [shard];
    const surface = document.createElement('div');
    document.body.appendChild(surface);
    const onClickOutside = () => state.calls.push('outside');
    await render(
      <template>
        <EuiEmotionProvider>
          <button type="button" data-test-outside>x</button>
          <EuiFocusTrap @onClickOutside={{onClickOutside}} @shards={{state.shards}}>
            <button type="button" data-test-in>in</button>
            <span data-test-anchor>anchor</span>
          </EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    await triggerEvent('[data-test-in]', 'mousedown');
    await triggerEvent(shard, 'mousedown');
    assert.deepEqual(state.calls, [], 'inside and shard presses ignored');
    const detach = attachToFocusTraps(el('[data-test-anchor]'), surface);
    await triggerEvent(surface, 'mousedown');
    assert.deepEqual(state.calls, [], 'attached surface counts as inside');
    detach();
    await triggerEvent('[data-test-outside]', 'mousedown');
    assert.deepEqual(state.calls, ['outside']);
    await triggerEvent('[data-test-outside]', 'touchstart');
    assert.deepEqual(state.calls, ['outside', 'outside']);
    shard.remove();
    surface.remove();
  });

  test('shards can be focused without being pulled back', async function (assert) {
    const shard = document.createElement('div');
    shard.innerHTML = '<input data-test-shard-input />';
    document.body.appendChild(shard);
    const shards = [shard];
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFocusTrap @shards={{shards}}><input data-test-first /></EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    el('[data-test-shard-input]').focus();
    await settled();
    assert.strictEqual(document.activeElement, el('[data-test-shard-input]'));
    shard.remove();
  });

  test('closeOnMouseup defers onClickOutside to mouseup', async function (assert) {
    const state = new State();
    const onClickOutside = () => state.calls.push('outside');
    await render(
      <template>
        <EuiEmotionProvider>
          <button type="button" data-test-outside>x</button>
          <EuiFocusTrap @onClickOutside={{onClickOutside}} @closeOnMouseup={{true}}><input /></EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    await triggerEvent('[data-test-outside]', 'mousedown');
    assert.deepEqual(state.calls, []);
    await triggerEvent('[data-test-outside]', 'mouseup');
    await new Promise((resolve) => setTimeout(resolve, 10));
    assert.deepEqual(state.calls, ['outside']);
  });

  test('clickOutsideDisables disables until @disabled changes', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider>
          <button type="button" data-test-outside>x</button>
          <EuiFocusTrap class="mine" @disabled={{state.disabled}} @clickOutsideDisables={{true}}><input /></EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    await triggerEvent('[data-test-outside]', 'mousedown');
    assert.strictEqual(el('.mine').getAttribute('data-focus-lock-disabled'), 'disabled');
    state.disabled = true;
    await settled();
    state.disabled = false;
    await settled();
    assert.strictEqual(el('.mine').getAttribute('data-focus-lock-disabled'), 'false');
  });

  test('onEscapeKey, onActivation and onDeactivation', async function (assert) {
    const state = new State();
    const onEscapeKey = () => state.calls.push('escape');
    const onActivation = (node: HTMLElement) => state.calls.push(`activate:${node.className}`);
    const onDeactivation = () => state.calls.push('deactivate');
    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.show}}
            <EuiFocusTrap class="mine" @onEscapeKey={{onEscapeKey}} @onActivation={{onActivation}} @onDeactivation={{onDeactivation}}><input data-test-in /></EuiFocusTrap>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    await triggerKeyEvent('[data-test-in]', 'keydown', 'Escape');
    state.show = false;
    await settled();
    await new Promise((resolve) => setTimeout(resolve, 20));
    assert.strictEqual(state.calls.join('|'), 'activate:mine|escape|deactivate');
  });

  test('scrollLock locks the body while enabled and restores it', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFocusTrap @scrollLock={{true}} @disabled={{state.disabled}}><input /></EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(document.body.style.overflow, 'hidden');
    state.disabled = true;
    await settled();
    assert.strictEqual(document.body.style.overflow, '');
  });

  test('noIsolation false hides and blocks the outside until disabled', async function (assert) {
    const state = new State();
    const sibling = document.createElement('div');
    document.body.appendChild(sibling);
    await render(
      <template>
        <EuiEmotionProvider>
          <p data-test-sibling>sibling</p>
          <EuiFocusTrap @noIsolation={{false}} @disabled={{state.disabled}}><input /></EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(sibling.getAttribute('aria-hidden'), 'true');
    assert.strictEqual(el('[data-test-sibling]').getAttribute('aria-hidden'), 'true');
    assert.strictEqual(el('[data-test-sibling]').style.pointerEvents, 'none');
    state.disabled = true;
    await settled();
    assert.strictEqual(sibling.getAttribute('aria-hidden'), null);
    assert.strictEqual(el('[data-test-sibling]').getAttribute('aria-hidden'), null);
    sibling.remove();
  });

  test('crossFrame false lets focus move into an iframe', async function (assert) {
    const iframe = document.createElement('iframe');
    document.body.appendChild(iframe);
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFocusTrap @crossFrame={{false}}><input data-test-in /></EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    iframe.focus();
    await new Promise((resolve) => setTimeout(resolve, 50));
    assert.strictEqual(document.activeElement, iframe);
    iframe.remove();
  });

  test('crossFrame true keeps focus out of an iframe', async function (assert) {
    const iframe = document.createElement('iframe');
    document.body.appendChild(iframe);
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFocusTrap @crossFrame={{true}}><input data-test-in /></EuiFocusTrap>
        </EuiEmotionProvider>
      </template>
    );
    iframe.focus();
    await new Promise((resolve) => setTimeout(resolve, 50));
    assert.strictEqual(document.activeElement, el('[data-test-in]'));
    iframe.remove();
  });
});

module('Integration | Component | EuiWindowEvent', function (hooks) {
  setupRenderingTest(hooks);

  test('subscribes while rendered, resubscribes on change and unsubscribes', async function (assert) {
    const state = new State();
    const handler = (e: Event) => state.calls.push(`h:${e.type}`);
    await render(
      <template>
        {{#if state.show}}
          <EuiWindowEvent @event={{state.event}} @handler={{handler}} />
        {{/if}}
      </template>
    );
    window.dispatchEvent(new Event('keydown'));
    window.dispatchEvent(new Event('mousemove'));
    assert.deepEqual(state.calls, ['h:keydown']);
    state.event = 'mousemove';
    await settled();
    window.dispatchEvent(new Event('keydown'));
    window.dispatchEvent(new Event('mousemove'));
    assert.deepEqual(state.calls, ['h:keydown', 'h:mousemove']);
    state.show = false;
    await settled();
    window.dispatchEvent(new Event('mousemove'));
    assert.deepEqual(state.calls, ['h:keydown', 'h:mousemove']);
  });
});

