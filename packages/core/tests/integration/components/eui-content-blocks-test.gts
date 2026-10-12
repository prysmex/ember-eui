import { tracked } from '@glimmer/tracking';
import { array } from '@ember/helper';
import {
  clearRender,
  click,
  render,
  rerender,
  settled
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import { getTokenName } from '@elastic/eui-theme-common';

import EuiButton from '#src/components/eui-button.gts';
import EuiButtonEmpty from '#src/components/eui-button-empty.gts';
import EuiCallOut from '#src/components/eui-call-out.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiEmptyPrompt from '#src/components/eui-empty-prompt.gts';
import EuiPanel from '#src/components/eui-panel.gts';
import EuiStat from '#src/components/eui-stat.gts';
import EuiText from '#src/components/eui-text.gts';
import EuiTitle from '#src/components/eui-title.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiCallOutColor } from '#src/components/eui-call-out.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

type Colors = Record<string, string>;

function token(
  theme: typeof light,
  base: string,
  color: string
): string {
  return (theme.colors as unknown as Colors)[getTokenName(base, color)]!;
}

function el(root: Element, selector: string): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element, selector: string, pseudo?: string) {
  return getComputedStyle(el(root, selector), pseudo);
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

function px(value: string) {
  return parseFloat(value);
}

/** Lets ResizeObserver callbacks run, then waits for Ember. */
async function layoutSettled() {
  // Observer callback, then the deferred attribute write, then a margin.
  for (let frame = 0; frame < 4; frame++)
    await new Promise((resolve) => requestAnimationFrame(resolve));
  await settled();
}

/** Media rules (conditionText) whose style rules mention `className`. */
function mediaConditionsFor(className: string): string[] {
  const conditions: string[] = [];
  for (const sheet of Array.from(document.styleSheets)) {
    let rules: CSSRuleList;
    try {
      rules = sheet.cssRules;
    } catch {
      continue;
    }
    for (const rule of Array.from(rules)) {
      if (
        rule instanceof CSSMediaRule &&
        Array.from(rule.cssRules).some(
          (inner) =>
            inner instanceof CSSStyleRule &&
            inner.selectorText.includes(className)
        )
      )
        conditions.push(rule.conditionText);
    }
  }
  return conditions;
}

/** The generated Emotion class (the one that is not a stable name). */
function emotionClass(element: Element, stable: string[]): string {
  return Array.from(element.classList).find(
    (name) => !stable.includes(name)
  )!;
}

const CALLOUT_COLORS: EuiCallOutColor[] = [
  'primary',
  'success',
  'warning',
  'danger'
];

const isLarge = () =>
  window.matchMedia(`(min-width: ${light.breakpoint.l}px)`).matches;

const canAnimate = () =>
  window.matchMedia('(prefers-reduced-motion: no-preference)').matches;

const noop = () => {};

module('Integration | Component | Borealis content blocks', function (hooks) {
  setupRenderingTest(hooks);

  // ---------------------------------------------------------------- CallOut

  test('callout colors: panel background, semantic border, radius and text in every color', async function (assert) {
    await render(
      <template>
        {{#each CALLOUT_COLORS as |color|}}
          <EuiCallOut
            @color={{color}}
            @title="Title"
            data-color={{color}}
          >Body</EuiCallOut>
        {{/each}}
        {{! @glint-expect-error: unknown colors fall back to primary, as upstream }}
        <EuiCallOut @color="accent" @title="Fallback" data-fallback />
      </template>
    );
    for (const color of CALLOUT_COLORS) {
      const root = el(this.element, `[data-color="${color}"]`);
      const css = getComputedStyle(root);
      assert.dom(root).hasClass(`euiCallOut--${color}`);
      assert.strictEqual(
        css.backgroundColor,
        rgb(token(light, 'backgroundBase', color)),
        `${color} background`
      );
      for (const side of ['Top', 'Right', 'Bottom', 'Left'] as const) {
        assert.strictEqual(
          css[`border${side}Color`],
          rgb(token(light, 'borderBase', color)),
          `${color} border ${side}`
        );
        assert.strictEqual(css[`border${side}Width`], light.border.width.thin);
        assert.strictEqual(css[`border${side}Style`], 'solid');
      }
      assert.strictEqual(css.borderTopLeftRadius, light.border.radius.panel);
      assert.strictEqual(css.boxShadow, 'none');
      assert.strictEqual(css.display, 'flex');
      assert.strictEqual(css.alignItems, 'center');
      assert.strictEqual(css.position, 'relative');
      assert.strictEqual(css.boxSizing, 'border-box');
      assert.strictEqual(
        getComputedStyle(root, '::after').content,
        'none',
        'colored panels draw no pseudo border'
      );
      const title = style(root, '.euiCallOutHeader__title');
      assert.strictEqual(title.color, rgb(light.colors.textHeading));
      assert.strictEqual(title.fontWeight, String(light.font.weight.bold));
      assert.strictEqual(title.marginBottom, '0px');
      assert.strictEqual(
        style(root, '.euiCallOut__additionalContent').color,
        rgb(light.colors.textParagraph),
        'body uses the default text color'
      );
      assert
        .dom('.euiNotificationIcon', root)
        .exists({ count: 1 }, `${color} renders a default notification icon`)
        .hasAttribute('aria-hidden', 'true');
    }
    const fallback = el(this.element, '[data-fallback]');
    assert.dom(fallback).hasClass('euiCallOut--primary');
    assert.strictEqual(
      getComputedStyle(fallback).backgroundColor,
      rgb(light.colors.backgroundBasePrimary)
    );
  });

  test('callout sizes: padding, gaps, title and text scale', async function (assert) {
    await render(
      <template>
        <div style="width: 600px">
          <EuiCallOut @title="Medium" @text="Text" data-m>Children</EuiCallOut>
          <EuiCallOut
            @size="s"
            @title="Small"
            @text="Text"
            data-s
          >Children</EuiCallOut>
          <EuiTitle @size="xs" data-ref-xs>x</EuiTitle>
          <EuiTitle @size="xxs" data-ref-xxs>x</EuiTitle>
          <EuiText @size="s" data-ref-s>x</EuiText>
          <EuiText @size="xs" data-ref-text-xs>x</EuiText>
        </div>
      </template>
    );
    const m = style(this.element, '[data-m]');
    const s = style(this.element, '[data-s]');
    assert.dom('[data-m]').hasAttribute('data-size', 'm');
    assert.dom('[data-s]').hasAttribute('data-size', 's');
    assert.deepEqual(
      [m.paddingTop, m.paddingRight, m.paddingBottom, m.paddingLeft],
      Array(4).fill(light.size.base),
      'm padding is size.base'
    );
    assert.deepEqual(
      [s.paddingTop, s.paddingRight, s.paddingBottom, s.paddingLeft],
      [light.size.m, light.size.base, light.size.m, light.size.base],
      's padding is size.m block, size.base inline'
    );

    const wrapper = (selector: string) =>
      getComputedStyle(el(this.element, selector).firstElementChild!);
    const body = (selector: string) =>
      getComputedStyle(
        el(this.element, selector).firstElementChild!.firstElementChild!
      );
    assert.strictEqual(wrapper('[data-m]').flexDirection, 'column');
    assert.strictEqual(wrapper('[data-m]').rowGap, light.size.m);
    assert.strictEqual(wrapper('[data-s]').rowGap, light.size.s);
    assert.strictEqual(body('[data-m]').display, 'flex');
    assert.strictEqual(body('[data-m]').columnGap, light.size.m);
    assert.strictEqual(body('[data-s]').columnGap, light.size.s);

    assert.strictEqual(
      style(this.element, '[data-m] .euiCallOutHeader__title').fontSize,
      style(this.element, '[data-ref-xs]').fontSize,
      'm title is EuiTitle xs'
    );
    assert.strictEqual(
      style(this.element, '[data-s] .euiCallOutHeader__title').fontSize,
      style(this.element, '[data-ref-xxs]').fontSize,
      's title is EuiTitle xxs'
    );
    assert.strictEqual(
      style(this.element, '[data-m] .euiCallOut__additionalContent').fontSize,
      style(this.element, '[data-ref-s]').fontSize,
      'm children are EuiText s'
    );
    assert.strictEqual(
      style(this.element, '[data-s] .euiCallOut__additionalContent').fontSize,
      style(this.element, '[data-ref-text-xs]').fontSize,
      's children are EuiText xs'
    );
    assert.strictEqual(
      style(this.element, '[data-s] .euiCallOut__text').fontSize,
      style(this.element, '[data-ref-s]').fontSize,
      '@text is EuiText s in both sizes'
    );

    // m stacks title/text/children in a column; s runs title and text inline.
    const mContent = el(this.element, '[data-m] .euiCallOut__text')
      .parentElement!;
    assert.strictEqual(getComputedStyle(mContent).display, 'flex');
    assert.strictEqual(getComputedStyle(mContent).flexDirection, 'column');
    assert.strictEqual(getComputedStyle(mContent).rowGap, light.size.xs);
    assert.strictEqual(
      style(this.element, '[data-m] .euiCallOut__additionalContent').marginTop,
      light.size.s,
      'children after text get size.s'
    );
    assert.strictEqual(
      style(this.element, '[data-s] .euiCallOutHeader__title').display,
      'inline'
    );
    assert.strictEqual(
      style(this.element, '[data-s] .euiCallOutHeader__title').marginRight,
      light.size.xxs
    );
    assert.strictEqual(
      style(this.element, '[data-s] .euiCallOut__text').display,
      'inline'
    );
    const separator = style(this.element, '[data-s] .euiCallOut__text', '::before');
    assert.strictEqual(separator.content, '"·"', 'inline separator after the title');
    assert.strictEqual(separator.color, rgb(light.colors.textHeading));
    assert.strictEqual(
      style(this.element, '[data-s] .euiCallOut__additionalContent').marginTop,
      light.size.xs
    );
    assert.strictEqual(
      px(getComputedStyle(mContent).maxWidth),
      1200,
      'content keeps the 1200px reading width'
    );
  });

  test('callout heading level, title block, icon semantics and forwarded attributes', async function (assert) {
    await render(
      <template>
        <EuiCallOut @title="Default" data-default />
        {{#each (array "h1" "h2" "h3" "h4" "h5" "h6") as |tag|}}
          {{! @glint-expect-error: tag is a string literal from the array }}
          <EuiCallOut @heading={{tag}} @title={{tag}} data-heading={{tag}} />
        {{/each}}
        <EuiCallOut @heading="h2" data-block role="status" aria-live="polite">
          <:title><em>Block</em> title</:title>
          <:body><p>Body</p></:body>
        </EuiCallOut>
        <EuiCallOut @iconType="help" data-custom-icon>No title</EuiCallOut>
      </template>
    );
    assert
      .dom('[data-default] .euiCallOutHeader__title')
      .hasTagName('p', 'upstream default heading is a paragraph')
      .hasClass('euiTitle');
    for (const tag of ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']) {
      assert
        .dom(`[data-heading="${tag}"] .euiCallOutHeader__title`)
        .hasTagName(tag)
        .hasText(tag);
      assert.strictEqual(
        style(this.element, `[data-heading="${tag}"] .euiCallOutHeader__title`)
          .fontSize,
        style(this.element, '[data-default] .euiCallOutHeader__title').fontSize,
        `${tag} keeps the size-driven title scale`
      );
    }
    assert.dom('[data-block] h2.euiCallOutHeader__title em').hasText('Block');
    assert
      .dom('[data-block]')
      .hasAttribute('role', 'status')
      .hasAttribute('aria-live', 'polite');
    assert.dom('[data-block] .euiCallOut__additionalContent p').hasText('Body');
    assert.dom('[data-custom-icon] .euiCallOutHeader__title').doesNotExist();
    assert.dom('[data-custom-icon] .euiNotificationIcon').doesNotExist();
    assert
      .dom('[data-custom-icon] svg')
      .exists({ count: 1 })
      .hasAttribute('aria-hidden', 'true');
    const icon = style(this.element, '[data-custom-icon] svg');
    assert.strictEqual(icon.position, 'relative');
    assert.strictEqual(icon.marginTop, light.size.xxs, 'icon aligns with the first line');
    assert.dom('[data-custom-icon] .euiCallOut__additionalContent').hasText('No title');
  });

  test('callout dismiss button: label, placement, padding and behavior', async function (assert) {
    const calls: Event[] = [];
    const onDismiss = (event: Event) => calls.push(event);
    const i18n = this.owner.lookup('service:eui-i18n') as {
      addTranslations: (translations: object) => void;
    };
    await render(
      <template>
        <EuiCallOut @title="Plain" data-plain>Body</EuiCallOut>
        <div dir="ltr">
          <EuiCallOut
            @title="Dismissible"
            @color="warning"
            @onDismiss={{onDismiss}}
            data-ltr
          >Body</EuiCallOut>
        </div>
        <div dir="rtl">
          <EuiCallOut @title="RTL" @onDismiss={{noop}} data-rtl>Body</EuiCallOut>
        </div>
        <EuiCallOut @onDismiss={{noop}} data-untitled>Only body</EuiCallOut>
        <EuiCallOut
          @title="Custom"
          @onDismiss={{noop}}
          @dismissButtonAriaLabel="Hide notice"
          data-custom-label
        />
      </template>
    );
    assert.dom('[data-plain] button').doesNotExist();
    assert.strictEqual(
      style(this.element, '[data-plain]').paddingRight,
      light.size.base
    );

    const button = el(this.element, '[data-ltr] [data-test-subj="euiDismissCalloutButton"]');
    assert
      .dom(button)
      .hasTagName('button')
      .hasClass('euiButtonIcon')
      .hasAttribute('type', 'button')
      .hasAttribute('aria-label', 'Dismiss this callout');
    assert.dom('svg', button).hasAttribute('aria-hidden', 'true');
    assert.strictEqual(
      style(this.element, '[data-ltr]').paddingInlineEnd,
      light.size.xxl,
      'room for the button'
    );
    assert.strictEqual(
      style(this.element, '[data-ltr]').paddingInlineStart,
      light.size.base
    );
    const buttonCss = getComputedStyle(button);
    // The positioned box is a wrapper around the button (see the handoff).
    // Offsets, not client rects: the test container is scaled.
    const ltrRoot = el(this.element, '[data-ltr]');
    const wrap = button.parentElement!;
    assert.strictEqual(wrap.offsetParent, ltrRoot, 'positioned against the callout');
    assert.strictEqual(getComputedStyle(wrap).position, 'absolute');
    assert.strictEqual(wrap.offsetWidth, button.offsetWidth, 'wrapper shrink-wraps the button');
    assert.strictEqual(wrap.offsetHeight, button.offsetHeight);
    assert.strictEqual(
      ltrRoot.clientWidth - (wrap.offsetLeft + wrap.offsetWidth),
      px(light.size.s),
      'top-right corner in LTR'
    );
    assert.strictEqual(wrap.offsetTop, px(light.size.s));
    assert.strictEqual(
      buttonCss.color,
      rgb(light.colors.textWarning),
      'button uses the callout color'
    );

    const rtlRoot = el(this.element, '[data-rtl]');
    const rtlRootRect = rtlRoot.getBoundingClientRect();
    const scale = rtlRootRect.width / rtlRoot.offsetWidth;
    assert.strictEqual(
      Math.round(
        (el(this.element, '[data-rtl] button').parentElement!.getBoundingClientRect().left -
          rtlRootRect.left) /
          scale -
          rtlRoot.clientLeft
      ),
      px(light.size.s),
      'logical inset puts it top-left in RTL'
    );
    assert.strictEqual(
      style(this.element, '[data-rtl]').paddingLeft,
      light.size.xxl,
      'dismiss padding is logical'
    );

    // DOM order: title, button, body; without a title the button follows the body.
    const titled = Array.from(
      el(this.element, '[data-ltr] .euiCallOutHeader__title').parentElement!
        .children
    );
    assert.deepEqual(
      titled.map((node) =>
        node.matches('.euiCallOutHeader__title')
          ? 'title'
          : node.querySelector('button')
            ? 'button'
            : 'body'
      ),
      ['title', 'button', 'body']
    );
    const untitled = Array.from(
      el(this.element, '[data-untitled] button').parentElement!.parentElement!
        .children
    );
    assert.deepEqual(
      untitled.map((node) => (node.querySelector('button') ? 'button' : 'body')),
      ['body', 'button']
    );
    assert
      .dom('[data-custom-label] button')
      .hasAttribute('aria-label', 'Hide notice');

    await click(button);
    assert.strictEqual(calls.length, 1, 'onDismiss called once');
    assert.true(calls[0] instanceof MouseEvent);

    button.focus();
    assert.strictEqual(document.activeElement, button, 'button is focusable');

    i18n.addTranslations({ euiCallOut: { dismissAriaLabel: 'Schließen' } });
    await clearRender();
    await render(
      <template><EuiCallOut @title="t" @onDismiss={{noop}} data-i18n /></template>
    );
    assert
      .dom('[data-i18n] button')
      .hasAttribute('aria-label', 'Schließen', 'label comes from the i18n token');
  });

  test('callout actions and width-driven layout', async function (assert) {
    await render(
      <template>
        <div style="width: 1200px" data-container>
          <EuiCallOut @title="Actions" data-actions>
            <:body>Body</:body>
            <:actions>
              <EuiButton @size="s" data-primary>Primary</EuiButton>
              <EuiButtonEmpty @size="s" data-secondary>Secondary</EuiButtonEmpty>
            </:actions>
          </EuiCallOut>
        </div>
        <div style="width: 900px">
          <EuiCallOut @size="s" @title="Small wide" data-small />
        </div>
      </template>
    );
    await layoutSettled();
    const root = el(this.element, '[data-actions]');
    const wrapper = root.firstElementChild!;
    const actions = wrapper.lastElementChild!;
    assert.dom(root).hasAttribute('data-layout', 'wide');
    assert.strictEqual(getComputedStyle(wrapper).flexDirection, 'row');
    assert.strictEqual(getComputedStyle(wrapper).columnGap, light.size.xxl);
    assert.strictEqual(getComputedStyle(actions).flexDirection, 'row-reverse');
    assert.strictEqual(getComputedStyle(actions).marginLeft, '0px');
    assert.strictEqual(getComputedStyle(actions).columnGap, light.size.s);
    assert.dom('[data-small]').hasAttribute('data-layout', 'wide', 's is wide from 800px');

    const container = el(this.element, '[data-container]');
    container.style.width = '600px';
    await layoutSettled();
    assert.strictEqual(el(this.element, '[data-actions]'), root, 'same element');
    assert.dom(root).doesNotHaveAttribute('data-layout');
    assert.strictEqual(getComputedStyle(wrapper).flexDirection, 'column');
    assert.strictEqual(
      getComputedStyle(actions).marginInlineStart,
      light.size.xl,
      'actions align with the text after the icon'
    );

    container.style.width = '320px';
    await layoutSettled();
    assert.dom(root).hasAttribute('data-layout', 'superNarrow');
    assert.strictEqual(getComputedStyle(actions).flexWrap, 'wrap');

    await clearRender();
    assert.dom('.euiCallOut').doesNotExist('observer torn down with the element');
  });

  test('callout args update in place', async function (assert) {
    class State {
      @tracked color: EuiCallOutColor = 'primary';
      @tracked size: 's' | 'm' = 'm';
      @tracked title = 'First';
      @tracked dismiss: (() => void) | undefined = undefined;
    }
    const state = new State();
    await render(
      <template>
        <EuiCallOut
          @color={{state.color}}
          @size={{state.size}}
          @title={{state.title}}
          @onDismiss={{state.dismiss}}
          data-callout
        >Body</EuiCallOut>
      </template>
    );
    const root = el(this.element, '[data-callout]');
    const title = el(this.element, '.euiCallOutHeader__title');

    state.color = 'danger';
    state.size = 's';
    state.title = 'Second';
    state.dismiss = noop;
    await settled();

    assert.strictEqual(el(this.element, '[data-callout]'), root, 'root kept');
    assert.strictEqual(
      el(this.element, '.euiCallOutHeader__title'),
      title,
      'title element kept'
    );
    assert.dom(root).hasClass('euiCallOut--danger').doesNotHaveClass('euiCallOut--primary');
    assert.dom(title).hasText('Second');
    const css = getComputedStyle(root);
    assert.strictEqual(css.backgroundColor, rgb(light.colors.backgroundBaseDanger));
    assert.strictEqual(css.borderTopColor, rgb(light.colors.borderBaseDanger));
    assert.strictEqual(css.paddingTop, light.size.m);
    assert.strictEqual(css.paddingInlineEnd, light.size.xxl);
    assert.dom('[data-callout] button').exists();

    state.dismiss = undefined;
    await rerender();
    assert.dom('[data-callout] button').doesNotExist();
    assert.strictEqual(getComputedStyle(root).paddingInlineEnd, light.size.base);
  });

  // ------------------------------------------------------------ EmptyPrompt

  test('empty prompt defaults: transparent panel, centered column, latest spacing', async function (assert) {
    await render(
      <template>
        <EuiEmptyPrompt
          @iconType="search"
          @title="No results"
          @body="Try another search"
          @footer="Footer"
          data-prompt
        />
        <EuiPanel data-panel-ref>Ref</EuiPanel>
        <EuiTitle @size="m" data-title-ref>x</EuiTitle>
      </template>
    );
    const root = style(this.element, '[data-prompt]');
    assert.strictEqual(root.backgroundColor, 'rgba(0, 0, 0, 0)', 'transparent');
    assert.strictEqual(
      getComputedStyle(el(this.element, '[data-prompt]'), '::after').content,
      'none',
      'transparent prompts have no border by default'
    );
    assert.strictEqual(root.borderTopStyle, 'none');
    assert.strictEqual(root.textAlign, 'center');
    assert.strictEqual(root.boxShadow, 'none');
    assert.strictEqual(root.flexGrow, '0');
    assert.strictEqual(
      root.borderTopLeftRadius,
      style(this.element, '[data-panel-ref]').borderTopLeftRadius,
      'panel radius m'
    );
    assert.strictEqual(
      root.maxWidth,
      isLarge() ? 'max-content' : 'none',
      'max-content from the l breakpoint'
    );
    const main = style(this.element, '.euiEmptyPrompt__main');
    assert.strictEqual(main.display, 'flex');
    assert.strictEqual(main.flexDirection, 'column');
    assert.strictEqual(main.justifyContent, 'center');
    assert.strictEqual(main.paddingTop, light.size.l, 'padding l');
    assert.strictEqual(main.paddingLeft, light.size.l);

    const icon = style(this.element, '.euiEmptyPrompt__icon');
    assert.strictEqual(icon.marginBottom, light.size.base);
    assert.strictEqual(px(icon.maxWidth), px(light.size.l) * 15);
    assert.dom('.euiEmptyPrompt__icon svg').hasClass('euiIcon--subdued', 'icon defaults to subdued');

    const content = style(this.element, '.euiEmptyPrompt__content');
    assert.strictEqual(px(content.maxWidth), 36 * px(content.fontSize));
    assert.strictEqual(
      style(this.element, '[data-prompt] .euiTitle').fontSize,
      style(this.element, '[data-title-ref]').fontSize,
      'title size m'
    );
    assert.dom('[data-prompt] .euiTitle').hasTagName('h2');
    const body = style(this.element, '[data-prompt] .euiText');
    assert.strictEqual(body.color, rgb(light.colors.textSubdued));
    assert.strictEqual(
      style(this.element, '[data-prompt] .euiBorealisSpacer').blockSize,
      light.size.s
    );

    const footer = style(this.element, '.euiEmptyPrompt__footer');
    assert.strictEqual(footer.backgroundColor, rgb(light.colors.body));
    assert.strictEqual(footer.paddingTop, light.size.l);
    assert.strictEqual(
      footer.borderBottomLeftRadius,
      root.borderBottomLeftRadius,
      'footer inherits the bottom corners'
    );
    assert.strictEqual(
      footer.borderTopLeftRadius,
      root.borderTopLeftRadius,
      'borderless transparent footer inherits every corner'
    );
  });

  test('empty prompt colors, borders, icon color and footers', async function (assert) {
    const colors = [
      'plain',
      'subdued',
      'primary',
      'accent',
      'success',
      'warning',
      'danger'
    ] as const;
    await render(
      <template>
        {{#each colors as |color|}}
          <EuiEmptyPrompt
            @color={{color}}
            @iconType="search"
            @title="t"
            @footer="f"
            data-color={{color}}
          />
        {{/each}}
        <EuiEmptyPrompt @color="plain" @hasBorder={{false}} data-plain-borderless />
        <EuiEmptyPrompt @hasBorder={{true}} @footer="f" data-transparent-border />
        <EuiEmptyPrompt
          @color="danger"
          @iconType="alert"
          @iconColor="primary"
          data-icon-color
        />
      </template>
    );
    for (const color of colors) {
      const root = el(this.element, `[data-color="${color}"]`);
      assert.strictEqual(
        getComputedStyle(root).backgroundColor,
        rgb(token(light, 'backgroundBase', color)),
        `${color} background`
      );
      const after = getComputedStyle(root, '::after');
      if (color === 'plain') {
        assert.strictEqual(after.borderTopWidth, light.border.width.thin, 'plain defaults to a border');
        assert.strictEqual(after.borderTopColor, rgb(light.border.color));
      } else {
        assert.strictEqual(after.content, 'none', `${color} has no pseudo border`);
      }
      const footer = getComputedStyle(root.querySelector('.euiEmptyPrompt__footer')!);
      if (color === 'plain') {
        assert.strictEqual(footer.backgroundColor, rgb(light.colors.body));
        assert.strictEqual(footer.borderTopStyle, 'none');
      } else {
        const base = color === 'subdued' ? 'borderBase' : 'borderStrong';
        assert.strictEqual(footer.borderTopStyle, 'solid', `${color} footer separator`);
        assert.strictEqual(
          footer.borderTopColor,
          rgb(token(light, base, color)),
          `${color} footer border token`
        );
      }
      const named = ['primary', 'accent', 'success', 'warning', 'danger'].includes(color);
      assert
        .dom('.euiEmptyPrompt__icon svg', root)
        .hasClass(named ? `euiIcon--${color}` : 'euiIcon--subdued', `${color} icon color`);
    }
    assert.strictEqual(
      getComputedStyle(el(this.element, '[data-plain-borderless]'), '::after').content,
      'none'
    );
    assert.strictEqual(
      getComputedStyle(el(this.element, '[data-transparent-border]'), '::after').borderTopWidth,
      light.border.width.thin
    );
    assert.strictEqual(
      style(this.element, '[data-transparent-border] .euiEmptyPrompt__footer')
        .borderTopLeftRadius,
      '0px',
      'only borderless transparent footers round every corner'
    );
    assert.dom('[data-icon-color] svg').hasClass('euiIcon--primary', '@iconColor wins');
  });

  test('empty prompt padding sizes, horizontal layout and responsive collapse', async function (assert) {
    class State {
      @tracked padding: 'none' | 's' | 'm' | 'l' = 'none';
      @tracked layout: 'vertical' | 'horizontal' = 'vertical';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmptyPrompt
          @layout={{state.layout}}
          @paddingSize={{state.padding}}
          @iconType="search"
          @title="Title"
          @body="Body"
          @footer="Footer"
          @actions={{array (component EuiButton) (component EuiButtonEmpty)}}
          data-prompt
        />
      </template>
    );
    const root = el(this.element, '[data-prompt]');
    const main = el(this.element, '.euiEmptyPrompt__main');
    const expected = { none: '0px', s: light.size.s, m: light.size.base, l: light.size.l };
    for (const padding of ['none', 's', 'm', 'l'] as const) {
      state.padding = padding;
      await settled();
      assert.strictEqual(getComputedStyle(main).paddingTop, expected[padding], `main padding ${padding}`);
      assert.strictEqual(
        style(this.element, '.euiEmptyPrompt__footer').paddingTop,
        expected[padding],
        `footer padding ${padding}`
      );
      assert.strictEqual(getComputedStyle(main).columnGap, 'normal', 'vertical has no gap');
    }
    const actions = el(this.element, '.euiEmptyPrompt__actions');
    assert.dom(actions).hasClass('euiFlexGroup');
    assert.strictEqual(getComputedStyle(actions).flexDirection, 'column');
    assert.strictEqual(getComputedStyle(actions).alignItems, 'center');
    assert.strictEqual(getComputedStyle(actions).justifyContent, 'center');
    assert.strictEqual(getComputedStyle(actions).rowGap, light.size.base, 'gutter m');
    assert.strictEqual(
      style(this.element, '.euiEmptyPrompt__actions > :first-child').flexGrow,
      '0'
    );

    state.layout = 'horizontal';
    await settled();
    assert.strictEqual(el(this.element, '[data-prompt]'), root, 'root kept');
    assert.strictEqual(el(this.element, '.euiEmptyPrompt__main'), main, 'main kept');
    assert.strictEqual(getComputedStyle(main).columnGap, light.size.l, 'horizontal gap equals padding');
    assert.strictEqual(getComputedStyle(main).alignItems, 'center');
    assert.strictEqual(getComputedStyle(actions).flexDirection, 'row');

    const large = isLarge();
    assert.strictEqual(
      getComputedStyle(main).flexDirection,
      large ? 'row-reverse' : 'column',
      'icon beside content only from the l breakpoint'
    );
    assert.strictEqual(getComputedStyle(root).textAlign, large ? 'start' : 'center');
    assert.strictEqual(
      getComputedStyle(actions).justifyContent,
      large ? 'flex-start' : 'center'
    );
    const icon = el(this.element, '.euiEmptyPrompt__icon');
    if (large) {
      assert.true(
        icon.getBoundingClientRect().left >
          el(this.element, '.euiEmptyPrompt__content').getBoundingClientRect().left,
        'LTR: icon sits after (right of) the content'
      );
      assert.strictEqual(getComputedStyle(icon).minWidth, '40%');
      assert.strictEqual(
        style(this.element, '.euiEmptyPrompt__content').paddingTop,
        light.size.l
      );
    }

    // The collapse is a min-width media query at the l breakpoint (the
    // test window cannot be resized, so check the rules themselves).
    const conditions = mediaConditionsFor(
      emotionClass(main, ['euiEmptyPrompt__main'])
    );
    assert.true(conditions.length > 0, `horizontal main rules are media scoped (${conditions.length})`);
    assert.true(
      conditions.every((condition) =>
        condition.includes(`min-width: ${light.breakpoint.l}px`)
      ),
      `collapse below ${light.breakpoint.l}px: ${conditions.join(' | ')}`
    );
  });

  test('empty prompt RTL and blocks', async function (assert) {
    await render(
      <template>
        <div dir="rtl">
          <EuiEmptyPrompt @layout="horizontal" @iconType="search" @title="T" data-rtl>
            <:footer><a href="#docs" data-footer-link>Docs</a></:footer>
          </EuiEmptyPrompt>
        </div>
        <EuiEmptyPrompt data-blocks>
          <:icon><img alt="Illustration" data-illustration /></:icon>
          <:content><h3 data-custom>Custom</h3></:content>
        </EuiEmptyPrompt>
      </template>
    );
    if (isLarge()) {
      const icon = el(this.element, '[data-rtl] .euiEmptyPrompt__icon').getBoundingClientRect();
      const content = el(this.element, '[data-rtl] .euiEmptyPrompt__content').getBoundingClientRect();
      assert.true(icon.left < content.left, 'RTL: icon sits on the left');
      assert.strictEqual(style(this.element, '[data-rtl]').textAlign, 'start');
    } else {
      assert.strictEqual(style(this.element, '[data-rtl]').textAlign, 'center');
    }
    assert.dom('[data-rtl] .euiEmptyPrompt__footer [data-footer-link]').exists();
    assert.dom('[data-blocks] .euiEmptyPrompt__icon [data-illustration]').exists();
    assert.dom('[data-blocks] .euiEmptyPrompt__content > [data-custom]').exists();
    assert.dom('[data-blocks] .euiEmptyPrompt__footer').doesNotExist();
    assert.dom('[data-blocks] .euiTitle').doesNotExist();
  });

  // ------------------------------------------------------------------- Stat

  test('stat title sizes, elements and description', async function (assert) {
    const sizes = ['xxxs', 'xxs', 'xs', 's', 'm', 'l'] as const;
    await render(
      <template>
        <EuiStat @title="1" @description="Default" data-default />
        {{#each sizes as |size|}}
          <EuiStat @title="1" @description="d" @titleSize={{size}} data-size={{size}} />
          <EuiTitle @size={{size}} data-ref={{size}}>x</EuiTitle>
        {{/each}}
        <EuiStat
          @title="2"
          @description="desc"
          @titleElement="h3"
          @descriptionElement="span"
          data-elements
        />
        <EuiText @size="s" data-text-ref>x</EuiText>
      </template>
    );
    for (const size of sizes) {
      const title = style(this.element, `[data-size="${size}"] .euiStat__title`);
      const ref = style(this.element, `[data-ref="${size}"]`);
      assert.strictEqual(title.fontSize, ref.fontSize, `${size} font size`);
      assert.strictEqual(title.lineHeight, ref.lineHeight, `${size} line height`);
      assert.strictEqual(title.fontWeight, ref.fontWeight);
    }
    assert.strictEqual(
      style(this.element, '[data-default] .euiStat__title').fontSize,
      style(this.element, '[data-ref="l"]').fontSize,
      'default size is l'
    );
    assert
      .dom('[data-default] .euiStat__title')
      .hasTagName('p')
      .hasClass('euiTitle')
      .hasText('1');
    assert.strictEqual(style(this.element, '[data-default] .euiStat__title').marginTop, '0px');
    assert.dom('[data-default] .euiStat__description').hasClass('euiText');
    assert.dom('[data-default] .euiStat__description > p').hasText('Default');
    assert.strictEqual(
      style(this.element, '[data-default] .euiStat__description').fontSize,
      style(this.element, '[data-text-ref]').fontSize,
      'description is EuiText s'
    );
    assert.dom('[data-elements] h3.euiStat__title').hasText('2');
    assert.dom('[data-elements] .euiStat__description > span').hasText('desc');
    assert
      .dom('[data-default] [aria-hidden]')
      .doesNotExist('title and description are read directly, as upstream');
    assert.dom('[data-default] p').exists({ count: 2 }, 'no duplicate screen reader copy');
  });

  test('stat title colors: named tokens and custom CSS colors', async function (assert) {
    const colors = {
      default: 'fullShade',
      subdued: 'textSubdued',
      primary: 'textPrimary',
      success: 'textSuccess',
      warning: 'textWarning',
      danger: 'textDanger',
      accent: 'textAccent'
    } as const;
    const names = Object.keys(colors) as (keyof typeof colors)[];
    await render(
      <template>
        {{#each names as |color|}}
          <EuiStat @title="1" @description="d" @titleColor={{color}} data-color={{color}} />
        {{/each}}
        <EuiStat @title="1" @description="d" data-unset />
        <EuiStat @title="1" @description="d" @titleColor="#123456" data-custom />
      </template>
    );
    for (const color of names) {
      assert.strictEqual(
        style(this.element, `[data-color="${color}"] .euiStat__title`).color,
        rgb((light.colors as unknown as Colors)[colors[color]]!),
        `${color} uses ${colors[color]}`
      );
    }
    assert.strictEqual(
      style(this.element, '[data-unset] .euiStat__title').color,
      rgb(light.colors.fullShade),
      'default color is fullShade'
    );
    assert.strictEqual(
      style(this.element, '[data-custom] .euiStat__title').color,
      'rgb(18, 52, 86)'
    );
    assert
      .dom('[data-custom] .euiStat__title')
      .doesNotHaveAttribute('style', 'custom color is a class, not inline style');
  });

  test('stat alignment is logical; reverse and children order', async function (assert) {
    class State {
      @tracked align: 'left' | 'center' | 'right' = 'left';
      @tracked reverse = false;
    }
    const state = new State();
    await render(
      <template>
        <div dir="ltr" style="width: 400px">
          <EuiStat
            @textAlign={{state.align}}
            @reverse={{state.reverse}}
            @description="Desc"
            data-ltr
          >
            <:title><span data-value>42</span></:title>
            <:default><span data-extra>trend</span></:default>
          </EuiStat>
        </div>
        <div dir="rtl" style="width: 400px">
          <EuiStat @description="Desc" data-rtl>
            <:title><span data-value>42</span></:title>
          </EuiStat>
        </div>
      </template>
    );
    const root = el(this.element, '[data-ltr]');
    const title = el(this.element, '[data-ltr] .euiStat__title');
    const order = () =>
      Array.from(root.children).map((child) =>
        child.matches('.euiStat__title')
          ? 'title'
          : child.matches('.euiStat__description')
            ? 'description'
            : 'children'
      );
    const edge = (scope: string) => {
      const box = el(this.element, scope).getBoundingClientRect();
      const value = el(this.element, `${scope} [data-value]`).getBoundingClientRect();
      return {
        start: Math.round(value.left - box.left),
        end: Math.round(box.right - value.right)
      };
    };
    assert.deepEqual(order(), ['description', 'title', 'children']);
    assert.strictEqual(getComputedStyle(root).textAlign, 'start');
    assert.strictEqual(getComputedStyle(root).alignItems, 'flex-start');
    assert.strictEqual(edge('[data-ltr]').start, 0, 'left aligned in LTR');
    assert.strictEqual(edge('[data-rtl]').end, 0, 'left is the start edge: right in RTL');

    state.align = 'right';
    await settled();
    assert.strictEqual(getComputedStyle(root).textAlign, 'end');
    assert.strictEqual(getComputedStyle(root).alignItems, 'flex-end');
    assert.strictEqual(edge('[data-ltr]').end, 0);

    state.align = 'center';
    await settled();
    assert.strictEqual(getComputedStyle(root).textAlign, 'center');
    assert.strictEqual(getComputedStyle(root).alignItems, 'center');

    state.reverse = true;
    await settled();
    assert.strictEqual(el(this.element, '[data-ltr]'), root, 'root kept');
    assert.strictEqual(
      el(this.element, '[data-ltr] .euiStat__title'),
      title,
      'title element kept when reversing'
    );
    assert.deepEqual(order(), ['title', 'description', 'children']);
  });

  test('stat loading: placeholder, label, pulse and reactive updates', async function (assert) {
    class State {
      @tracked loading = true;
      @tracked title = '42';
      @tracked color = 'success';
    }
    const state = new State();
    await render(
      <template>
        <EuiStat
          @title={{state.title}}
          @description="Answer"
          @isLoading={{state.loading}}
          @titleColor={{state.color}}
          data-stat
        />
      </template>
    );
    const title = el(this.element, '.euiStat__title');
    assert.dom(title).hasText('--').hasAttribute('aria-label', 'Statistic is loading');
    assert.strictEqual(
      getComputedStyle(title).animationName === 'none',
      !canAnimate(),
      'pulses unless reduced motion is requested'
    );
    if (canAnimate()) {
      assert.strictEqual(getComputedStyle(title).animationDuration, '1.5s');
      assert.strictEqual(getComputedStyle(title).animationIterationCount, 'infinite');
    }

    state.loading = false;
    state.title = '43';
    state.color = 'danger';
    await settled();
    assert.strictEqual(el(this.element, '.euiStat__title'), title, 'title kept');
    assert.dom(title).hasText('43').doesNotHaveAttribute('aria-label');
    assert.strictEqual(getComputedStyle(title).animationName, 'none');
    assert.strictEqual(getComputedStyle(title).color, rgb(light.colors.textDanger));

    const i18n = this.owner.lookup('service:eui-i18n') as {
      addTranslations: (translations: object) => void;
    };
    i18n.addTranslations({ euiStat: { loadingText: 'Wird geladen' } });
    await clearRender();
    await render(
      <template><EuiStat @title="1" @description="d" @isLoading={{true}} /></template>
    );
    assert.dom('.euiStat__title').hasAttribute('aria-label', 'Wird geladen');
  });

  // ------------------------------------------------- Providers and contrast

  test('light/dark follow the nearest provider; siblings stay isolated', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiCallOut @color="success" @title="t" data-callout>b</EuiCallOut>
          <EuiEmptyPrompt @color="plain" @title="t" @footer="f" data-prompt />
          <EuiStat @title="1" @description="d" data-stat />
          <EuiEmotionProvider @colorMode="light">
            <EuiStat @title="1" @description="d" data-fixed-light />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiCallOut @color="success" @title="t" data-sibling-callout />
          <EuiStat @title="1" @description="d" data-sibling-stat />
        </EuiEmotionProvider>
      </template>
    );
    const callout = el(this.element, '[data-callout]');
    assert.strictEqual(
      getComputedStyle(callout).backgroundColor,
      rgb(light.colors.backgroundBaseSuccess)
    );

    state.mode = 'dark';
    await settled();

    assert.strictEqual(el(this.element, '[data-callout]'), callout, 'element kept');
    assert.strictEqual(
      getComputedStyle(callout).backgroundColor,
      rgb(dark.colors.backgroundBaseSuccess)
    );
    assert.strictEqual(
      getComputedStyle(callout).borderTopColor,
      rgb(dark.colors.borderBaseSuccess)
    );
    assert.strictEqual(
      style(this.element, '[data-callout] .euiCallOutHeader__title').color,
      rgb(dark.colors.textHeading)
    );
    assert.strictEqual(
      style(this.element, '[data-callout] .euiCallOut__additionalContent').color,
      rgb(dark.colors.textParagraph)
    );
    assert.strictEqual(
      style(this.element, '[data-prompt]').backgroundColor,
      rgb(dark.colors.backgroundBasePlain)
    );
    assert.strictEqual(
      style(this.element, '[data-prompt] .euiEmptyPrompt__footer').backgroundColor,
      rgb(dark.colors.body)
    );
    assert.strictEqual(
      style(this.element, '[data-stat] .euiStat__title').color,
      rgb(dark.colors.fullShade)
    );
    assert.strictEqual(
      style(this.element, '[data-fixed-light] .euiStat__title').color,
      rgb(light.colors.fullShade),
      'nested light provider'
    );
    assert.strictEqual(
      style(this.element, '[data-sibling-callout]').backgroundColor,
      rgb(light.colors.backgroundBaseSuccess),
      'sibling callout isolated'
    );
    assert.strictEqual(
      style(this.element, '[data-sibling-stat] .euiStat__title').color,
      rgb(light.colors.fullShade),
      'sibling stat isolated'
    );
  });

  test('native token overrides (JS objects) and high contrast reach all three', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider
          @borealisOverrides={{state.overrides}}
          @highContrastMode={{state.contrast}}
        >
          <EuiCallOut @color="danger" @title="t" data-callout>b</EuiCallOut>
          <EuiEmptyPrompt @title="t" @footer="f" data-prompt />
          <EuiEmptyPrompt @color="plain" @title="t" @footer="f" data-plain />
          <EuiStat @title="1" @description="d" @titleColor="success" data-stat />
        </EuiEmotionProvider>
        <EuiCallOut @color="danger" @title="t" data-outside />
      </template>
    );
    assert.strictEqual(
      style(this.element, '[data-prompt] .euiEmptyPrompt__footer').borderTopStyle,
      'none'
    );

    state.overrides = {
      colors: {
        LIGHT: {
          backgroundBaseDanger: '#123456',
          borderBaseDanger: '#654321',
          textSuccess: '#0a0b0c'
        }
      }
    };
    await settled();
    assert.strictEqual(style(this.element, '[data-callout]').backgroundColor, 'rgb(18, 52, 86)');
    assert.strictEqual(style(this.element, '[data-callout]').borderTopColor, 'rgb(101, 67, 33)');
    assert.strictEqual(style(this.element, '[data-stat] .euiStat__title').color, 'rgb(10, 11, 12)');
    assert.strictEqual(
      style(this.element, '[data-outside]').backgroundColor,
      rgb(light.colors.backgroundBaseDanger),
      'overrides stay scoped'
    );

    state.overrides = {};
    state.contrast = 'preferred';
    await settled();
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    const callout = style(this.element, '[data-callout]');
    assert.strictEqual(callout.borderTopStyle, 'solid');
    assert.strictEqual(callout.borderTopWidth, hc.border.width.thin);
    assert.strictEqual(callout.borderTopColor, rgb(token(hc, 'borderBase', 'danger')));
    const footer = style(this.element, '[data-prompt] .euiEmptyPrompt__footer');
    assert.strictEqual(footer.borderTopStyle, 'solid', 'preferred contrast borders the transparent footer');
    assert.strictEqual(
      style(this.element, '[data-plain] .euiEmptyPrompt__footer').borderTopColor,
      rgb(token(hc, 'borderBase', 'plain')),
      'plain footer separator in contrast mode'
    );
    assert.strictEqual(
      style(this.element, '[data-plain]').borderTopStyle,
      'solid',
      'contrast panel border on the prompt'
    );

    await clearRender();
    assert.dom('.euiCallOut, .euiEmptyPrompt, .euiStat').doesNotExist('teardown');
  });
});
