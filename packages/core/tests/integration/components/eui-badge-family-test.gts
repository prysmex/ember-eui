import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  click,
  clearRender,
  focus,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiBadge from '#src/components/eui-badge.gts';
import EuiBadgeGroup from '#src/components/eui-badge-group.gts';
import EuiBetaBadge from '#src/components/eui-beta-badge.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiNotificationBadge from '#src/components/eui-notification-badge.gts';
import {
  euiBadgeColors,
  getTextColor
} from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiBadgeNamedColor } from '#src/components/eui-badge.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

interface BadgeColorValues {
  color: string;
  backgroundColor: string;
  borderColor?: string;
}
interface BadgeColorSet {
  fill: Record<string, BadgeColorValues>;
  base: Record<string, BadgeColorValues>;
  disabled: BadgeColorValues;
  hollow: BadgeColorValues;
  subdued: BadgeColorValues;
  accentText: BadgeColorValues;
}

const lightContext = resolveBorealisTheme('light');
const darkContext = resolveBorealisTheme('dark');
const light = lightContext.euiTheme;
const lightColors = euiBadgeColors(lightContext) as BadgeColorSet;
const darkColors = euiBadgeColors(darkContext) as BadgeColorSet;

const NAMED: EuiBadgeNamedColor[] = [
  'default',
  'primary',
  'accent',
  'neutral',
  'success',
  'warning',
  'risk',
  'danger'
];

function style(root: Element, selector: string) {
  const element = root.querySelector(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return getComputedStyle(element);
}

function el(root: Element, selector: string) {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function channels(color: string): [number, number, number] {
  const [r, g, b] = rgb(color).match(/[\d.]+/g)!.map(Number);
  return [r!, g!, b!];
}

/** WCAG 2 contrast ratio between two opaque colors. */
function contrast(a: string, b: string) {
  const luminance = (color: string) => {
    const [r, g, b] = channels(color).map((value) => {
      const c = value / 255;
      return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
    });
    return 0.2126 * r! + 0.7152 * g! + 0.0722 * b!;
  };
  const [high, low] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (high! + 0.05) / (low! + 0.05);
}

/** `#ember-testing` is scaled down; undo it so boxes are in CSS pixels. */
function scale() {
  const container = document.querySelector<HTMLElement>('#ember-testing');
  if (!container?.offsetWidth) return 1;
  return container.getBoundingClientRect().width / container.offsetWidth;
}

function box(root: Element, selector: string) {
  const rect = el(root, selector).getBoundingClientRect();
  const factor = scale();
  return {
    left: rect.left / factor,
    right: rect.right / factor,
    width: Math.round((rect.width / factor) * 100) / 100,
    height: Math.round((rect.height / factor) * 100) / 100
  };
}

/** Upstream font sizes are rem based; EUI apps set a 14px root (`s`). */
function remPx(rem: number) {
  return rem * parseFloat(getComputedStyle(document.documentElement).fontSize);
}

/** The `xs` scale step: 12px in a 14px-root EUI app. */
function assertXsFont(assert: Assert, fontSize: string, label: string) {
  assert.true(
    Math.abs(parseFloat(fontSize) - remPx(12 / 14)) < 0.05,
    `${label} uses the xs font scale (${fontSize})`
  );
}

/** Finish CSS transitions (notification badges animate every property). */
function finishTransitions() {
  document.getAnimations().forEach((animation) => animation.finish());
}

/** Upstream rings use `outline-style: auto` only for keyboard modality. */
function expectedOutline(element: Element) {
  return element.matches(':focus-visible') ? 'auto' : 'none';
}

module('Integration | Component | Borealis badge family', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiBadge renders every named color, base and fill, from the upstream helpers', async function (assert) {
    await render(
      <template>
        {{#each NAMED as |color|}}
          <EuiBadge @color={{color}} data-base={{color}}>{{color}}</EuiBadge>
          <EuiBadge
            @color={{color}}
            @fill={{true}}
            data-fill={{color}}
          >{{color}}</EuiBadge>
        {{/each}}
        <EuiBadge @color="hollow" data-hollow>hollow</EuiBadge>
        <EuiBadge data-implicit>implicit</EuiBadge>
      </template>
    );
    for (const color of NAMED) {
      const base = style(this.element, `[data-base="${color}"]`);
      const fill = style(this.element, `[data-fill="${color}"]`);
      assert.strictEqual(
        base.color,
        rgb(lightColors.base[color]!.color),
        `${color} base text`
      );
      assert.strictEqual(
        base.backgroundColor,
        rgb(lightColors.base[color]!.backgroundColor),
        `${color} base background`
      );
      assert.strictEqual(
        fill.color,
        rgb(lightColors.fill[color]!.color),
        `${color} fill text`
      );
      assert.strictEqual(
        fill.backgroundColor,
        rgb(lightColors.fill[color]!.backgroundColor),
        `${color} fill background`
      );
      assert.true(
        contrast(fill.color, fill.backgroundColor) >= 4.5 ||
          contrast(base.color, base.backgroundColor) >= 4.5,
        `${color} keeps readable text`
      );
    }
    const hollow = style(this.element, '[data-hollow]');
    assert.strictEqual(hollow.color, rgb(lightColors.hollow.color));
    assert.strictEqual(
      hollow.backgroundColor,
      rgb(lightColors.hollow.backgroundColor)
    );
    assert.strictEqual(
      hollow.borderTopColor,
      rgb(lightColors.hollow.borderColor!),
      'hollow keeps a visible border'
    );
    const implicit = style(this.element, '[data-implicit]');
    const defaults = style(this.element, '[data-base="default"]');
    assert.strictEqual(implicit.backgroundColor, defaults.backgroundColor);
    assert.strictEqual(implicit.color, defaults.color, 'default is not filled');

    // Shared Borealis badge shape.
    assertXsFont(assert, implicit.fontSize, 'badge');
    assert.strictEqual(implicit.lineHeight, '18px');
    assert.strictEqual(implicit.fontWeight, String(light.font.weight.medium));
    assert.strictEqual(implicit.borderTopLeftRadius, light.size.l);
    assert.strictEqual(implicit.paddingInlineStart, '7px');
    assert.strictEqual(implicit.whiteSpace, 'nowrap');
    assert.strictEqual(implicit.verticalAlign, 'middle');
    assert.strictEqual(implicit.boxSizing, 'border-box');
    assert.true(implicit.fontFamily.includes('Inter'), 'Borealis font');
    assert.strictEqual(
      box(this.element, '[data-implicit]').height,
      20,
      '16px line + borders'
    );
    assert
      .dom('.euiBadge--hollow, .euiBadge--iconLeft, .euiBadge-isClickable')
      .doesNotExist('no legacy modifier classes');
  });

  test('custom colors pick the contrasting text color; invalid colors fall back', async function (assert) {
    await render(
      <template>
        <EuiBadge @color="#FFEB3B" data-light-hex>Light</EuiBadge>
        <EuiBadge @color="#1A237E" data-dark-hex>Dark</EuiBadge>
        <EuiBadge @color="rgb(0, 128, 0)" data-rgb>Rgb</EuiBadge>
        <EuiBadge
          @color="#ff0000"
          style="margin-top: 3px"
          data-styled
        >Styled</EuiBadge>
        <EuiBadge @color="not-a-color" data-invalid>Invalid</EuiBadge>
        <EuiBadge
          @color="#1A237E"
          @isDisabled={{true}}
          data-disabled-custom
        >Off</EuiBadge>
        <EuiBadge
          @color="#FFEB3B"
          @onClick={{noop}}
          data-custom-button
        >Click</EuiBadge>
      </template>
    );
    const lightHex = style(this.element, '[data-light-hex]');
    assert.strictEqual(lightHex.backgroundColor, 'rgb(255, 235, 59)');
    assert.strictEqual(
      lightHex.color,
      rgb(getTextColor(lightContext, '#FFEB3B') as string)
    );
    assert.strictEqual(lightHex.color, rgb(light.colors.textInk), 'ink on light');
    const darkHex = style(this.element, '[data-dark-hex]');
    assert.strictEqual(darkHex.backgroundColor, 'rgb(26, 35, 126)');
    assert.strictEqual(darkHex.color, rgb(light.colors.textGhost), 'ghost on dark');
    for (const selector of ['[data-light-hex]', '[data-dark-hex]', '[data-rgb]']) {
      const computed = style(this.element, selector);
      assert.true(
        contrast(computed.color, computed.backgroundColor) >= 4.5,
        `${selector} meets WCAG AA`
      );
    }
    assert.strictEqual(
      style(this.element, '[data-rgb]').backgroundColor,
      'rgb(0, 128, 0)'
    );
    const styled = el(this.element, '[data-styled]');
    assert.strictEqual(getComputedStyle(styled).marginTop, '3px');
    assert.strictEqual(getComputedStyle(styled).backgroundColor, 'rgb(255, 0, 0)');
    assert.false(
      styled.style.getPropertyValue('--euiBadgeBackgroundColor') !== '',
      'custom color variables live in a class, not the style attribute'
    );

    const invalid = style(this.element, '[data-invalid]');
    assert.strictEqual(
      invalid.backgroundColor,
      rgb(lightColors.fill.default!.backgroundColor),
      'invalid colors fall back to the default badge colors'
    );
    assert.strictEqual(invalid.color, rgb(lightColors.fill.default!.color));

    const disabled = style(this.element, '[data-disabled-custom]');
    assert.strictEqual(
      disabled.backgroundColor,
      rgb(lightColors.disabled.backgroundColor),
      'disabled overrides custom colors'
    );
    assert.strictEqual(disabled.color, rgb(lightColors.disabled.color));

    const button = el(this.element, '[data-custom-button]');
    assert.strictEqual(button.tagName, 'BUTTON');
    assert.strictEqual(getComputedStyle(button).backgroundColor, 'rgb(255, 235, 59)');
    await focus(button);
    assert.strictEqual(
      getComputedStyle(button).outlineStyle,
      expectedOutline(button),
      'custom clickable badges use the focus ring'
    );
    assert.strictEqual(getComputedStyle(button).outlineOffset, '3px');
  });

  test('icons sit on either logical side, at the upstream size, also in RTL', async function (assert) {
    await render(
      <template>
        <div dir="ltr">
          <EuiBadge @iconType="check" data-ltr-left>Left</EuiBadge>
          <EuiBadge
            @iconType="check"
            @iconSide="right"
            data-ltr-right
          >Right</EuiBadge>
          <EuiBadge @iconType="check" data-icon-only />
        </div>
        <div dir="rtl">
          <EuiBadge @iconType="check" data-rtl-left>Left</EuiBadge>
          <EuiBadge
            @iconType="check"
            @iconSide="right"
            data-rtl-right
          >Right</EuiBadge>
        </div>
      </template>
    );
    
    const sides = (selector: string) => {
      const icon = box(this.element, `${selector} .euiBadge__icon`);
      const text = box(this.element, `${selector} .euiBadge__text`);
      return { icon, text };
    };
    const ltrLeft = sides('[data-ltr-left]');
    assert.true(ltrLeft.icon.right <= ltrLeft.text.left, 'ltr left: icon first');
    const ltrRight = sides('[data-ltr-right]');
    assert.true(ltrRight.icon.left >= ltrRight.text.right, 'ltr right: icon last');
    const rtlLeft = sides('[data-rtl-left]');
    assert.true(rtlLeft.icon.left >= rtlLeft.text.right, 'rtl left = start: icon on the right');
    const rtlRight = sides('[data-rtl-right]');
    assert.true(rtlRight.icon.right <= rtlRight.text.left, 'rtl right = end: icon on the left');

    const icon = style(this.element, '[data-ltr-left] .euiBadge__icon');
    assert.strictEqual(icon.width, light.size.m, 'icon size s is 12px');
    assert.strictEqual(icon.height, light.size.m);
    assert.strictEqual(icon.marginInlineEnd, light.size.xxs, 'gap on the text side');
    assert.strictEqual(
      style(this.element, '[data-ltr-right] .euiBadge__icon').marginInlineStart,
      light.size.xxs
    );
    assert.strictEqual(
      icon.fill,
      style(this.element, '[data-ltr-left]').color,
      'icon inherits the badge text color'
    );
    assert.dom('[data-ltr-left] .euiBadge__content > *:first-child').hasClass('euiBadge__icon');
    assert.dom('[data-ltr-right] .euiBadge__content > *:last-child').hasClass('euiBadge__icon');

    const iconOnly = style(this.element, '[data-icon-only]');
    assert.strictEqual(iconOnly.paddingInlineStart, '3px', 'icon-only padding');
    assert.dom('[data-icon-only] .euiBadge__text').doesNotExist();
    assert.strictEqual(
      style(this.element, '[data-icon-only] .euiBadge__icon').marginInlineEnd,
      '0px',
      'a lone icon has no gap'
    );
    assert.strictEqual(box(this.element, '[data-icon-only]').height, 20);
  });

  test('onClick, href and plain badges keep native semantics; disabled blocks them', async function (assert) {
    const calls: string[] = [];
    const press = () => calls.push('badge');
    const pressIcon = () => calls.push('icon');
    await render(
      <template>
        <EuiBadge
          @onClick={{press}}
          @onClickAriaLabel="Filter by bug"
          data-button
        >Bug</EuiBadge>
        <EuiBadge @href="#docs" data-link>Docs</EuiBadge>
        <EuiBadge
          @href="https://example.com"
          @target="_blank"
          @rel="nofollow"
          data-external
        >External</EuiBadge>
        <EuiBadge data-plain>Plain</EuiBadge>
        <EuiBadge
          @href="#docs"
          @isDisabled={{true}}
          @onClick={{press}}
          data-disabled-link
        >Off</EuiBadge>
        {{! template-lint-disable no-unsafe-url }}
        <EuiBadge @href="javascript:alert(1)" data-script>Script</EuiBadge>
        <EuiBadge
          @iconType="cross"
          @iconOnClick={{pressIcon}}
          @iconOnClickAriaLabel="Remove"
          @closeButtonProps={{closeProps}}
          data-removable
        >Removable</EuiBadge>
        <EuiBadge
          @iconType="cross"
          @iconSide="right"
          @iconOnClick={{pressIcon}}
          @iconOnClickAriaLabel="Remove"
          @onClick={{press}}
          @onClickAriaLabel="Open"
          class="both"
          data-both
        >Both</EuiBadge>
        <EuiBadge
          @iconType="cross"
          @iconOnClick={{pressIcon}}
          @iconOnClickAriaLabel="Remove"
          @href="#both"
          class="both-link"
          data-both-link
        >Both link</EuiBadge>
      </template>
    );
    

    assert
      .dom('[data-button]')
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasAttribute('aria-label', 'Filter by bug')
      .hasAttribute('title', 'Bug')
      .isNotDisabled();
    assert.strictEqual(
      style(this.element, '[data-button] .euiBadge__text').cursor,
      'pointer'
    );
    await click('[data-button]');
    assert.deepEqual(calls, ['badge']);

    assert
      .dom('[data-link]')
      .hasTagName('a')
      .hasAttribute('href', '#docs')
      .hasAttribute('rel', 'noreferrer');
    assert.strictEqual(style(this.element, '[data-link]').textDecorationLine, 'none');
    assert
      .dom('[data-external]')
      .hasAttribute('target', '_blank')
      .hasAttribute('rel', 'nofollow noopener noreferrer');
    assert.dom('[data-plain]').hasTagName('span').hasAttribute('title', 'Plain');
    assert.strictEqual(style(this.element, '[data-plain] .euiBadge__text').cursor, 'auto');

    assert
      .dom('[data-disabled-link]')
      .hasTagName('button', 'links cannot be disabled, so it is a button')
      .isDisabled()
      .doesNotHaveAttribute('href');
    const disabled = style(this.element, '[data-disabled-link]');
    assert.strictEqual(disabled.backgroundColor, rgb(lightColors.disabled.backgroundColor));
    assert.strictEqual(disabled.color, rgb(lightColors.disabled.color));
    assert.strictEqual(disabled.cursor, 'auto', 'upstream: disabled badges inherit the cursor');
    calls.length = 0;
    el(this.element, '[data-disabled-link]').click();
    assert.deepEqual(calls, [], 'disabled badge does not fire');
    assert
      .dom('[data-script]')
      .hasTagName('button', 'javascript: hrefs are disabled, as upstream')
      .isDisabled();

    assert.dom('[data-removable]').hasTagName('span');
    assert
      .dom('[data-removable] .euiBadge__iconButton')
      .hasTagName('button')
      .hasAttribute('aria-label', 'Remove')
      .hasAttribute('title', 'Remove')
      .hasAttribute('tabindex', '-1')
      .hasAttribute('data-selected-index', '2');
    assert.dom('[data-removable] .euiBadge__icon').hasClass('extra-icon-class');
    const iconButton = style(this.element, '[data-removable] .euiBadge__iconButton');
    assert.strictEqual(iconButton.fontSize, '0px');
    assert.strictEqual(iconButton.backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.strictEqual(iconButton.borderTopStyle, 'none');
    assert.strictEqual(iconButton.marginInlineEnd, light.size.xxs);
    await click('[data-removable] .euiBadge__iconButton');
    assert.deepEqual(calls, ['icon']);

    // upstream: className on the outer span, the other props on the text button
    assert.dom('.both').hasTagName('span').doesNotHaveAttribute('data-both');
    assert
      .dom('.both .euiBadge__childButton')
      .hasTagName('button')
      .hasAttribute('data-both')
      .hasAttribute('aria-label', 'Open')
      .hasAttribute('title', 'Both');
    assert.dom('.both .euiBadge__content > :last-child').hasClass('euiBadge__iconButton');
    calls.length = 0;
    await click('.both .euiBadge__childButton');
    await click('.both .euiBadge__iconButton');
    assert.deepEqual(calls, ['badge', 'icon'], 'text and icon act separately');
    assert
      .dom('.both-link a.euiBadge__childButton')
      .hasAttribute('data-both-link')
      .hasAttribute('href', '#both')
      .hasAttribute('rel', 'noreferrer');
    const child = style(this.element, '.both .euiBadge__childButton');
    assert.strictEqual(child.backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.strictEqual(child.fontWeight, String(light.font.weight.medium));
    assert.strictEqual(child.color, style(this.element, '.both').color);
  });

  // upstream badge.tsx: with iconOnClick and onClick/href, `className` and
  // `style` stay on the outer span; `...rest` goes on the text button/link
  test('with both handlers, attributes go on the text button; class and style stay on the root', async function (assert) {
    class State {
      @tracked subj = 'first';
    }
    const state = new State();
    await render(
      <template>
        <EuiBadge
          @iconType="cross"
          @iconOnClick={{noop}}
          @iconOnClickAriaLabel="Remove"
          @onClick={{noop}}
          @onClickAriaLabel="Open"
          class="mine"
          style="margin-top: 3px"
          data-test-subj={{state.subj}}
          aria-describedby="help"
          id="badge-text"
        >Both</EuiBadge>
        <EuiBadge @iconType="cross" @iconOnClick={{noop}} @iconOnClickAriaLabel="Remove" data-test-subj="icon-only" class="icon-only">Icon only</EuiBadge>
      </template>
    );

    assert.dom('.mine').hasTagName('span').hasStyle({ marginTop: '3px' });
    for (const name of ['data-test-subj', 'aria-describedby', 'id']) {
      assert.dom('.mine').doesNotHaveAttribute(name);
    }
    assert
      .dom('.mine .euiBadge__childButton')
      .hasAttribute('data-test-subj', 'first')
      .hasAttribute('aria-describedby', 'help')
      .hasAttribute('id', 'badge-text')
      .doesNotHaveClass('mine');
    state.subj = 'second';
    await settled();
    await waitUntil(() => document.querySelector('.mine .euiBadge__childButton')?.getAttribute('data-test-subj') === 'second');
    assert.dom('.mine').doesNotHaveAttribute('data-test-subj', 'an update is moved too');
    assert.dom('.icon-only').hasAttribute('data-test-subj', 'icon-only', 'iconOnClick alone: on the root (upstream)');
  });

  test('long text truncates with an ellipsis and keeps the full text as title', async function (assert) {
    await render(
      <template>
        <div style="width: 90px">
          <EuiBadge data-long>A very long badge label that cannot fit</EuiBadge>
          <EuiBadge
            @iconType="cross"
            @iconOnClick={{noop}}
            @iconOnClickAriaLabel="Remove"
            @onClick={{noop}}
            class="long-child"
            data-long-child
          >Another very long badge label here</EuiBadge>
        </div>
      </template>
    );
    
    assert.true(box(this.element, '[data-long]').width <= 90, 'max-width: 100%');
    const text = el(this.element, '[data-long] .euiBadge__text');
    assert.strictEqual(getComputedStyle(text).textOverflow, 'ellipsis');
    assert.strictEqual(getComputedStyle(text).overflow, 'hidden');
    assert.true(text.scrollWidth > text.clientWidth, 'text overflows');
    assert
      .dom('[data-long]')
      .hasAttribute('title', 'A very long badge label that cannot fit');
    // upstream: the attributes are on the text button, the class on the root
    const child = el(this.element, '.long-child .euiBadge__childButton[data-long-child]');
    assert.strictEqual(getComputedStyle(child).textOverflow, 'ellipsis');
    assert.true(box(this.element, '.long-child').width <= 90);
  });

  test('EuiBetaBadge sizes, circles, colors, alignment and link/button/tooltip semantics', async function (assert) {
    const colors = ['hollow', 'accent', 'subdued', 'warning'] as const;
    let clicks = 0;
    const press = () => clicks++;
    await render(
      <template>
        <EuiBetaBadge @label="Beta" data-m />
        <EuiBetaBadge @label="Beta" @size="s" data-s />
        <EuiBetaBadge @label="B" data-letter-m />
        <EuiBetaBadge @label="B" @size="s" data-letter-s />
        <EuiBetaBadge @iconType="beaker" @title="Lab" data-icon-m />
        <EuiBetaBadge @iconType="beaker" @title="Lab" @size="s" data-icon-s />
        {{#each colors as |color|}}
          <EuiBetaBadge @label={{color}} @color={{color}} data-color={{color}} />
        {{/each}}
        <EuiBetaBadge @label="Mid" @alignment="middle" data-middle />
        <EuiBetaBadge
          @label="Link"
          @href="https://example.com"
          @target="_blank"
          data-link
        />
        <EuiBetaBadge
          @label="Button"
          @onClick={{press}}
          @onClickAriaLabel="Learn more"
          data-button
        />
        <span data-tooltip-host>
          <EuiBetaBadge
            @label="Tip"
            @tooltipContent="Not ready yet"
            data-tooltip
          />
        </span>
        <span data-clickable-tooltip-host>
          <EuiBetaBadge
            @label="Both"
            @onClick={{press}}
            @tooltipContent="Explained"
          />
        </span>
      </template>
    );
    
    const m = style(this.element, '[data-m]');
    const s = style(this.element, '[data-s]');
    assert.strictEqual(m.height, light.size.l, 'm is 24px tall');
    assert.strictEqual(m.lineHeight, light.size.l);
    assert.strictEqual(m.paddingInlineStart, light.size.base);
    assertXsFont(assert, m.fontSize, 'beta m');
    assert.strictEqual(s.height, '20px', 's is 1.25 × base');
    assert.strictEqual(s.paddingInlineStart, light.size.m);
    assert.true(Math.abs(parseFloat(s.fontSize) - remPx(0.7)) < 0.05, 's uses 0.7rem');
    assert.strictEqual(m.textTransform, 'uppercase');
    assert.strictEqual(m.fontWeight, String(light.font.weight.semiBold));
    assert.strictEqual(m.verticalAlign, 'baseline', 'default alignment');
    assert.strictEqual(m.textOverflow, 'ellipsis');
    assert.true(m.fontFamily.includes('Inter'));
    for (const [selector, size] of [
      ['[data-letter-m]', 24],
      ['[data-letter-s]', 20],
      ['[data-icon-m]', 24],
      ['[data-icon-s]', 20]
    ] as const) {
      const rect = box(this.element, selector);
      assert.strictEqual(rect.width, size, `${selector} is a circle`);
      assert.strictEqual(rect.height, size);
    }
    assert.strictEqual(
      style(this.element, '[data-icon-m] .euiBetaBadge__icon').width,
      light.size.base,
      'm icon is 16px'
    );
    assert.strictEqual(
      style(this.element, '[data-icon-s] .euiBetaBadge__icon').width,
      light.size.m,
      's icon is 12px'
    );
    assert
      .dom('[data-icon-m] .euiBetaBadge__icon')
      .hasAttribute('aria-hidden', 'true');
    assert.dom('[data-icon-m]').hasAttribute('title', 'Lab');

    const expected = {
      hollow: lightColors.hollow,
      accent: lightColors.fill.accent!,
      subdued: lightColors.subdued,
      warning: lightColors.fill.warning!
    };
    for (const color of colors) {
      const computed = style(this.element, `[data-color="${color}"]`);
      assert.strictEqual(computed.color, rgb(expected[color].color), `${color} text`);
      assert.strictEqual(
        computed.backgroundColor,
        rgb(expected[color].backgroundColor),
        `${color} background`
      );
    }
    assert.strictEqual(
      style(this.element, '[data-color="hollow"]').borderTopColor,
      rgb(lightColors.hollow.borderColor!)
    );
    assert.strictEqual(style(this.element, '[data-middle]').verticalAlign, 'middle');

    assert
      .dom('[data-link]')
      .hasTagName('a')
      .hasAttribute('title', 'Link')
      .hasAttribute('rel', 'noopener noreferrer');
    assert
      .dom('[data-button]')
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasAttribute('aria-label', 'Learn more');
    const button = style(this.element, '[data-button]');
    assert.strictEqual(button.height, light.size.l, 'button reset keeps the size');
    assert.strictEqual(button.fontSize, m.fontSize, 'button reset keeps the font');
    await click('[data-button]');
    assert.strictEqual(clicks, 1);
    await focus('[data-button]');
    assert.strictEqual(
      style(this.element, '[data-button]').outlineStyle,
      expectedOutline(el(this.element, '[data-button]'))
    );

    assert
      .dom('[data-tooltip]')
      .hasTagName('span')
      .hasAttribute('tabindex', '0')
      .hasAttribute('role', 'button')
      .doesNotHaveAttribute('title');
    assert
      .dom('[data-clickable-tooltip-host] .euiBetaBadge')
      .exists({ count: 1 }, 'clickable tooltip badges render once');
    await triggerEvent('[data-tooltip]', 'mouseover');
    await triggerEvent('[data-tooltip]', 'mouseout');
    assert.dom('[data-m]').hasAttribute('title', 'Beta');
    assert
      .dom('.euiBetaBadge--hollow, .euiBetaBadge--small, .euiBetaBadge--singleLetter')
      .doesNotExist('no legacy modifier classes');
  });

  test('EuiNotificationBadge sizes and colors', async function (assert) {
    await render(
      <template>
        <EuiNotificationBadge data-default>3</EuiNotificationBadge>
        <EuiNotificationBadge @size="m" data-m>12</EuiNotificationBadge>
        <EuiNotificationBadge @color="subdued" data-subdued>5</EuiNotificationBadge>
        <EuiNotificationBadge @color="success" data-success>7</EuiNotificationBadge>
        <EuiNotificationBadge
          aria-label="3 unread"
          id="count"
          data-attrs
        >3</EuiNotificationBadge>
      </template>
    );
    const small = style(this.element, '[data-default]');
    assert.strictEqual(small.height, light.size.base);
    assert.strictEqual(small.minWidth, light.size.base);
    assert.strictEqual(small.borderTopLeftRadius, light.border.radius.inline);
    assert.strictEqual(small.display, 'inline-flex');
    assertXsFont(assert, small.fontSize, 'notification');
    assert.strictEqual(small.fontWeight, String(light.font.weight.medium));
    assert.strictEqual(small.paddingInlineStart, light.size.xs);
    assert.true(small.fontFeatureSettings.includes('tnum'), 'tabular numbers');
    assert.true(small.fontFamily.includes('Inter'));
    assert.strictEqual(small.color, rgb(lightColors.accentText.color));
    assert.strictEqual(
      small.backgroundColor,
      rgb(lightColors.accentText.backgroundColor),
      'accent uses the accent text color as background'
    );
    const medium = style(this.element, '[data-m]');
    assert.strictEqual(medium.height, '20px', 'm is base + xs');
    assert.strictEqual(medium.borderTopLeftRadius, light.border.radius.control);
    const subdued = style(this.element, '[data-subdued]');
    assert.strictEqual(subdued.backgroundColor, rgb(lightColors.subdued.backgroundColor));
    assert.strictEqual(subdued.color, rgb(lightColors.subdued.color));
    const success = style(this.element, '[data-success]');
    assert.strictEqual(
      success.backgroundColor,
      rgb(lightColors.fill.success!.backgroundColor)
    );
    assert.strictEqual(success.color, rgb(lightColors.fill.success!.color));
    assert
      .dom('[data-attrs]')
      .hasAttribute('aria-label', '3 unread')
      .hasAttribute('id', 'count')
      .hasClass('euiNotificationBadge')
      .hasText('3');
    assert
      .dom('.euiNotificationBadge--medium, .euiNotificationBadge--subdued')
      .doesNotExist('no legacy modifier classes');
  });

  test('EuiBadgeGroup gutters and adjacent badge spacing', async function (assert) {
    const gutters = ['none', 'xs', 's'] as const;
    await render(
      <template>
        {{#each gutters as |gutter|}}
          <EuiBadgeGroup @gutterSize={{gutter}} data-group={{gutter}} as |group|>
            <group.item><EuiBadge data-first>One</EuiBadge></group.item>
            <group.item><EuiBadge>Two</EuiBadge></group.item>
          </EuiBadgeGroup>
        {{/each}}
        <EuiBadgeGroup data-default-group as |group|>
          <group.item><EuiBadge>One</EuiBadge></group.item>
        </EuiBadgeGroup>
        <div data-adjacent>
          <EuiBadge data-a>A</EuiBadge><EuiBadge data-b>B</EuiBadge>
        </div>
        <div style="width: 80px">
          <EuiBadgeGroup data-narrow as |group|>
            <group.item><EuiBadge>A long label inside a group</EuiBadge></group.item>
          </EuiBadgeGroup>
        </div>
      </template>
    );
    const spacing = (gutter: string) => {
      const items = this.element.querySelectorAll(
        `[data-group="${gutter}"] .euiBadgeGroup__item`
      );
      return Math.round(
        (items[1]!.getBoundingClientRect().left -
          items[0]!.getBoundingClientRect().right) /
          scale()
      );
    };
    assert.strictEqual(spacing('none'), 0);
    assert.strictEqual(spacing('xs'), 4);
    assert.strictEqual(spacing('s'), 8);
    const group = style(this.element, '[data-default-group]');
    assert.strictEqual(group.display, 'inline-flex');
    assert.strictEqual(group.flexWrap, 'wrap');
    assert.strictEqual(group.columnGap, light.size.xs, 'default gutter is xs');
    assert.strictEqual(
      style(this.element, '[data-b]').marginInlineStart,
      light.size.xs,
      'adjacent badges are spaced'
    );
    assert.true(box(this.element, '[data-narrow]').width <= 80);
    assert.true(
      box(this.element, '[data-narrow] .euiBadge').width <= 80,
      'badges in a group truncate'
    );
    assert
      .dom('.euiBadgeGroup--gutterSmall, .euiBadgeGroup--gutterExtraSmall')
      .doesNotExist('no legacy modifier classes');
  });

  test('arguments update reactively without replacing elements', async function (assert) {
    class State {
      @tracked color = 'primary';
      @tracked fill = false;
      @tracked side: 'left' | 'right' = 'left';
      @tracked disabled = false;
      @tracked betaColor: 'hollow' | 'accent' = 'hollow';
      @tracked betaSize: 's' | 'm' = 'm';
      @tracked notificationSize: 's' | 'm' = 's';
      @tracked notificationColor: 'accent' | 'subdued' = 'accent';
      @tracked gutter: 'xs' | 's' = 'xs';
      @tracked label = 'First';
    }
    const state = new State();
    await render(
      <template>
        <EuiBadge
          @color={{state.color}}
          @fill={{state.fill}}
          @iconType="check"
          @iconSide={{state.side}}
          @isDisabled={{state.disabled}}
          data-badge
        >{{state.label}}</EuiBadge>
        <EuiBetaBadge
          @label="Beta"
          @color={{state.betaColor}}
          @size={{state.betaSize}}
          data-beta
        />
        <EuiNotificationBadge
          @size={{state.notificationSize}}
          @color={{state.notificationColor}}
          data-notification
        >1</EuiNotificationBadge>
        <EuiBadgeGroup @gutterSize={{state.gutter}} data-group as |group|>
          <group.item><EuiBadge>A</EuiBadge></group.item>
        </EuiBadgeGroup>
      </template>
    );
    
    const nodes = ['badge', 'beta', 'notification', 'group'].map((name) =>
      el(this.element, `[data-${name}]`)
    );
    assert.strictEqual(
      style(this.element, '[data-badge]').backgroundColor,
      rgb(lightColors.base.primary!.backgroundColor)
    );
    assert.dom('[data-badge]').hasAttribute('title', 'First');

    state.fill = true;
    state.side = 'right';
    state.betaColor = 'accent';
    state.betaSize = 's';
    state.notificationSize = 'm';
    state.notificationColor = 'subdued';
    state.gutter = 's';
    state.label = 'Second';
    await settled();
    finishTransitions();

    ['badge', 'beta', 'notification', 'group'].forEach((name, index) =>
      assert.strictEqual(
        this.element.querySelector(`[data-${name}]`),
        nodes[index],
        `${name} element preserved`
      )
    );
    assert.strictEqual(
      style(this.element, '[data-badge]').backgroundColor,
      rgb(lightColors.fill.primary!.backgroundColor),
      'fill'
    );
    assert.dom('[data-badge] .euiBadge__content > :last-child').hasClass('euiBadge__icon');
    assert.dom('[data-badge]').hasAttribute('title', 'Second', 'title follows the text');
    assert.strictEqual(
      style(this.element, '[data-beta]').backgroundColor,
      rgb(lightColors.fill.accent!.backgroundColor)
    );
    assert.strictEqual(style(this.element, '[data-beta]').height, '20px');
    assert.strictEqual(style(this.element, '[data-notification]').height, '20px');
    assert.strictEqual(
      style(this.element, '[data-notification]').backgroundColor,
      rgb(lightColors.subdued.backgroundColor)
    );
    assert.strictEqual(style(this.element, '[data-group]').columnGap, light.size.s);

    state.color = '#1A237E';
    state.disabled = true;
    await settled();
    finishTransitions();
    assert.strictEqual(
      this.element.querySelector('[data-badge]'),
      nodes[0],
      'plain badge stays put when disabled'
    );
    assert.strictEqual(
      style(this.element, '[data-badge]').backgroundColor,
      rgb(lightColors.disabled.backgroundColor)
    );
    state.disabled = false;
    await settled();
    finishTransitions();
    assert.strictEqual(style(this.element, '[data-badge]').backgroundColor, 'rgb(26, 35, 126)');
  });

  test('light/dark modes follow the nearest provider; siblings stay isolated', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiBadge data-parent>Parent</EuiBadge>
          <EuiBadge @color="#FFEB3B" data-parent-custom>Custom</EuiBadge>
          <EuiBetaBadge @label="Beta" data-parent-beta />
          <EuiNotificationBadge data-parent-notification>1</EuiNotificationBadge>
          <EuiEmotionProvider>
            <EuiBadge @color="success" data-nested>Nested</EuiBadge>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <EuiBadge data-fixed-light>Fixed</EuiBadge>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiBadge data-sibling>Sibling</EuiBadge>
        </EuiEmotionProvider>
      </template>
    );
    const parent = el(this.element, '[data-parent]');
    assert.strictEqual(
      getComputedStyle(parent).backgroundColor,
      rgb(lightColors.base.default!.backgroundColor)
    );

    state.mode = 'dark';
    await settled();
    finishTransitions();

    assert.strictEqual(this.element.querySelector('[data-parent]'), parent, 'element kept');
    assert.strictEqual(
      getComputedStyle(parent).backgroundColor,
      rgb(darkColors.base.default!.backgroundColor)
    );
    assert.strictEqual(getComputedStyle(parent).color, rgb(darkColors.base.default!.color));
    assert.strictEqual(
      style(this.element, '[data-parent-custom]').color,
      rgb(getTextColor(darkContext, '#FFEB3B') as string),
      'custom text color uses the dark theme tokens'
    );
    assert.strictEqual(
      style(this.element, '[data-parent-beta]').borderTopColor,
      rgb(darkColors.hollow.borderColor!)
    );
    assert.strictEqual(
      style(this.element, '[data-parent-notification]').backgroundColor,
      rgb(darkColors.accentText.backgroundColor)
    );
    assert.strictEqual(
      style(this.element, '[data-nested]').backgroundColor,
      rgb(darkColors.base.success!.backgroundColor),
      'nested provider inherits dark'
    );
    assert.strictEqual(
      style(this.element, '[data-fixed-light]').backgroundColor,
      rgb(lightColors.base.default!.backgroundColor),
      'fixed light child is isolated'
    );
    assert.strictEqual(
      style(this.element, '[data-sibling]').backgroundColor,
      rgb(lightColors.base.default!.backgroundColor),
      'outer sibling is isolated'
    );
    assert.notStrictEqual(
      rgb(darkColors.base.default!.backgroundColor),
      rgb(lightColors.base.default!.backgroundColor),
      'modes actually differ'
    );
  });

  test('native token overrides and high contrast reach the badge factories', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    const nested: EuiBorealisOverrides = {
      colors: { LIGHT: { textAccent: '#00aa00' } }
    };
    await render(
      <template>
        <EuiEmotionProvider
          @borealisOverrides={{state.overrides}}
          @highContrastMode={{state.contrast}}
        >
          <EuiNotificationBadge data-notification>1</EuiNotificationBadge>
          <EuiBadge @color="primary" data-badge>Primary</EuiBadge>
          <EuiBadge @color="#FFEB3B" data-custom>Custom</EuiBadge>
          <EuiBadgeGroup data-group as |group|>
            <group.item><EuiBadge>A</EuiBadge></group.item>
          </EuiBadgeGroup>
          <EuiEmotionProvider @borealisOverrides={{nested}}>
            <EuiNotificationBadge data-nested>2</EuiNotificationBadge>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiNotificationBadge data-outside>3</EuiNotificationBadge>
      </template>
    );
    assert.strictEqual(style(this.element, '[data-badge]').borderTopStyle, 'solid');
    assert.strictEqual(
      style(this.element, '[data-badge]').borderTopColor,
      'rgba(0, 0, 0, 0)',
      'transparent border outside high contrast'
    );
    assert.strictEqual(style(this.element, '[data-notification]').borderTopStyle, 'none');

    state.overrides = {
      colors: { LIGHT: { textAccent: '#123456', textInk: '#010203' } },
      size: { xs: '6px' }
    };
    state.contrast = 'preferred';
    await settled();
    finishTransitions();

    const overridden = resolveBorealisTheme('light', state.overrides, 'preferred');
    const overriddenColors = euiBadgeColors(overridden) as BadgeColorSet;
    assert.strictEqual(
      style(this.element, '[data-notification]').backgroundColor,
      'rgb(18, 52, 86)',
      'textAccent override reaches the notification badge'
    );
    assert.strictEqual(
      style(this.element, '[data-custom]').color,
      rgb(getTextColor(overridden, '#FFEB3B') as string),
      'custom badge text uses the overridden (high contrast) ink'
    );
    assert.strictEqual(style(this.element, '[data-group]').columnGap, '6px');
    assert.strictEqual(
      style(this.element, '[data-nested]').backgroundColor,
      'rgb(0, 170, 0)',
      'nearest override wins'
    );
    assert.strictEqual(
      style(this.element, '[data-outside]').backgroundColor,
      rgb(lightColors.accentText.backgroundColor),
      'overrides stay scoped'
    );
    assert.strictEqual(
      style(this.element, '[data-notification]').borderTopStyle,
      'solid',
      'preferred contrast borders notification badges'
    );
    const badge = style(this.element, '[data-badge]');
    assert.strictEqual(badge.borderTopStyle, 'solid');
    assert.strictEqual(
      badge.borderTopColor,
      rgb(overriddenColors.base.primary!.borderColor!),
      'preferred contrast shows the colored badge border'
    );
    assert.strictEqual(
      badge.backgroundColor,
      rgb(overriddenColors.base.primary!.backgroundColor)
    );

    state.contrast = 'forced';
    await settled();
    finishTransitions();
    assert.strictEqual(style(this.element, '[data-badge]').borderTopStyle, 'solid');

    await clearRender();
    assert
      .dom('.euiBadge, .euiBetaBadge, .euiNotificationBadge, .euiBadgeGroup')
      .doesNotExist('teardown');
  });

  test('attributes, modifiers and accessibility', async function (assert) {
    const events: string[] = [];
    const record = (event: Event) => events.push(event.type);
    await render(
      <template>
        <EuiBadge
          id="status"
          aria-describedby="help"
          data-test-subj="status-badge"
          {{on "mouseenter" record}}
          data-badge
        >Status</EuiBadge>
        <EuiBadge
          @onClick={{noop}}
          @onClickAriaLabel="Open details"
          title="Custom title"
          data-button
        >Open</EuiBadge>
        <EuiBadge @color="hollow" @iconType="returnKey" aria-hidden="true" data-hidden />
        <EuiBetaBadge
          @label="Beta"
          data-test-subj="beta"
          {{on "mouseenter" record}}
          data-beta
        />
        <EuiNotificationBadge {{on "mouseenter" record}} data-notification>4</EuiNotificationBadge>
        <EuiBadgeGroup aria-label="Tags" data-group as |group|>
          <group.item><EuiBadge>Tag</EuiBadge></group.item>
        </EuiBadgeGroup>
      </template>
    );
    
    assert
      .dom('[data-badge]')
      .hasAttribute('id', 'status')
      .hasAttribute('aria-describedby', 'help')
      .hasAttribute('data-test-subj', 'status-badge')
      .hasClass('euiBadge');
    assert
      .dom('[data-button]')
      .hasAttribute('title', 'Custom title', 'caller title wins over the inner text')
      .hasAttribute('aria-label', 'Open details');
    assert.dom('[data-hidden]').hasAttribute('aria-hidden', 'true');
    assert.dom('[data-beta]').hasAttribute('data-test-subj', 'beta');
    assert.dom('[data-group]').hasAttribute('aria-label', 'Tags').hasTagName('div');
    await triggerEvent('[data-badge]', 'mouseenter');
    await triggerEvent('[data-beta]', 'mouseenter');
    await triggerEvent('[data-notification]', 'mouseenter');
    assert.deepEqual(events, ['mouseenter', 'mouseenter', 'mouseenter']);
    await focus('[data-button]');
    const button = style(this.element, '[data-button]');
    assert.strictEqual(
      button.outlineStyle,
      expectedOutline(el(this.element, '[data-button]')),
      'focus ring on clickable badges'
    );
    assert.strictEqual(
      button.outlineOffset,
      '3px',
      'outset ring clears the badge border (focus width + border)'
    );
    assert.strictEqual(
      (document.activeElement as HTMLElement).dataset['button'],
      '',
      'clickable badges are focusable'
    );
  });
});

const closeProps = {
  tabIndex: -1,
  dataSelectedIconIndex: 2,
  iconClasses: 'extra-icon-class'
};

function noop() {}
