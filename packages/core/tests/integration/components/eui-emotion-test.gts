import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { click, render, settled } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiEmotionButton from '#src/components/eui-emotion-button.gts';
import { createEuiEmotionCache, EuiThemeContext, useEuiStyles } from '#src/utils/emotion/context.ts';
import type EuiEmotionService from '#src/services/eui-emotion.ts';
import type { EuiColorMode, EuiThemeOverrides } from '#src/utils/emotion/theme.ts';

module('Integration | Component | Emotion spike', function (hooks) {
  setupRenderingTest(hooks);

  test('styles light and dark buttons without the legacy stylesheet', async function (assert) {
    await render(<template>
      <EuiEmotionProvider @colorMode="light" as |eui|>
        <eui.Button @fill={{true}} data-light>Light</eui.Button>
      </EuiEmotionProvider>
      <EuiEmotionProvider @colorMode="dark" as |eui|>
        <eui.Button @fill={{true}} data-dark>Dark</eui.Button>
      </EuiEmotionProvider>
    </template>);

    const light = this.element.querySelector('[data-light]')!;
    const dark = this.element.querySelector('[data-dark]')!;
    assert.strictEqual(getComputedStyle(light).backgroundColor, 'rgb(0, 90, 158)');
    assert.strictEqual(getComputedStyle(dark).backgroundColor, 'rgb(121, 184, 255)');
    assert.dom('[data-light]').doesNotHaveClass('euiButton').hasText('Light');
    assert.strictEqual(getComputedStyle(light).minHeight, '40px');
  });

  test('provider arguments reactively update existing buttons', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiThemeOverrides = {};
    }
    const state = new State();
    await render(<template>
      <EuiEmotionProvider @colorMode={{state.mode}} @overrides={{state.overrides}} as |eui|>
        <eui.Button @fill={{true}} data-button>Save</eui.Button>
      </EuiEmotionProvider>
    </template>);
    const button = this.element.querySelector('[data-button]')!;
    const initialClass = button.className;
    state.mode = 'dark';
    await settled();
    assert.strictEqual(getComputedStyle(button).backgroundColor, 'rgb(121, 184, 255)');
    assert.notStrictEqual(button.className, initialClass);
    state.overrides = { colors: { primary: '#663399' }, borderRadius: 12 };
    await settled();
    assert.strictEqual(getComputedStyle(button).backgroundColor, 'rgb(102, 51, 153)');
    assert.strictEqual(getComputedStyle(button).borderRadius, '12px');
    state.overrides = {};
    state.mode = 'light';
    await settled();
    assert.strictEqual(button.className, initialClass, 'same tokens reuse the generated class');
  });

  test('nested providers inherit tokens and mode without changing siblings', async function (assert) {
    const overrides: EuiThemeOverrides = { spacing: 10, colors: { primary: '#663399' } };
    const child: EuiThemeOverrides = { borderRadius: 12 };
    class State { @tracked mode: EuiColorMode = 'dark'; }
    const state = new State();
    await render(<template>
      <EuiEmotionProvider @colorMode={{state.mode}} @overrides={{overrides}} as |parent|>
        <parent.Button @fill={{true}} data-parent>Parent</parent.Button>
        <EuiEmotionProvider @parent={{parent.context}} @overrides={{child}} as |nested|>
          <nested.Button @fill={{true}} data-child>Child</nested.Button>
        </EuiEmotionProvider>
        <EuiEmotionProvider @parent={{parent.context}} @colorMode="light" as |nested|>
          <nested.Button data-light>Light island</nested.Button>
        </EuiEmotionProvider>
      </EuiEmotionProvider>
      <EuiEmotionButton @fill={{true}} data-sibling>Sibling</EuiEmotionButton>
    </template>);
    const style = (selector: string) => getComputedStyle(this.element.querySelector(selector)!);
    assert.strictEqual(style('[data-child]').backgroundColor, 'rgb(102, 51, 153)');
    assert.strictEqual(style('[data-child]').paddingLeft, '20px');
    assert.strictEqual(style('[data-child]').borderRadius, '12px');
    assert.strictEqual(style('[data-parent]').borderRadius, '6px');
    assert.strictEqual(style('[data-sibling]').backgroundColor, 'rgb(0, 90, 158)');
    assert.strictEqual(style('[data-light]').backgroundColor, 'rgb(255, 255, 255)');
    state.mode = 'light';
    await settled();
    assert.strictEqual(style('[data-child]').color, 'rgb(255, 255, 255)', 'child follows parent mode');
    assert.deepEqual(overrides, { spacing: 10, colors: { primary: '#663399' } }, 'parent input was not mutated');
  });

  test('standalone buttons follow owner service settings', async function (assert) {
    const service = this.owner.lookup('service:eui-emotion') as EuiEmotionService;
    await render(<template><EuiEmotionButton @fill={{true}} data-button>Save</EuiEmotionButton></template>);
    service.colorMode = 'dark';
    await settled();
    assert.strictEqual(getComputedStyle(this.element.querySelector('[data-button]')!).backgroundColor, 'rgb(121, 184, 255)');
  });

  test('native semantics, modifiers, loading, links and variants', async function (assert) {
    let clicks = 0;
    const clicked = () => clicks++;
    await render(<template>
      <EuiEmotionButton @type="submit" @isSelected={{true}} @size="s" {{on "click" clicked}} data-submit>Save</EuiEmotionButton>
      <EuiEmotionButton @href="#target" @target="_blank" data-link>Open</EuiEmotionButton>
      <EuiEmotionButton @href="#target" @disabled={{true}} data-disabled>Disabled</EuiEmotionButton>
      <EuiEmotionButton @href="#target" @isLoading={{true}} data-loading>Loading</EuiEmotionButton>
      <EuiEmotionButton @color="danger" @fill={{true}} @fullWidth={{true}} data-danger>Delete</EuiEmotionButton>
    </template>);
    assert.dom('button[data-submit]').hasAttribute('type', 'submit').hasAttribute('aria-pressed', 'true');
    assert.strictEqual(getComputedStyle(this.element.querySelector('[data-submit]')!).minHeight, '32px');
    await click('[data-submit]');
    assert.strictEqual(clicks, 1);
    assert.dom('a[data-link]').hasAttribute('href', '#target').hasAttribute('target', '_blank');
    assert.dom('button[data-disabled]').isDisabled().doesNotHaveAttribute('href');
    assert.dom('button[data-loading]').isDisabled().hasAttribute('aria-busy', 'true').hasText('Loading');
    assert.dom('[data-loading] [aria-hidden="true"]').exists();
    assert.strictEqual(getComputedStyle(this.element.querySelector('[data-danger]')!).backgroundColor, 'rgb(180, 35, 44)');
  });

  test('explicit cache supports containers and nonces and deduplicates styles', async function (assert) {
    const container = document.createElement('div');
    document.head.append(container);
    const cache = createEuiEmotionCache({ key: 'eui-test', container, nonce: 'spike-nonce', speedy: false });
    try {
      const context = new EuiThemeContext(() => ({ cache }));
      const first = useEuiStyles(context, (theme) => ({ color: theme.colors.primary }));
      const count = Object.keys(cache.cache.inserted).length;
      assert.strictEqual(useEuiStyles(context, (theme) => ({ color: theme.colors.primary })), first);
      assert.strictEqual(Object.keys(cache.cache.inserted).length, count);
      await render(<template>
        <EuiEmotionProvider @cache={{cache}} as |eui|>
          <eui.Button data-button>Save</eui.Button>
        </EuiEmotionProvider>
      </template>);
      assert.true(container.querySelectorAll('style[data-emotion="eui-test"]').length > 0);
      assert.strictEqual(container.querySelector('style')?.nonce, 'spike-nonce');
      assert.dom('[data-button]').hasClass(/^eui-test-/);
    } finally {
      cache.flush();
      container.remove();
    }
  });

  test('destroying a context flushes only its own cache', function (assert) {
    const owned = new EuiThemeContext(() => ({}));
    const ownedCache = owned.cache;
    useEuiStyles(owned, () => ({ color: 'red' }));
    owned.destroy();
    assert.strictEqual(Object.keys(ownedCache.cache.inserted).length, 0);

    const shared = createEuiEmotionCache({ key: 'eui-shared' });
    try {
      const parent = new EuiThemeContext(() => ({ cache: shared }));
      const child = new EuiThemeContext(() => ({}), () => parent);
      useEuiStyles(child, () => ({ color: 'blue' }));
      child.destroy();
      parent.destroy();
      assert.strictEqual(Object.keys(shared.cache.inserted).length, 1, 'caller-owned cache survives both contexts');
    } finally {
      shared.flush();
    }
  });
});
