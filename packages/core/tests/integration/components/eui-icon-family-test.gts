import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { getRootElement, render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiAvatar from '#src/components/eui-avatar.gts';
import EuiBeacon from '#src/components/eui-beacon.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiHealth from '#src/components/eui-health.gts';
import EuiIcon from '#src/components/eui-icon.gts';
import EuiIconTip from '#src/components/eui-icon-tip.gts';
import EuiToken from '#src/components/eui-token.gts';
import { clearIconCache } from '#src/-private/icon-loader.ts';
import { isColorDark } from '#src/helpers/is-color-dark.ts';
import { hexToRgb } from '#src/helpers/hex-to-rgb.ts';
import { preloadIcons } from '#src/utils/preload-icons.ts';
import {
  shade,
  tint,
  TOKEN_COLOR_TO_ICON_COLOR_MAP
} from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const TRANSPARENT = 'rgba(0, 0, 0, 0)';

type Theme = typeof light;
const vis = (theme: Theme) =>
  theme.colors.vis as unknown as Record<string, string>;

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function el(root: Element, selector: string) {
  const element = root.querySelector(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element, selector: string, pseudo?: string) {
  return getComputedStyle(el(root, selector), pseudo);
}

/**
 * Measured layout box in CSS pixels. The ember-qunit container is scaled, so
 * client rects are divided by that scale to give real rendered dimensions.
 */
function box(element: Element) {
  const container = document.querySelector<HTMLElement>('#ember-testing')!;
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = element.getBoundingClientRect();
  return {
    width: Math.round((rect.width / scale) * 100) / 100,
    height: Math.round((rect.height / scale) * 100) / 100,
    left: rect.left / scale,
    right: rect.right / scale
  };
}

/**
 * The first svg rendered by `callback` and its computed state, captured as
 * soon as it is in the DOM (before a lazily loaded icon can arrive).
 */
async function firstRenderedSvg(callback: () => Promise<void>) {
  let first:
    | {
        loading: string | null;
        loaded: string | null;
        children: number;
        opacity: string;
        background: string;
        radius: string;
        color: string;
      }
    | undefined;
  const observer = new MutationObserver(() => {
    const svg = getRootElement().querySelector('svg');
    if (svg && !first) {
      const css = getComputedStyle(svg);
      first = {
        loading: svg.getAttribute('data-is-loading'),
        loaded: svg.getAttribute('data-is-loaded'),
        children: svg.childElementCount,
        opacity: css.opacity,
        background: css.backgroundColor,
        radius: css.borderRadius,
        color: css.color
      };
    }
  });
  observer.observe(getRootElement(), { childList: true, subtree: true });
  await callback();
  observer.disconnect();
  return first;
}

const ICON_SIZES = {
  s: 12,
  m: 16,
  l: 24,
  xl: 32,
  xxl: 40
} as const;

/** Named icon colors and the Borealis token each one renders. */
const ICON_COLORS: Record<string, keyof Theme['colors']> = {
  primary: 'textPrimary',
  accent: 'textAccent',
  accentSecondary: 'textAccentSecondary',
  ghost: 'textGhost',
  subdued: 'textSubdued',
  text: 'textHeading',
  neutral: 'textNeutral',
  success: 'textSuccess',
  warning: 'textWarning',
  risk: 'textRisk',
  danger: 'textDanger'
};

module('Integration | Component | Borealis icon family', function (hooks) {
  setupRenderingTest(hooks);

  module('EuiIcon', function () {
    test('every size measures the upstream square; original keeps the svg size', async function (assert) {
      const sizes = Object.keys(ICON_SIZES);
      await render(
        <template>
          {{#each sizes as |size|}}
            {{! @glint-expect-error the arg type is a union }}
            <EuiIcon @type="bell" @size={{size}} data-size={{size}} />
          {{/each}}
          <EuiIcon @type="bell" @size="original" data-original />
          <EuiIcon @type="apmApp" @size="original" data-original-app />
          <EuiIcon @type="bell" data-default />
        </template>
      );
      for (const [size, px] of Object.entries(ICON_SIZES)) {
        const svg = el(this.element, `[data-size="${size}"]`);
        const css = getComputedStyle(svg);
        assert.deepEqual(
          [box(svg).width, box(svg).height],
          [px, px],
          `${size} measures ${px}px`
        );
        assert.strictEqual(css.inlineSize, `${px}px`, `${size} logical size`);
        assert.strictEqual(css.display, 'inline-block');
        assert.strictEqual(css.verticalAlign, 'middle');
        assert.strictEqual(css.flexShrink, '0');
        assert.strictEqual(css.fill, css.color, `${size} fills currentColor`);
        assert.dom(svg).hasClass('euiIcon');
      }
      assert.strictEqual(box(el(this.element, '[data-default]')).width, 16, 'default m');
      assert.strictEqual(box(el(this.element, '[data-original]')).width, 16, 'svg width attribute');
      assert.strictEqual(box(el(this.element, '[data-original-app]')).width, 32, 'app svg is 32px');
    });

    test('named colors use their Borealis text tokens; default and inherit inherit', async function (assert) {
      const colors = Object.keys(ICON_COLORS);
      await render(
        <template>
          <div style="color: rgb(1, 2, 3)">
            {{#each colors as |color|}}
              <EuiIcon @type="bell" @color={{color}} data-color={{color}} />
            {{/each}}
            <EuiIcon @type="bell" @color="default" data-default />
            <EuiIcon @type="bell" @color="inherit" data-inherit />
            <EuiIcon @type="bell" data-none />
          </div>
        </template>
      );
      for (const [color, token] of Object.entries(ICON_COLORS)) {
        const css = style(this.element, `[data-color="${color}"]`);
        assert.strictEqual(css.color, rgb(light.colors[token] as string), `${color} → ${token}`);
        assert.strictEqual(css.fill, css.color, `${color} fill follows color`);
      }
      for (const name of ['default', 'inherit', 'none'])
        assert.strictEqual(style(this.element, `[data-${name}]`).color, 'rgb(1, 2, 3)', name);
    });

    test('custom colors set color through a class, keeping the caller style', async function (assert) {
      class State {
        @tracked color = '#00ff00';
      }
      const state = new State();
      await render(
        <template>
          <EuiIcon @type="bell" @color={{state.color}} style="opacity: 0.5" data-custom />
          <EuiIcon @type="bell" @color="rgb(10, 20, 30)" data-rgb />
          <EuiIcon @type="bell" @color="red" data-keyword />
        </template>
      );
      const svg = el(this.element, '[data-custom]');
      assert.strictEqual(getComputedStyle(svg).color, 'rgb(0, 255, 0)');
      assert.strictEqual(getComputedStyle(svg).fill, 'rgb(0, 255, 0)');
      assert.strictEqual(getComputedStyle(svg).opacity, '0.5', 'caller style kept');
      assert.strictEqual(svg.getAttribute('style'), 'opacity: 0.5');
      assert.strictEqual(style(this.element, '[data-rgb]').color, 'rgb(10, 20, 30)');
      assert.strictEqual(style(this.element, '[data-keyword]').color, 'rgb(255, 0, 0)');

      state.color = 'danger';
      await settled();
      assert.strictEqual(el(this.element, '[data-custom]'), svg, 'same element');
      assert.strictEqual(getComputedStyle(svg).color, rgb(light.colors.textDanger));
    });

    test('app icons are two-toned until colored; text/ghost force one tone', async function (assert) {
      await render(
        <template>
          <EuiIcon @type="apmApp" data-app />
          <EuiIcon @type="apmApp" @color="default" data-app-default />
          <EuiIcon @type="apmApp" @color="primary" data-app-primary />
          <EuiIcon @type="apmApp" @color="ghost" data-app-ghost />
          <EuiIcon @type="classificationJob" data-job />
          <EuiIcon @type="logoKibana" data-negative />
          <EuiIcon @type="logoElastic" @color="text" data-logo-text />
          <EuiIcon @type="logoElastic" data-logo />
        </template>
      );
      const secondary = (selector: string) =>
        style(this.element, `${selector} .euiIcon__fillSecondary`).fill;
      for (const selector of ['[data-app]', '[data-app-default]', '[data-job]']) {
        assert.strictEqual(style(this.element, selector).fill, rgb(light.colors.textParagraph), `${selector} base tone`);
        assert.strictEqual(secondary(selector), rgb(light.colors.primary), `${selector} secondary tone`);
      }
      const primary = rgb(light.colors.textPrimary);
      assert.strictEqual(style(this.element, '[data-app-primary]').fill, primary);
      assert.strictEqual(secondary('[data-app-primary]'), primary, 'colored: one tone');
      assert.strictEqual(secondary('[data-app-ghost]'), rgb(light.colors.textGhost), 'ghost forces currentColor');
      assert.strictEqual(
        style(this.element, '[data-negative] .euiIcon__fillNegative').fill,
        rgb(light.colors.darkestShade),
        'fillNegative uses darkestShade in light mode'
      );
      // logoElasticOutline: `*[fill]` loses its fill and is stroked instead
      const filled = el(this.element, '[data-logo-text]').querySelector('[fill]:not(svg)');
      if (filled) {
        assert.strictEqual(getComputedStyle(filled).fill, 'none');
        assert.strictEqual(getComputedStyle(filled).stroke, rgb(light.colors.textHeading));
      } else {
        const self = style(this.element, '[data-logo-text]');
        assert.strictEqual(self.stroke, rgb(light.colors.textHeading), 'outline stroke');
      }
      assert.strictEqual(style(this.element, '[data-logo]').stroke, 'none', 'plain logo not outlined');
    });

    test('a loading icon shows the upstream placeholder, then fades in once', async function (assert) {
      clearIconCache();
      let loads = 0;
      const onLoad = () => loads++;
      const first = await firstRenderedSvg(() =>
        render(
          <template>
            <div style="color: rgb(200, 0, 0)">
              <EuiIcon @type="bell" @size="l" @onIconLoad={{onLoad}} />
            </div>
          </template>
        )
      );
      assert.ok(first, 'captured the first svg');
      assert.strictEqual(first!.children, 0, 'empty svg first');
      assert.strictEqual(first!.loading, 'true', 'data-is-loading');
      assert.strictEqual(first!.loaded, null);
      assert.strictEqual(first!.opacity, '0.05', 'upstream iconLoadingOpacity');
      assert.strictEqual(first!.background, 'rgb(200, 0, 0)', 'currentColor placeholder');
      assert.strictEqual(first!.radius, light.border.radius.inline);

      const svg = el(this.element, 'svg');
      const css = getComputedStyle(svg);
      assert.dom(svg).hasAttribute('data-is-loaded', 'true');
      assert.dom(svg).doesNotHaveAttribute('data-is-loading');
      assert.dom(svg).hasAttribute('data-icon-type', 'bell');
      assert.ok(svg.childElementCount > 0, 'the icon arrived');
      assert.strictEqual(css.backgroundColor, TRANSPARENT, 'placeholder gone');
      assert.ok(css.animationName.startsWith('animation-'), `fade-in animation (${css.animationName})`);
      assert.strictEqual(css.animationDuration, '0.25s', 'animation.normal');
      assert.strictEqual(css.animationFillMode, 'forwards');
      assert.strictEqual(box(svg).width, 24, 'size kept');
      assert.strictEqual(loads, 1, '@onIconLoad once, after loading');
    });

    test('preloaded icons render without placeholder or animation', async function (assert) {
      await preloadIcons(['bell']);
      let loads = 0;
      const onLoad = () => loads++;
      const first = await firstRenderedSvg(() =>
        render(<template><EuiIcon @type="bell" @onIconLoad={{onLoad}} /></template>)
      );
      assert.true((first?.children ?? 0) > 0, 'final svg first');
      assert.strictEqual(first?.loading, null);
      const css = style(this.element, 'svg');
      assert.dom('svg').doesNotHaveAttribute('data-is-loaded');
      assert.strictEqual(css.animationName, 'none');
      assert.strictEqual(css.opacity, '1');
      assert.strictEqual(loads, 1, '@onIconLoad on insert');
    });

    test('semantics: decorative, titled, labelled and caller overrides', async function (assert) {
      await render(
        <template>
          <EuiIcon @type="bell" data-decorative />
          <EuiIcon @type="bell" @title="Bell" data-title />
          <EuiIcon @type="bell" @title="Bell" @titleId="my-title" data-title-id />
          <EuiIcon @type="bell" @aria-label="Alerts" data-label />
          <EuiIcon @type="bell" @aria-label="Alerts" @title="Bell" data-label-title />
          <span id="ext">External</span>
          <EuiIcon @type="bell" @aria-labelledby="ext" @title="Ignored id" data-labelledby />
          <EuiIcon @type="bell" role="none" data-role />
          <EuiIcon @type="bell" aria-hidden="true" data-hidden />
          <EuiIcon @type="bell" @tabIndex={{0}} @aria-label="Focusable" data-tab />
        </template>
      );
      assert.dom('[data-decorative]').hasAttribute('role', 'presentation');
      assert.dom('[data-decorative]').doesNotHaveAttribute('aria-hidden');
      assert.dom('[data-decorative] title').doesNotExist();
      assert.dom('[data-decorative]').doesNotHaveAttribute('aria-labelledby');

      const titleId = el(this.element, '[data-title] title').id;
      assert.ok(titleId, 'generated title id');
      assert.dom('[data-title]').hasAttribute('role', 'img').hasAttribute('aria-labelledby', titleId);
      assert.dom('[data-title] title').hasText('Bell');
      assert.dom('[data-title-id] title#my-title').exists();
      assert.dom('[data-title-id]').hasAttribute('aria-labelledby', 'my-title');

      assert.dom('[data-label]').hasAttribute('role', 'img').hasAttribute('aria-label', 'Alerts');
      assert.dom('[data-label]').doesNotHaveAttribute('aria-labelledby');
      assert.dom('[data-label] title').doesNotExist();
      // upstream keeps the title as a tooltip-like <title>, without labelling
      assert.dom('[data-label-title] title').hasText('Bell').doesNotHaveAttribute('id');
      assert.dom('[data-label-title]').doesNotHaveAttribute('aria-labelledby');

      assert.dom('[data-labelledby]').hasAttribute('aria-labelledby', 'ext').hasAttribute('role', 'img');
      assert.dom('[data-role]').hasAttribute('role', 'none', 'caller role wins');
      assert.dom('[data-hidden]').hasAttribute('aria-hidden', 'true');
      assert.dom('[data-tab]').hasAttribute('tabindex', '0');
    });

    test('images: role, alt and the same upstream sizing', async function (assert) {
      const url =
        'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"></svg>';
      await render(
        <template>
          <EuiIcon @type={{url}} @size="xl" data-img />
          <EuiIcon @type={{url}} @title="Logo" data-img-title />
        </template>
      );
      assert.dom('img[data-img]').hasClass('euiIcon').hasAttribute('role', 'presentation');
      assert.dom('img[data-img]').doesNotHaveAttribute('alt');
      assert.strictEqual(box(el(this.element, '[data-img]')).width, 32);
      assert.dom('img[data-img-title]').hasAttribute('alt', 'Logo').hasAttribute('role', 'img');
    });

    test('size, color, title and classes update without replacing the element', async function (assert) {
      await preloadIcons(['bell']);
      class State {
        @tracked size: 's' | 'xxl' = 's';
        @tracked color = 'primary';
        @tracked title?: string = undefined;
        @tracked classes = 'one';
      }
      const state = new State();
      await render(
        <template>
          <EuiIcon
            @type="bell"
            @size={{state.size}}
            @color={{state.color}}
            @title={{state.title}}
            @iconClasses={{state.classes}}
          />
        </template>
      );
      const svg = el(this.element, 'svg');
      assert.strictEqual(box(svg).width, 12);
      assert.dom(svg).hasClass('one').hasAttribute('role', 'presentation');

      state.size = 'xxl';
      state.color = 'success';
      state.title = 'Ok';
      state.classes = 'two';
      await settled();
      assert.strictEqual(el(this.element, 'svg'), svg, 'same element');
      assert.strictEqual(box(svg).width, 40);
      assert.strictEqual(getComputedStyle(svg).color, rgb(light.colors.textSuccess));
      assert.dom(svg).hasClass('two').doesNotHaveClass('one').hasClass('euiIcon');
      assert.dom(svg).hasAttribute('role', 'img');
      assert.dom('svg title').hasText('Ok');
    });

    test('light/dark follow the nearest provider; siblings stay isolated', async function (assert) {
      class State {
        @tracked mode: EuiColorMode = 'light';
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider @colorMode={{state.mode}}>
            <EuiIcon @type="bell" @color="primary" data-primary />
            <EuiIcon @type="bell" data-default />
            <EuiIcon @type="logoKibana" data-negative />
            <EuiEmotionProvider @colorMode="light">
              <EuiIcon @type="bell" @color="primary" data-fixed />
            </EuiEmotionProvider>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <EuiIcon @type="bell" @color="primary" data-sibling />
          </EuiEmotionProvider>
        </template>
      );
      const svg = el(this.element, '[data-primary]');
      assert.strictEqual(getComputedStyle(svg).color, rgb(light.colors.textPrimary));
      assert.strictEqual(style(this.element, '[data-default]').color, rgb(light.colors.textParagraph));

      state.mode = 'dark';
      await settled();
      assert.strictEqual(el(this.element, '[data-primary]'), svg, 'same element');
      assert.strictEqual(getComputedStyle(svg).color, rgb(dark.colors.textPrimary));
      assert.strictEqual(style(this.element, '[data-default]').color, rgb(dark.colors.textParagraph), 'inherits the dark wrapper');
      assert.strictEqual(
        style(this.element, '[data-negative] .euiIcon__fillNegative').fill,
        rgb(dark.colors.fullShade),
        'fillNegative uses fullShade in dark mode'
      );
      assert.notStrictEqual(rgb(dark.colors.textPrimary), rgb(light.colors.textPrimary));
      assert.strictEqual(style(this.element, '[data-fixed]').color, rgb(light.colors.textPrimary));
      assert.strictEqual(style(this.element, '[data-sibling]').color, rgb(light.colors.textPrimary));
    });

    test('native token overrides (JS objects) reach the icon styles', async function (assert) {
      class State {
        @tracked overrides: EuiBorealisOverrides = {};
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider @borealisOverrides={{state.overrides}}>
            <EuiIcon @type="bell" @size="l" @color="danger" data-icon />
          </EuiEmotionProvider>
          <EuiIcon @type="bell" @size="l" @color="danger" data-outside />
        </template>
      );
      assert.strictEqual(box(el(this.element, '[data-icon]')).width, 24);

      const overrides: EuiBorealisOverrides = {
        size: { l: '30px' },
        colors: { LIGHT: { textDanger: '#123456' } }
      };
      state.overrides = overrides;
      await settled();
      const expected = resolveBorealisTheme('light', overrides).euiTheme;
      assert.strictEqual(expected.size.l, '30px');
      assert.strictEqual(box(el(this.element, '[data-icon]')).width, 30, 'size override');
      assert.strictEqual(style(this.element, '[data-icon]').color, 'rgb(18, 52, 86)', 'color override');
      assert.strictEqual(box(el(this.element, '[data-outside]')).width, 24, 'outside unaffected');
      assert.strictEqual(style(this.element, '[data-outside]').color, rgb(light.colors.textDanger));
    });
  });

  module('EuiIconTip', function () {
    test('renders a focusable, labelled icon in the tooltip anchor', async function (assert) {
      await render(
        <template>
          <EuiIconTip @content="Help" data-default />
          <EuiIconTip @content="Help" @type="alert" @color="danger" @size="l" @ariaLabel="Warning" />
        </template>
      );
      const icons = this.element.querySelectorAll('.euiToolTipAnchor svg.euiIcon');
      assert.strictEqual(icons.length, 2);
      const [first, second] = [...icons];
      assert.dom(first).hasAttribute('tabindex', '0').hasAttribute('role', 'img');
      assert.dom(first).hasAttribute('aria-label', 'Info').hasAttribute('data-icon-type', 'question');
      assert.strictEqual(box(first!).width, 16, 'default icon size m');
      assert.dom(second).hasAttribute('aria-label', 'Warning').hasAttribute('data-icon-type', 'alert');
      assert.strictEqual(box(second!).width, 24);
      assert.strictEqual(getComputedStyle(second!).color, rgb(light.colors.textDanger));
    });
  });

  module('EuiHealth', function () {
    test('text sizes, dot colors and layout follow upstream (14px root)', async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider>
            <EuiHealth @color="success" data-default>Default</EuiHealth>
            <EuiHealth @color="warning" @textSize="xs" data-xs>xs</EuiHealth>
            <EuiHealth @color="danger" @textSize="m" data-m>m</EuiHealth>
            <EuiHealth @color="#ff0000" @textSize="inherit" style="font-size: 20px" data-inherit>i</EuiHealth>
            <EuiHealth @color="subdued" @textSize="s" data-s>s</EuiHealth>
          </EuiEmotionProvider>
        </template>
      );
      const sizes: Record<string, [number, number]> = {
        default: [14, 20],
        xs: [12, 16],
        s: [14, 20],
        m: [16, 24]
      };
      for (const [name, [fontSize, lineHeight]] of Object.entries(sizes)) {
        const css = style(this.element, `[data-${name}]`);
        assert.ok(Math.abs(parseFloat(css.fontSize) - fontSize) < 0.05, `${name} font ${css.fontSize}`);
        assert.ok(Math.abs(parseFloat(css.lineHeight) - lineHeight) < 0.05, `${name} line ${css.lineHeight}`);
        assert.strictEqual(css.display, 'inline-block');
      }
      assert.strictEqual(style(this.element, '[data-inherit]').fontSize, '20px');
      assert.dom('[data-default]').hasClass('euiHealth');
      const dots: Record<string, string> = {
        default: rgb(light.colors.textSuccess),
        xs: rgb(light.colors.textWarning),
        m: rgb(light.colors.textDanger),
        inherit: 'rgb(255, 0, 0)',
        s: rgb(light.colors.textSubdued)
      };
      for (const [name, color] of Object.entries(dots)) {
        assert.strictEqual(style(this.element, `[data-${name}] svg`).color, color, `${name} dot`);
        assert.dom(`[data-${name}] svg`).hasAttribute('data-icon-type', 'dot');
      }
      // upstream EuiFlexGroup gutter xs, centered, no grow
      const group = el(this.element, '[data-default] > .euiFlexGroup');
      assert.strictEqual(getComputedStyle(group).gap, '4px');
      assert.strictEqual(getComputedStyle(group).alignItems, 'center');
      assert.strictEqual(getComputedStyle(group).flexDirection, 'row');
      for (const item of group.children) assert.strictEqual(getComputedStyle(item).flexGrow, '0');
      assert.dom('[data-default]').hasText('Default');
    });

    test('RTL puts the dot at the inline start (right)', async function (assert) {
      await render(
        <template>
          <div dir="ltr"><EuiHealth @color="success" data-ltr>Healthy</EuiHealth></div>
          <div dir="rtl"><EuiHealth @color="success" data-rtl>Healthy</EuiHealth></div>
        </template>
      );
      const positions = (name: string) => {
        const dot = box(el(this.element, `[data-${name}] svg`));
        const text = box(el(this.element, `[data-${name}] .euiFlexItem:last-child`));
        return { dot, text };
      };
      const ltr = positions('ltr');
      const rtl = positions('rtl');
      assert.ok(ltr.dot.right <= ltr.text.left + 0.5, 'ltr: dot before text');
      assert.ok(rtl.dot.left >= rtl.text.right - 0.5, 'rtl: dot after text visually');
    });
  });

  module('EuiToken', function () {
    test('sizes and shapes measure the upstream tokens', async function (assert) {
      const sizes = { xs: 8, s: 16, m: 24, l: 32 };
      const entries = Object.keys(sizes);
      const shapes = ['circle', 'square', 'rectangle'];
      await render(
        <template>
          {{#each entries as |size|}}
            {{#each shapes as |shape|}}
              {{! @glint-expect-error the arg types are unions }}
              <EuiToken @iconType="bolt" @size={{size}} @shape={{shape}} data-size={{size}} data-shape={{shape}} />
            {{/each}}
          {{/each}}
        </template>
      );
      const inline = { xs: 4, s: 4, m: 8, l: 8 };
      for (const [size, px] of Object.entries(sizes)) {
        for (const shape of shapes) {
          const token = el(this.element, `[data-size="${size}"][data-shape="${shape}"]`);
          const css = getComputedStyle(token);
          const label = `${size}/${shape}`;
          assert.strictEqual(css.display, 'inline-flex');
          assert.strictEqual(css.height, `${px}px`, `${label} content height`);
          if (shape === 'rectangle') {
            const pad = inline[size as keyof typeof inline];
            assert.strictEqual(css.boxSizing, 'content-box');
            assert.strictEqual(css.paddingInlineStart, `${pad}px`, `${label} padding`);
            assert.strictEqual(css.paddingInlineEnd, `${pad}px`);
            assert.strictEqual(box(token).width, px + 2 * pad, `${label} measured width`);
            assert.strictEqual(css.paddingTop, size === 'xs' ? '1px' : '0px');
            assert.strictEqual(css.borderTopLeftRadius, size === 'xs' ? '2px' : '4px');
          } else {
            assert.strictEqual(box(token).width, px, `${label} measured width`);
            assert.strictEqual(
              css.borderTopLeftRadius,
              shape === 'circle' ? '50%' : size === 'xs' ? '2px' : '4px',
              `${label} radius`
            );
          }
          // the icon fills the token height
          const icon = token.querySelector('svg')!;
          assert.strictEqual(getComputedStyle(icon).height, `${px}px`, `${label} icon height`);
        }
      }
    });

    test('vis colors × fills match the upstream color math', async function (assert) {
      const colors = [...Array.from({ length: 10 }, (_, i) => `euiColorVis${i}`), 'gray'];
      const fills = ['light', 'dark', 'none'];
      await render(
        <template>
          {{#each colors as |color|}}
            {{#each fills as |fill|}}
              {{! @glint-expect-error the arg types are unions }}
              <EuiToken @iconType="bolt" @color={{color}} @fill={{fill}} data-color={{color}} data-fill={{fill}} />
            {{/each}}
          {{/each}}
        </template>
      );
      const v = vis(light);
      for (const color of colors) {
        const index = color === 'gray' ? undefined : Number(color.slice(-1));
        const iconColor = index === undefined ? light.colors.darkShade : v[color]!;
        const backgroundDark = index === undefined ? light.colors.darkShade : v[color]!;
        const lightText =
          index === undefined
            ? iconColor
            : shade(v[(TOKEN_COLOR_TO_ICON_COLOR_MAP as Record<string, string>)[color]!]!, 0.3);
        const darkText = isColorDark(...hexToRgb(backgroundDark))
          ? light.colors.textGhost
          : light.colors.textInk;
        const css = (fill: string) =>
          style(this.element, `[data-color="${color}"][data-fill="${fill}"]`);

        assert.strictEqual(css('none').color, rgb(iconColor), `${color}/none color`);
        assert.strictEqual(css('none').backgroundColor, TRANSPARENT, `${color}/none background`);
        assert.strictEqual(css('dark').color, rgb(darkText), `${color}/dark text`);
        assert.strictEqual(css('dark').backgroundColor, rgb(backgroundDark), `${color}/dark background`);
        assert.strictEqual(css('light').color, rgb(lightText), `${color}/light text`);
        assert.strictEqual(css('light').backgroundColor, rgb(tint(iconColor, 0.9)), `${color}/light background`);
        assert.ok(
          css('light').boxShadow.includes(rgb(tint(iconColor, 0.2))) &&
            css('light').boxShadow.includes('inset'),
          `${color}/light inset border ${css('light').boxShadow}`
        );
        assert.strictEqual(css('none').boxShadow, 'none');
        // the icon inherits the token color
        assert.strictEqual(
          getComputedStyle(el(this.element, `[data-color="${color}"][data-fill="light"] svg`)).fill,
          css('light').color
        );
      }
    });

    test('presets, custom colors and icon semantics', async function (assert) {
      await render(
        <template>
          <EuiToken @iconType="tokenString" @title="String field" data-preset />
          <EuiToken @iconType="tokenRepo" data-repo />
          <EuiToken @iconType="tokenDenseVector" data-dense />
          <EuiToken @iconType="bolt" data-plain />
          <EuiToken @iconType="bolt" @color="#000000" data-custom-dark />
          <EuiToken @iconType="bolt" @color="#ffffff" @fill="light" data-custom-light />
          <EuiToken @iconType="bolt" @color="#ff0000" @fill="none" style="opacity: 0.5" data-custom-none />
          <EuiToken @iconType="bolt" @aria-label="Bolt" @aria-describedby="x" data-label />
        </template>
      );
      const preset = style(this.element, '[data-preset]');
      assert.strictEqual(preset.borderTopLeftRadius, '4px', 'tokenString is square');
      assert.strictEqual(preset.backgroundColor, rgb(tint(vis(light)['euiColorVis2']!, 0.9)), 'tokenString is euiColorVis2/light (upstream 123 preset)');
      assert.dom('[data-preset] svg').hasAttribute('role', 'img').hasAttribute('data-icon-type', 'tokenString');
      assert.dom('[data-preset] svg title').hasText('String field');
      assert.strictEqual(style(this.element, '[data-preset] svg').width, '16px', 'token icon one size up (m)');
      // upstream 123 TOKEN_MAP: tokenRepo is a light euiColorVis2 square
      // (was a dark euiColorVis1 rectangle); no fill presets any more
      assert.strictEqual(
        style(this.element, '[data-repo]').backgroundColor,
        rgb(tint(vis(light)['euiColorVis2']!, 0.9))
      );
      assert.strictEqual(style(this.element, '[data-repo]').borderTopLeftRadius, '4px', 'square preset');
      // our renamed-upstream asset keeps its preset through the alias
      assert.strictEqual(
        style(this.element, '[data-dense]').backgroundColor,
        rgb(tint(vis(light)['euiColorVis8']!, 0.9)),
        'tokenDenseVector uses the tokenVectorDense preset'
      );
      const plain = style(this.element, '[data-plain]');
      assert.strictEqual(plain.borderTopLeftRadius, '50%', 'circle default');
      assert.strictEqual(plain.backgroundColor, rgb(tint(light.colors.darkShade, 0.9)), 'gray default');
      assert.dom('[data-plain] svg').hasAttribute('role', 'presentation');

      assert.strictEqual(style(this.element, '[data-custom-dark]').backgroundColor, 'rgb(0, 0, 0)');
      assert.strictEqual(style(this.element, '[data-custom-dark]').color, 'rgb(255, 255, 255)');
      assert.strictEqual(style(this.element, '[data-custom-light]').backgroundColor, 'rgb(255, 255, 255)', 'custom forces dark fill');
      assert.strictEqual(style(this.element, '[data-custom-light]').color, 'rgb(0, 0, 0)');
      assert.strictEqual(style(this.element, '[data-custom-none]').color, 'rgb(255, 0, 0)');
      assert.strictEqual(style(this.element, '[data-custom-none]').backgroundColor, TRANSPARENT);
      assert.strictEqual(style(this.element, '[data-custom-none]').opacity, '0.5', 'caller style kept');
      assert.dom('[data-label] svg').hasAttribute('aria-label', 'Bolt').hasAttribute('aria-describedby', 'x');
      assert.dom('[data-label]').hasClass('euiToken');
    });

    test('dark mode, contrast modes, overrides and reactive args', async function (assert) {
      class State {
        @tracked mode: EuiColorMode = 'light';
        @tracked contrast: EuiBorealisHighContrastMode = false;
        @tracked overrides: EuiBorealisOverrides = {};
        @tracked size: 's' | 'l' = 's';
        @tracked fill: 'light' | 'dark' = 'light';
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider
            @colorMode={{state.mode}}
            @highContrastMode={{state.contrast}}
            @borealisOverrides={{state.overrides}}
          >
            <EuiToken @iconType="bolt" @size={{state.size}} @fill={{state.fill}} @shape="square" data-token />
          </EuiEmotionProvider>
          <EuiToken @iconType="bolt" data-sibling />
        </template>
      );
      const token = el(this.element, '[data-token]');
      const gray = light.colors.darkShade;
      assert.strictEqual(getComputedStyle(token).backgroundColor, rgb(tint(gray, 0.9)));

      state.mode = 'dark';
      await settled();
      assert.strictEqual(el(this.element, '[data-token]'), token, 'same element');
      assert.strictEqual(getComputedStyle(token).backgroundColor, rgb(shade(dark.colors.darkShade, 0.9)), 'dark mode shades');
      assert.ok(getComputedStyle(token).boxShadow.includes(rgb(shade(dark.colors.darkShade, 0.6))));
      assert.strictEqual(
        style(this.element, '[data-sibling]').backgroundColor,
        rgb(tint(gray, 0.9)),
        'sibling stays light'
      );

      state.contrast = 'preferred';
      await settled();
      assert.ok(getComputedStyle(token).boxShadow.includes(rgb(dark.colors.darkShade)), 'preferred: full-color border');
      state.contrast = 'forced';
      await settled();
      assert.strictEqual(getComputedStyle(token).borderTopStyle, 'solid', 'forced: real border');
      assert.strictEqual(getComputedStyle(token).boxShadow, 'none');

      state.contrast = false;
      state.mode = 'light';
      state.overrides = { border: { radius: { inline: '6px' } }, colors: { LIGHT: { darkShade: '#336699' } } };
      state.size = 'l';
      state.fill = 'dark';
      await settled();
      assert.strictEqual(el(this.element, '[data-token]'), token, 'same element');
      assert.strictEqual(getComputedStyle(token).borderTopLeftRadius, '6px', 'radius override');
      assert.strictEqual(getComputedStyle(token).backgroundColor, 'rgb(51, 102, 153)', 'darkShade override');
      assert.strictEqual(box(token).width, 32, 'reactive size');
    });
  });

  module('EuiAvatar', function () {
    test('sizes, types, casing and the name-picked vis color', async function (assert) {
      await render(
        <template>
          <EuiAvatar @name="jane doe" @size="s" data-s />
          <EuiAvatar @name="jane doe" data-m />
          <EuiAvatar @name="jane doe" @size="l" data-l />
          <EuiAvatar @name="jane doe" @size="xl" @type="space" data-xl />
          <EuiAvatar @name="jane doe" @type="space" @casing="capitalize" data-capitalize />
          <EuiAvatar @name="Jane Doe" @casing="lowercase" @initialsLength={{1}} data-lower />
        </template>
      );
      const sizes: Record<string, [number, string]> = {
        s: [24, '12px'],
        m: [32, '14.4px'],
        l: [40, '19.2px'],
        xl: [64, '25.6px']
      };
      for (const [size, [px, font]] of Object.entries(sizes)) {
        const avatar = el(this.element, `[data-${size}]`);
        const css = getComputedStyle(avatar);
        assert.deepEqual([box(avatar).width, box(avatar).height], [px, px], `${size} measures ${px}px`);
        assert.strictEqual(css.fontSize, font, `${size} font`);
        assert.strictEqual(css.display, 'inline-flex');
        assert.strictEqual(css.alignItems, 'center');
        assert.strictEqual(css.justifyContent, 'center');
        assert.strictEqual(css.overflow, 'hidden');
        assert.strictEqual(css.fontWeight, String(light.font.weight.medium));
      }
      assert.strictEqual(style(this.element, '[data-m]').borderTopLeftRadius, '50%', 'user circle');
      assert.strictEqual(style(this.element, '[data-xl]').borderTopLeftRadius, light.border.radius.control, 'space radius');
      assert.strictEqual(style(this.element, '[data-m]').textTransform, 'uppercase', 'user default casing');
      assert.strictEqual(style(this.element, '[data-xl]').textTransform, 'none', 'space default casing');
      assert.strictEqual(style(this.element, '[data-capitalize]').textTransform, 'capitalize');
      assert.strictEqual(style(this.element, '[data-lower]').textTransform, 'lowercase');
      assert.dom('[data-lower] span').hasText('J');
      assert.dom('[data-m] span[aria-hidden="true"]').hasText('jd');
      // name length 8 → euiColorVis8, with a contrasting text color
      const color = vis(light)['euiColorVis8']!;
      assert.strictEqual(style(this.element, '[data-m]').backgroundColor, rgb(color));
      assert.strictEqual(
        style(this.element, '[data-m]').color,
        isColorDark(...hexToRgb(color)) ? 'rgb(255, 255, 255)' : 'rgb(0, 0, 0)'
      );
      assert.dom('[data-m]').hasAttribute('role', 'img').hasAttribute('aria-label', 'jane doe').doesNotHaveAttribute('title');
    });

    test('named colors, images, icons and disabled', async function (assert) {
      const image = 'data:image/gif;base64,R0lGODlhAQABAAAAACw=';
      await render(
        <template>
          <EuiAvatar @name="A" @color="plain" data-plain />
          <EuiAvatar @name="A" @color="subdued" data-subdued />
          <EuiAvatar @name="A" @color={{null}} data-null />
          <EuiAvatar @name="A" @color="#000000" data-hex />
          <EuiAvatar @name="A" @imageUrl={{image}} style="opacity: 0.5" data-image />
          <EuiAvatar @name="Bot" @color="#000000" @iconType="bell" data-icon />
          <EuiAvatar @name="Bot" @iconType="apmApp" @iconColor={{null}} @color="plain" data-app />
          <EuiAvatar @name="Bot" @iconType="bell" @iconColor="danger" @iconSize="s" data-icon-color />
          <EuiAvatar @name="A" @isDisabled={{true}} data-disabled />
        </template>
      );
      assert.strictEqual(style(this.element, '[data-plain]').backgroundColor, rgb(light.colors.emptyShade));
      assert.strictEqual(style(this.element, '[data-subdued]').backgroundColor, rgb(light.colors.lightestShade));
      assert.strictEqual(style(this.element, '[data-null]').backgroundColor, rgb(light.colors.lightShade));
      assert.strictEqual(style(this.element, '[data-hex]').backgroundColor, 'rgb(0, 0, 0)');
      assert.strictEqual(style(this.element, '[data-hex]').color, 'rgb(255, 255, 255)');
      const imageCss = style(this.element, '[data-image]');
      assert.ok(imageCss.backgroundImage.startsWith('url('), 'background image');
      assert.strictEqual(imageCss.backgroundSize, 'cover');
      assert.strictEqual(imageCss.opacity, '0.5', 'caller style kept');
      assert.dom('[data-image] span').doesNotExist();

      assert.dom('[data-icon] svg.euiAvatar__icon').hasAttribute('aria-hidden', 'true');
      assert.strictEqual(style(this.element, '[data-icon] svg').color, 'rgb(255, 255, 255)', 'icon takes the text color');
      assert.strictEqual(box(el(this.element, '[data-icon] svg')).width, 16, 'icon size follows @size (m)');
      assert.strictEqual(
        style(this.element, '[data-app] svg .euiIcon__fillSecondary').fill,
        rgb(light.colors.primary),
        '@iconColor={{null}} keeps app colors'
      );
      assert.strictEqual(style(this.element, '[data-icon-color] svg').color, rgb(light.colors.textDanger));
      assert.strictEqual(box(el(this.element, '[data-icon-color] svg')).width, 12);

      const disabled = style(this.element, '[data-disabled]');
      assert.strictEqual(disabled.cursor, 'not-allowed');
      assert.strictEqual(disabled.filter, 'grayscale(1)');
      assert.dom('[data-disabled]').hasAttribute('role', 'presentation').doesNotHaveAttribute('aria-label');
    });

    test('providers: dark mode, forced contrast and reactive args', async function (assert) {
      class State {
        @tracked mode: EuiColorMode = 'light';
        @tracked contrast: EuiBorealisHighContrastMode = false;
        @tracked size: 's' | 'xl' = 's';
        @tracked type: 'user' | 'space' = 'user';
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider @colorMode={{state.mode}} @highContrastMode={{state.contrast}}>
            <EuiAvatar @name="Bot" @color={{null}} @size={{state.size}} @type={{state.type}} data-avatar />
            <EuiAvatar @name="Bot" @iconType="bell" data-icon />
          </EuiEmotionProvider>
          <EuiAvatar @name="Bot" @color={{null}} data-sibling />
        </template>
      );
      const avatar = el(this.element, '[data-avatar]');
      assert.strictEqual(getComputedStyle(avatar).backgroundColor, rgb(light.colors.lightShade));

      state.mode = 'dark';
      state.size = 'xl';
      state.type = 'space';
      await settled();
      assert.strictEqual(el(this.element, '[data-avatar]'), avatar, 'same element');
      assert.strictEqual(getComputedStyle(avatar).backgroundColor, rgb(dark.colors.lightShade));
      assert.strictEqual(box(avatar).width, 64);
      assert.strictEqual(getComputedStyle(avatar).borderTopLeftRadius, dark.border.radius.control);
      assert.strictEqual(style(this.element, '[data-sibling]').backgroundColor, rgb(light.colors.lightShade));

      state.contrast = 'forced';
      await settled();
      assert.strictEqual(getComputedStyle(avatar).borderTopStyle, 'solid', 'forced: border');
      assert.strictEqual(box(avatar).width, 64, 'border-box: border does not grow it');
      const forced = resolveBorealisTheme('dark', {}, 'forced').euiTheme;
      assert.strictEqual(style(this.element, '[data-icon] svg').color, rgb(forced.colors.fullShade), 'forced: icon fullShade');
    });
  });

  module('EuiBeacon', function () {
    test('sizes, colors and the pulse follow upstream', async function (assert) {
      const colors = ['subdued', 'primary', 'success', 'accent', 'danger', 'warning'] as const;
      const tokens: Record<string, string> = {
        subdued: light.colors.textSubdued,
        primary: light.colors.primary,
        success: light.colors.success,
        accent: light.colors.accent,
        danger: light.colors.danger,
        warning: light.colors.warning
      };
      await render(
        <template>
          <EuiBeacon data-default style="opacity: 0.9" />
          <EuiBeacon @size={{20}} data-big />
          {{#each colors as |color|}}
            <EuiBeacon @color={{color}} data-color={{color}} />
          {{/each}}
        </template>
      );
      const beacon = el(this.element, '[data-default]');
      const css = getComputedStyle(beacon);
      assert.deepEqual([box(beacon).width, box(beacon).height], [12, 12]);
      assert.strictEqual(css.borderTopLeftRadius, '50%');
      assert.strictEqual(css.position, 'relative');
      assert.strictEqual(css.opacity, '0.9', 'caller style kept');
      assert.strictEqual(css.backgroundColor, rgb(light.colors.success), 'success by default');
      assert.deepEqual([box(el(this.element, '[data-big]')).width, box(el(this.element, '[data-big]')).height], [20, 20]);
      const before = getComputedStyle(beacon, '::before');
      const after = getComputedStyle(beacon, '::after');
      assert.strictEqual(before.position, 'absolute');
      // transform/opacity are animated (the pulse keyframes), so only the
      // animation itself is asserted
      assert.ok(before.animationName.startsWith('animation-'), 'large pulse');
      assert.strictEqual(before.animationDuration, '2.5s');
      assert.strictEqual(after.animationDelay, '0.25s', 'small pulse is delayed');
      for (const color of colors) {
        const node = el(this.element, `[data-color="${color}"]`);
        assert.strictEqual(getComputedStyle(node).backgroundColor, rgb(tokens[color]!), `${color} dot`);
        assert.ok(getComputedStyle(node, '::before').boxShadow.includes(rgb(tokens[color]!)), `${color} ring`);
      }
    });

    test('dark mode, forced contrast and reactive args', async function (assert) {
      class State {
        @tracked mode: EuiColorMode = 'light';
        @tracked contrast: EuiBorealisHighContrastMode = false;
        @tracked color: 'primary' | 'danger' = 'primary';
        @tracked size = 12;
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider @colorMode={{state.mode}} @highContrastMode={{state.contrast}}>
            <EuiBeacon @color={{state.color}} @size={{state.size}} data-beacon />
          </EuiEmotionProvider>
          <EuiBeacon @color="primary" data-sibling />
        </template>
      );
      const beacon = el(this.element, '[data-beacon]');
      state.mode = 'dark';
      state.color = 'danger';
      state.size = 30;
      await settled();
      assert.strictEqual(el(this.element, '[data-beacon]'), beacon, 'same element');
      assert.strictEqual(getComputedStyle(beacon).backgroundColor, rgb(dark.colors.danger));
      assert.strictEqual(box(beacon).width, 30);
      assert.strictEqual(style(this.element, '[data-sibling]').backgroundColor, rgb(light.colors.primary));
      state.contrast = 'forced';
      await settled();
      assert.strictEqual(getComputedStyle(beacon).forcedColorAdjust, 'none', 'forced: keeps its colors');
    });
  });
});
