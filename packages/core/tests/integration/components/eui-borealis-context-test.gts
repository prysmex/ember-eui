import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { render, settled } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';
import { hash } from '@ember/helper';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { getEuiThemeContext } from '#src/utils/emotion/consume.ts';
import { EuiThemeContext } from '#src/utils/emotion/context.ts';
import {
  resolveBorealisTheme,
  mergeBorealisOverrides
} from '#src/utils/eui/theme.ts';
import type {
  EuiBorealisOverrides,
  EuiBorealisHighContrastMode
} from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';

class Probe extends Component {
  get upstream() {
    return getEuiThemeContext(this).upstream;
  }
  <template>
    <output
      data-native-probe
      data-mode={{this.upstream.colorMode}}
      data-radius={{this.upstream.euiTheme.border.radius.panel}}
      data-primary={{this.upstream.euiTheme.colors.primary}}
      data-size={{this.upstream.euiTheme.size.base}}
      data-contrast={{this.upstream.highContrastMode}}
    ></output>
  </template>
}

module('Integration | Borealis | context', function (hooks) {
  setupRenderingTest(hooks);

  test('pinned native Borealis tokens replace no globals and include semantic/computed values', function (assert) {
    const light = resolveBorealisTheme('light');
    const dark = resolveBorealisTheme('dark');
    assert.strictEqual(light.euiTheme.colors.primary, '#0B64DD');
    assert.strictEqual(dark.euiTheme.colors.primary, '#61A2FF');
    assert.strictEqual(light.euiTheme.border.radius.panel, '12px');
    assert.strictEqual(light.euiTheme.border.thin, '1px solid #E3E8F2');
    assert.strictEqual(dark.euiTheme.colors.backgroundBasePlain, '#111C2C');
    assert.strictEqual(light.euiTheme.font.weight.medium, 450);
  });

  test('native overrides recompute dependent tokens and leave upstream defaults intact', function (assert) {
    const modifications: EuiBorealisOverrides = {
      base: 20,
      colors: { LIGHT: { primary: '#663399' } }
    };
    const native = resolveBorealisTheme('light', modifications);
    assert.strictEqual(native.euiTheme.size.base, '20px');
    assert.strictEqual(native.euiTheme.border.radius.panel, '15px');
    assert.strictEqual(native.euiTheme.colors.primary, '#663399');
    assert.strictEqual(
      resolveBorealisTheme('light').euiTheme.border.radius.panel,
      '12px'
    );
    assert.deepEqual(
      modifications,
      { base: 20, colors: { LIGHT: { primary: '#663399' } } },
      'input was not mutated'
    );
  });

  test('native nested contexts inherit and react without yielded references', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = { base: 20 };
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    const child: EuiBorealisOverrides = {
      border: { radius: { panel: '18px' } }
    };
    await render(
      <template>
        <EuiEmotionProvider
          @colorMode={{state.mode}}
          @borealisOverrides={{state.overrides}}
          @highContrastMode={{state.contrast}}
        >
          <div data-parent><Probe /></div>
          <EuiEmotionProvider @borealisOverrides={{child}}><div
              data-child
            ><Probe /></div></EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light"><div data-fixed><Probe
              /></div></EuiEmotionProvider>
        </EuiEmotionProvider>
        <div data-sibling><Probe /></div>
      </template>
    );
    assert
      .dom('[data-child] output')
      .hasAttribute('data-size', '20px')
      .hasAttribute('data-radius', '18px');
    assert.dom('[data-parent] output').hasAttribute('data-radius', '15px');
    assert.dom('[data-sibling] output').hasAttribute('data-size', '16px');
    state.mode = 'dark';
    state.overrides = { base: 24 };
    state.contrast = 'preferred';
    await settled();
    assert
      .dom('[data-child] output')
      .hasAttribute('data-mode', 'DARK')
      .hasAttribute('data-radius', '18px')
      .hasAttribute('data-size', '24px')
      .hasAttribute('data-contrast', 'preferred');
    assert.dom('[data-parent] output').hasAttribute('data-radius', '18px');
    assert.dom('[data-fixed] output').hasAttribute('data-mode', 'LIGHT');
    assert.dom('[data-sibling] output').hasAttribute('data-mode', 'LIGHT');
  });

  test('computed native context stays stable until tracked dependencies change', function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
    }
    const state = new State();
    const context = new EuiThemeContext(() => ({ colorMode: state.mode }));
    const first = context.upstream;
    assert.strictEqual(context.upstream, first, 'reuses the resolved theme');
    state.mode = 'dark';
    assert.notStrictEqual(
      context.upstream,
      first,
      'invalidates on a tracked change'
    );
    assert.strictEqual(context.upstream.euiTheme.colors.primary, '#61A2FF');
  });

  test('native override merge keeps sibling objects independent', function (assert) {
    const parent: EuiBorealisOverrides = {
      colors: { LIGHT: { primary: '#663399', text: '#112233' } },
      border: { radius: { panel: '18px' } }
    };
    const child: EuiBorealisOverrides = {
      colors: { LIGHT: { primary: '#005588' } }
    };
    const merged = mergeBorealisOverrides(parent, child);
    assert.strictEqual(merged.colors?.LIGHT?.primary, '#005588');
    assert.strictEqual(merged.colors?.LIGHT?.text, '#112233');
    assert.strictEqual(parent.colors?.LIGHT?.primary, '#663399');
    assert.strictEqual(
      resolveBorealisTheme('light', merged).euiTheme.border.radius.panel,
      '18px'
    );
  });

  test('template (hash) overrides resolve through nested providers', async function (assert) {
    class State {
      @tracked primary = '#123456';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider
          @borealisOverrides={{hash
            colors=(hash LIGHT=(hash primary=state.primary))
            border=(hash radius=(hash panel="18px"))
          }}
        >
          <EuiEmotionProvider
            @borealisOverrides={{hash border=(hash radius=(hash panel="7px"))}}
          ><Probe /></EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );
    assert
      .dom('[data-native-probe]')
      .hasAttribute('data-radius', '7px', 'nearest hash override wins')
      .hasAttribute('data-primary', '#123456', 'parent hash override inherited');
    state.primary = '#654321';
    await settled();
    assert
      .dom('[data-native-probe]')
      .hasAttribute('data-primary', '#654321', 'tracked hash value re-resolves')
      .hasAttribute('data-radius', '7px');
  });

  test('merge rebuilds prototype-less override objects as plain objects', function (assert) {
    const bare = Object.assign(Object.create(null), {
      colors: Object.assign(Object.create(null), {
        LIGHT: Object.assign(Object.create(null), { textHeading: '#abcdef' })
      })
    }) as EuiBorealisOverrides;
    const merged = mergeBorealisOverrides(bare, {}) as Record<string, any>;
    assert.strictEqual(Object.getPrototypeOf(merged.colors), Object.prototype);
    assert.strictEqual(
      Object.getPrototypeOf(merged.colors.LIGHT),
      Object.prototype
    );
    assert.strictEqual(
      resolveBorealisTheme('light', merged).euiTheme.colors.textHeading,
      '#abcdef'
    );
  });
});
