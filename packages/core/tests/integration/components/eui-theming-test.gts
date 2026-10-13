import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { render, settled } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';
import { EuiThemeBorealis } from '@elastic/eui-theme-borealis';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiPanel from '#src/components/eui-panel.gts';
import EuiPopover from '#src/components/eui-popover.gts';
import {
  euiClass,
  euiCssVar,
  euiCssVariableName,
  euiThemeCssVariables,
  getEuiThemeContext,
  resolveBorealisTheme,
  useEuiBorealisStyles
} from '#src/theming.ts';
import { EuiSystemPreferences } from '#src/utils/emotion/system.ts';

import type {
  EuiColorMode,
  EuiCss,
  EuiHighContrastModeArg,
  EuiThemeContext,
  EuiThemeStyleContext
} from '#src/theming.ts';
import type EuiEmotionService from '#src/services/eui-emotion.ts';

/** Plain CSS reading a published variable. */
const probeClass = 'eui-theming-probe';
const probeStyle = document.createElement('style');
probeStyle.textContent = `.${probeClass} { color: var(--eui-color-text-subdued); }`;
document.head.appendChild(probeStyle);

/** A controllable `window.matchMedia` with change events. */
class FakeMedia {
  matches: Record<string, boolean> = {};
  listeners = new Map<string, Set<(event: MediaQueryListEvent) => void>>();
  matchMedia = (query: string) => {
    const listeners = this.listeners;
    const current = this.matches;
    return {
      media: query,
      get matches() {
        return current[query] ?? false;
      },
      addEventListener(_: string, fn: (event: MediaQueryListEvent) => void) {
        if (!listeners.has(query)) listeners.set(query, new Set());
        listeners.get(query)!.add(fn);
      },
      removeEventListener(_: string, fn: (event: MediaQueryListEvent) => void) {
        listeners.get(query)?.delete(fn);
      }
    } as unknown as MediaQueryList;
  };
  set(query: string, matches: boolean) {
    this.matches[query] = matches;
    for (const fn of this.listeners.get(query) ?? [])
      fn({ matches, media: query } as MediaQueryListEvent);
  }
  get listenerCount() {
    let count = 0;
    for (const set of this.listeners.values()) count += set.size;
    return count;
  }
}

const DARK = '(prefers-color-scheme: dark)';
const MORE = '(prefers-contrast: more)';
const FORCED = '(forced-colors: active)';

function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function rootVar(name: string) {
  return getComputedStyle(document.documentElement)
    .getPropertyValue(name)
    .trim();
}

function el(selector: string): HTMLElement {
  const element = document.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

/** Exposes its nearest context to the test. */
let captured: Record<string, EuiThemeContext> = {};
class Capture extends Component<{ Args: { name: string } }> {
  get capture() {
    captured[this.args.name] = getEuiThemeContext(this);
    return '';
  }
  <template>{{this.capture}}</template>
}

module('Integration | Theming | high contrast and system defaults', function (hooks) {
  setupRenderingTest(hooks);

  let media: FakeMedia;
  let original: typeof window.matchMedia;
  hooks.beforeEach(function () {
    captured = {};
    media = new FakeMedia();
    original = window.matchMedia;
    window.matchMedia = media.matchMedia;
  });
  hooks.afterEach(function () {
    window.matchMedia = original;
  });

  test('a root provider follows prefers-contrast and prefers-color-scheme live', async function (assert) {
    media.set(MORE, true);
    await render(
      <template>
        <EuiEmotionProvider><Capture @name="root" /></EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(captured.root!.highContrastMode, 'preferred');
    assert.strictEqual(captured.root!.colorMode, 'light');
    assert.strictEqual(captured.root!.upstream.highContrastMode, 'preferred');

    media.set(MORE, false);
    media.set(DARK, true);
    await settled();
    assert.false(captured.root!.highContrastMode);
    assert.strictEqual(captured.root!.colorMode, 'dark');
    assert.strictEqual(captured.root!.upstream.colorMode, 'DARK');
  });

  test('true means preferred, false overrides the system, undefined inherits', async function (assert) {
    class State {
      @tracked mode: EuiHighContrastModeArg | undefined = undefined;
    }
    const state = new State();
    media.set(MORE, true);
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode={{state.mode}}>
          <Capture @name="root" />
          <EuiEmotionProvider><Capture @name="nested" /></EuiEmotionProvider>
          <EuiEmotionProvider @highContrastMode={{false}}>
            <Capture @name="off" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(captured.root!.highContrastMode, 'preferred');
    assert.strictEqual(captured.nested!.highContrastMode, 'preferred');
    assert.false(captured.off!.highContrastMode, 'false opts a subtree out');

    state.mode = false;
    await settled();
    assert.false(captured.root!.highContrastMode, 'false overrides the OS');
    assert.false(captured.nested!.highContrastMode);

    media.set(MORE, false);
    state.mode = true;
    await settled();
    assert.strictEqual(captured.root!.highContrastMode, 'preferred');
    state.mode = 'forced';
    await settled();
    assert.strictEqual(captured.root!.highContrastMode, 'forced');
  });

  test('Windows forced colors supersede app contrast and color mode settings', async function (assert) {
    media.set(FORCED, true);
    await render(
      <template>
        <EuiEmotionProvider @colorMode="dark" @highContrastMode={{false}}>
          <Capture @name="root" />
          <EuiEmotionProvider @colorMode="dark" @highContrastMode={{false}}>
            <Capture @name="nested" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );
    for (const name of ['root', 'nested']) {
      assert.strictEqual(captured[name]!.highContrastMode, 'forced', name);
      assert.strictEqual(
        captured[name]!.colorMode,
        'light',
        `${name} follows the system color mode`
      );
    }
    media.set(DARK, true);
    await settled();
    assert.strictEqual(captured.nested!.colorMode, 'dark');
    media.set(FORCED, false);
    await settled();
    assert.false(captured.root!.highContrastMode);
    assert.strictEqual(captured.root!.colorMode, 'dark');
  });

  test('explicit color modes and owner service settings win over the system', async function (assert) {
    media.set(DARK, true);
    const service = this.owner.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService;
    await render(
      <template>
        <EuiEmotionProvider><Capture @name="root" /></EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <Capture @name="light" />
        </EuiEmotionProvider>
        <Capture @name="standalone" />
      </template>
    );
    assert.strictEqual(captured.root!.colorMode, 'dark');
    assert.strictEqual(captured.light!.colorMode, 'light');
    assert.strictEqual(
      captured.standalone!.colorMode,
      'light',
      'components without a provider keep the light default'
    );
    service.colorMode = 'light';
    service.highContrastMode = true;
    await settled();
    assert.strictEqual(captured.root!.colorMode, 'light');
    assert.strictEqual(captured.root!.highContrastMode, 'preferred');
  });

  test('media listeners are removed when the root provider is torn down', async function (assert) {
    class State {
      @tracked show = true;
    }
    const state = new State();
    await render(
      <template>
        {{#if state.show}}
          <EuiEmotionProvider>
            <EuiEmotionProvider><Capture @name="nested" /></EuiEmotionProvider>
          </EuiEmotionProvider>
        {{/if}}
      </template>
    );
    assert.strictEqual(media.listenerCount, 3, 'only the root listens');
    state.show = false;
    await settled();
    assert.strictEqual(media.listenerCount, 0);
  });

  test('system preferences are safe without matchMedia', function (assert) {
    window.matchMedia = undefined as unknown as typeof window.matchMedia;
    const system = new EuiSystemPreferences();
    assert.strictEqual(system.colorMode, 'light');
    assert.false(system.highContrastMode);
    system.destroy();
  });

  test('high contrast applies upstream border modifications', async function (assert) {
    for (const mode of ['light', 'dark'] as const) {
      const theme = resolveBorealisTheme(
        mode,
        { colors: { LIGHT: { primary: '#663399' } } },
        'preferred'
      ).euiTheme;
      const plain =
        mode === 'dark'
          ? EuiThemeBorealis.root.colors.plainLight
          : EuiThemeBorealis.root.colors.plainDark;
      assert.strictEqual(theme.colors.borderBasePlain, plain, mode);
      assert.strictEqual(theme.border.color, plain);
      assert.strictEqual(theme.border.thin, `1px solid ${plain}`);
      assert.strictEqual(
        theme.colors.borderBaseDanger,
        resolveBorealisTheme(mode).euiTheme.colors.textDanger
      );
      if (mode === 'light')
        assert.strictEqual(
          theme.colors.primary.toLowerCase(),
          '#663399',
          'consumer color overrides survive high contrast'
        );
    }
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode={{true}}>
          <EuiPanel @hasBorder={{true}} data-panel>Panel</EuiPanel>
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(
      getComputedStyle(el('[data-panel]')).borderTopColor,
      rgb(EuiThemeBorealis.root.colors.plainDark)
    );
  });
});

module('Integration | Theming | CSS variables', function (hooks) {
  setupRenderingTest(hooks);

  test('names are derived deterministically from token paths', function (assert) {
    assert.strictEqual(
      euiCssVariableName('colors.textSubdued'),
      '--eui-color-text-subdued'
    );
    assert.strictEqual(
      euiCssVariableName('colors.backgroundBasePlain'),
      '--eui-color-background-base-plain'
    );
    assert.strictEqual(euiCssVariableName('size.s'), '--eui-size-s');
    assert.strictEqual(
      euiCssVariableName('border.radius.medium'),
      '--eui-border-radius-medium'
    );
    assert.strictEqual(
      euiCssVariableName('font.weight.semiBold'),
      '--eui-font-weight-semi-bold'
    );
    assert.strictEqual(
      euiCssVar('colors.danger', 'red'),
      'var(--eui-color-danger, red)'
    );
    const theme = resolveBorealisTheme('light');
    const vars = euiThemeCssVariables(theme);
    assert.strictEqual(
      vars['--eui-color-text-subdued'],
      theme.euiTheme.colors.textSubdued
    );
    assert.strictEqual(vars['--eui-size-s'], '8px');
    assert.strictEqual(vars['--eui-border-width-thin'], '1px');
    assert.strictEqual(vars['--eui-font-family'], theme.euiTheme.font.family);
    assert.ok(vars['--eui-font-size-s']!.endsWith('rem'));
    assert.ok(vars['--eui-color-severity-danger']);
    assert.notOk(
      Object.keys(vars).some((key) => key.startsWith('--eui-color-vis')),
      'vis colors are left out'
    );
    assert.ok(Object.keys(vars).length > 150);
  });

  test('the root provider publishes variables that follow color mode, contrast and overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked contrast = false;
      @tracked overrides = {};
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider
          @colorMode={{state.mode}}
          @highContrastMode={{state.contrast}}
          @borealisOverrides={{state.overrides}}
        >
          <p
            class={{probeClass}}
            data-probe
          >Subdued</p>
        </EuiEmotionProvider>
      </template>
    );
    const light = resolveBorealisTheme('light').euiTheme;
    const dark = resolveBorealisTheme('dark').euiTheme;
    assert.strictEqual(
      rootVar('--eui-color-text-subdued'),
      light.colors.textSubdued
    );
    assert.strictEqual(
      getComputedStyle(el('[data-probe]')).color,
      rgb(light.colors.textSubdued)
    );
    assert.strictEqual(rootVar('--eui-size-s'), '8px');
    assert.strictEqual(
      document.querySelectorAll('style[data-emotion^="eui-vars"]').length > 0,
      true,
      'variables live in the provider-owned eui-vars cache'
    );
    assert.notOk(el('[data-probe]').getAttribute('style'), 'no inline styles');

    state.mode = 'dark';
    await settled();
    assert.strictEqual(
      rootVar('--eui-color-text-subdued'),
      dark.colors.textSubdued
    );
    assert.strictEqual(
      getComputedStyle(el('[data-probe]')).color,
      rgb(dark.colors.textSubdued)
    );

    state.contrast = true;
    await settled();
    assert.strictEqual(
      rootVar('--eui-color-border-base-plain'),
      EuiThemeBorealis.root.colors.plainLight
    );

    state.overrides = { colors: { DARK: { textSubdued: '#663399' } } };
    await settled();
    assert.strictEqual(
      rootVar('--eui-color-text-subdued').toLowerCase(),
      '#663399'
    );
  });

  test('nested providers with a different theme scope variables on their wrapper', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'dark';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <p class={{probeClass}} data-outer>Outer</p>
          <EuiEmotionProvider @colorMode={{state.mode}} data-nested>
            <p class={{probeClass}} data-inner>Inner</p>
          </EuiEmotionProvider>
          <EuiEmotionProvider data-same>
            <p class={{probeClass}} data-same-inner>Same</p>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );
    const light = resolveBorealisTheme('light').euiTheme;
    const dark = resolveBorealisTheme('dark').euiTheme;
    assert.strictEqual(
      getComputedStyle(el('[data-inner]')).color,
      rgb(dark.colors.textSubdued)
    );
    assert.strictEqual(
      getComputedStyle(el('[data-outer]')).color,
      rgb(light.colors.textSubdued),
      'siblings outside keep the root values'
    );
    assert.strictEqual(
      getComputedStyle(el('[data-same-inner]')).color,
      rgb(light.colors.textSubdued)
    );
    assert.strictEqual(
      getComputedStyle(el('[data-same]'))
        .getPropertyValue('--eui-color-text-subdued')
        .trim(),
      light.colors.textSubdued,
      'an unchanged nested theme inherits from :root'
    );
    assert.strictEqual(
      rootVar('--eui-color-text-subdued'),
      light.colors.textSubdued
    );
    state.mode = 'light';
    await settled();
    assert.strictEqual(
      getComputedStyle(el('[data-inner]')).color,
      rgb(light.colors.textSubdued)
    );
  });

  test('variables are removed with the root provider', async function (assert) {
    class State {
      @tracked show = true;
    }
    const state = new State();
    await render(
      <template>
        {{#if state.show}}
          <EuiEmotionProvider @globalStyles={{false}} />
        {{/if}}
      </template>
    );
    assert.ok(rootVar('--eui-size-s'), 'published even without global styles');
    state.show = false;
    await settled();
    assert.strictEqual(rootVar('--eui-size-s'), '');
  });
});

const noop = () => {};
let calls = 0;
const dangerText: EuiCss = ({ euiTheme }: EuiThemeStyleContext) => {
  calls++;
  return { color: euiTheme.colors.textDanger };
};
const nested: EuiCss = [
  { fontWeight: 700 },
  ({ euiTheme }: EuiThemeStyleContext) => [
    { borderInlineStartColor: euiTheme.colors.borderStrongAccent }
  ]
];

const boxStyles = ({ euiTheme }: EuiThemeStyleContext) => ({
  root: { padding: euiTheme.size.m, color: euiTheme.colors.textSuccess }
});

class CustomBox extends Component<{ Element: HTMLDivElement; Blocks: { default: [] } }> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    return euiClass(context, useEuiBorealisStyles(context, boxStyles).root);
  }
  <template>
    <div class={{this.classes}} ...attributes>{{yield}}</div>
  </template>
}

module('Integration | Theming | theme function @css', function (hooks) {
  setupRenderingTest(hooks);

  test('a theme function @css follows the theme and stays cached otherwise', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked padding: 's' | 'l' = 's';
    }
    const state = new State();
    calls = 0;
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiPanel
            @paddingSize={{state.padding}}
            @css={{dangerText}}
            data-panel
          >Danger</EuiPanel>
          <EuiPanel @css={{dangerText}} data-twin>Twin</EuiPanel>
          <EuiPanel @css={{nested}} @hasBorder={{true}} data-nested>Nested</EuiPanel>
        </EuiEmotionProvider>
      </template>
    );
    const light = resolveBorealisTheme('light').euiTheme;
    const dark = resolveBorealisTheme('dark').euiTheme;
    const panel = el('[data-panel]');
    assert.strictEqual(getComputedStyle(panel).color, rgb(light.colors.textDanger));
    assert.strictEqual(calls, 1, 'one call per theme, shared by every user');
    assert.strictEqual(getComputedStyle(el('[data-nested]')).fontWeight, '700');
    assert.strictEqual(
      getComputedStyle(el('[data-nested]')).borderLeftColor,
      rgb(light.colors.borderStrongAccent),
      'functions nested in arrays resolve too'
    );

    state.padding = 'l';
    await settled();
    assert.strictEqual(calls, 1, 'unrelated argument changes reuse the result');
    assert.strictEqual(el('[data-panel]'), panel, 'element kept');

    state.mode = 'dark';
    await settled();
    assert.strictEqual(getComputedStyle(panel).color, rgb(dark.colors.textDanger));
    assert.strictEqual(calls, 2);

    state.mode = 'light';
    await settled();
    assert.strictEqual(getComputedStyle(panel).color, rgb(light.colors.textDanger));
  });

  test('slot css args such as @panelCss accept theme functions', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider @colorMode="dark">
          <EuiPopover @isOpen={{true}} @closePopover={{noop}} @panelCss={{dangerText}}>
            <:button><button type="button">Open</button></:button>
            <:content><span data-content>Content</span></:content>
          </EuiPopover>
        </EuiEmotionProvider>
      </template>
    );
    const content = document.querySelector('[data-content]')!;
    const panel = content.closest('.euiPopover__panel')!;
    assert.strictEqual(
      getComputedStyle(panel).color,
      rgb(resolveBorealisTheme('dark').euiTheme.colors.textDanger)
    );
  });

  test('custom components compose factories and strings through euiClass', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider @colorMode="dark">
          <CustomBox data-box>Box</CustomBox>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiPanel @css="text-decoration: underline;" data-string>String</EuiPanel>
        </EuiEmotionProvider>
      </template>
    );
    const dark = resolveBorealisTheme('dark').euiTheme;
    assert.strictEqual(getComputedStyle(el('[data-box]')).color, rgb(dark.colors.textSuccess));
    assert.strictEqual(getComputedStyle(el('[data-box]')).paddingTop, '12px');
    assert.true(
      getComputedStyle(el('[data-string]')).textDecorationLine.includes('underline')
    );
  });
});
