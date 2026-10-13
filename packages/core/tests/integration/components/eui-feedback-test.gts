import { tracked } from '@glimmer/tracking';
import { array } from '@ember/helper';
import {
  clearRender,
  click,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import { getTokenName } from '@elastic/eui-theme-common';

import EuiAccordion from '#src/components/eui-accordion.gts';
import EuiComment from '#src/components/eui-comment.gts';
import EuiCommentList from '#src/components/eui-comment-list.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiGlobalToastList from '#src/components/eui-global-toast-list.gts';
import EuiNotificationEvent from '#src/components/eui-notification-event.gts';
import EuiToast from '#src/components/eui-toast.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type EuiToasterService from '#src/services/eui-toaster.ts';
import type { EuiToastColor } from '#src/components/eui-toast.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

type Colors = Record<string, string>;

function token(theme: typeof light, base: string, color: string): string {
  return (theme.colors as unknown as Colors)[getTokenName(base, color)]!;
}

function el(root: Element | Document, selector: string): HTMLElement {
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

/** Lets ResizeObserver callbacks and transitions start, then waits for Ember. */
async function layoutSettled() {
  for (let frame = 0; frame < 3; frame++)
    await new Promise((resolve) => requestAnimationFrame(resolve));
  await settled();
}

/** Media rule conditions whose style rules mention `className`. */
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

/** The Emotion class: the generated one among stable class names. */
function emotionClass(element: Element): string {
  return Array.from(element.classList).find((name) => /^eui-spike-/.test(name))!;
}

const canAnimate = () =>
  window.matchMedia('(prefers-reduced-motion: no-preference)').matches;

const TOAST_COLORS: EuiToastColor[] = [
  'primary',
  'success',
  'warning',
  'danger'
];
const MESSAGES = ['First message', 'Second message', 'Third message'];
const noop = () => {};

module('Integration | Component | Borealis feedback', function (hooks) {
  setupRenderingTest(hooks);

  // -------------------------------------------------------------- Accordion

  test('accordion: toggles open/closed with aria, inert region, measured height and rotated arrow', async function (assert) {
    const toggles: boolean[] = [];
    const onToggle = (isOpen: boolean) => toggles.push(isOpen);
    await render(
      <template>
        <EuiAccordion @id="acc" @onToggle={{onToggle}} data-acc>
          <:buttonContent>Details</:buttonContent>
          <:content><p style="height: 40px; margin: 0">Content</p></:content>
        </EuiAccordion>
      </template>
    );
    const root = el(this.element, '[data-acc]');
    const button = el(root, '.euiAccordion__button');
    const arrow = el(root, '.euiAccordion__arrow');
    const region = el(root, '.euiAccordion__childWrapper');

    assert.dom(button).hasTagName('button').hasAttribute('type', 'button');
    assert.dom(button).hasAttribute('aria-expanded', 'false').hasAttribute('aria-controls', 'acc');
    assert.dom(region).hasAttribute('id', 'acc').hasAttribute('role', 'group');
    assert.dom(region).hasAttribute('aria-labelledby', button.id);
    assert.true(region.inert, 'closed content is inert');
    assert.strictEqual(region.style.blockSize, '0px');
    assert.strictEqual(getComputedStyle(region).opacity, '0');
    assert.strictEqual(getComputedStyle(region).overflow, 'hidden');
    // the arrow duplicates the trigger: hidden and out of the tab order
    assert.dom(arrow).hasAttribute('aria-hidden', 'true').hasAttribute('tabindex', '-1');
    assert.dom(arrow).hasAttribute('aria-controls', 'acc').hasAttribute('aria-labelledby', button.id);
    assert.strictEqual(getComputedStyle(arrow).transform, 'matrix(1, 0, 0, 1, 0, 0)');
    assert.strictEqual(getComputedStyle(arrow).flexShrink, '0');

    await click(button);
    await layoutSettled();
    assert.strictEqual(el(this.element, '[data-acc]'), root, 'root kept');
    assert.strictEqual(el(root, '.euiAccordion__button'), button, 'button kept');
    assert.dom(root).hasClass('euiAccordion-isOpen');
    assert.dom(button).hasAttribute('aria-expanded', 'true');
    assert.dom(arrow).hasAttribute('aria-expanded', 'true');
    assert.false(region.inert, 'open content is not inert');
    await waitUntil(() => region.style.blockSize === '40px', { timeout: 2000 });
    assert.strictEqual(region.style.blockSize, '40px', 'measured (unscaled) content height');
    const rotated = getComputedStyle(arrow).transform.split(/,\s*/);
    assert.strictEqual(Number(rotated[1]), 1, 'arrow rotated 90deg');
    assert.strictEqual(Number(rotated[2]), -1, 'arrow rotated 90deg');

    await click(arrow);
    assert.dom(root).doesNotHaveClass('euiAccordion-isOpen');
    assert.strictEqual(region.style.blockSize, '0px');
    assert.deepEqual(toggles, [true, false]);

    // Upstream trigger styles: small text, flex, start aligned, underline on hover
    const trigger = getComputedStyle(button);
    assert.strictEqual(trigger.display, 'flex');
    assert.strictEqual(trigger.flexGrow, '1');
    assert.strictEqual(trigger.textAlign, 'start', 'logical start alignment');
    assert.strictEqual(trigger.lineHeight, light.size.l);
    assert.strictEqual(trigger.backgroundColor, 'rgba(0, 0, 0, 0)', 'scoped button reset');
    assert.strictEqual(trigger.borderTopStyle, 'none');
    assert.strictEqual(style(root, '.euiAccordion__triggerWrapper').display, 'flex');
    assert.strictEqual(style(root, '.euiAccordion__triggerWrapper').alignItems, 'center');
  });

  test('accordion: arrow placement (left/right/none) with logical margins in LTR and RTL', async function (assert) {
    await render(
      <template>
        {{#each (array "ltr" "rtl") as |dir|}}
          <div dir={{dir}} data-dir={{dir}}>
            <EuiAccordion @arrowDisplay="left" data-left>
              <:buttonContent>Left</:buttonContent>
              <:content>c</:content>
            </EuiAccordion>
            <EuiAccordion @arrowDisplay="right" @extraAction={{true}} data-right>
              <:buttonContent>Right</:buttonContent>
              <:content>c</:content>
              <:extraAction><button type="button" data-extra>x</button></:extraAction>
            </EuiAccordion>
          </div>
        {{/each}}
        <EuiAccordion @arrowDisplay="none" data-none>
          <:buttonContent>None</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
        <EuiAccordion @arrowDisplay="none" @buttonElement="div" data-div>
          <:buttonContent>Div trigger</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
      </template>
    );
    const xs = light.size.xs;
    for (const dir of ['ltr', 'rtl']) {
      const scope = el(this.element, `[data-dir="${dir}"]`);
      const leftRoot = el(scope, '[data-left]');
      const leftWrapper = el(leftRoot, '.euiAccordion__triggerWrapper');
      assert.strictEqual(leftWrapper.firstElementChild, el(leftRoot, '.euiAccordion__arrow'), `${dir}: left arrow comes first`);
      const leftArrow = getComputedStyle(el(leftRoot, '.euiAccordion__arrow'));
      assert.strictEqual(dir === 'ltr' ? leftArrow.marginRight : leftArrow.marginLeft, xs, `${dir}: gap after a start arrow`);
      const leftArrowBox = el(leftRoot, '.euiAccordion__arrow').getBoundingClientRect();
      const leftButtonBox = el(leftRoot, '.euiAccordion__button').getBoundingClientRect();
      assert.strictEqual(
        dir === 'ltr' ? leftArrowBox.left < leftButtonBox.left : leftArrowBox.left > leftButtonBox.left,
        true,
        `${dir}: the start arrow sits on the start side`
      );

      const rightRoot = el(scope, '[data-right]');
      const rightWrapper = el(rightRoot, '.euiAccordion__triggerWrapper');
      assert.strictEqual(rightWrapper.lastElementChild, el(rightRoot, '.euiAccordion__arrow'), `${dir}: end arrow after the extra action`);
      const rightArrow = getComputedStyle(el(rightRoot, '.euiAccordion__arrow'));
      assert.strictEqual(dir === 'ltr' ? rightArrow.marginLeft : rightArrow.marginRight, xs, `${dir}: gap before an end arrow`);
      assert.strictEqual(style(rightRoot, '.euiAccordion__optionalAction').flexShrink, '0');
      assert.dom(el(rightRoot, '.euiAccordion__optionalAction [data-extra]')).exists();
    }

    assert.dom('[data-none] .euiAccordion__arrow').doesNotExist('no arrow with a button trigger');
    // A non-interactive trigger forces the arrow back, as the focusable control
    assert.dom('[data-div] .euiAccordion__button').hasTagName('div').doesNotHaveAttribute('aria-expanded').doesNotHaveAttribute('type');
    assert.dom('[data-div] .euiAccordion__arrow').hasAttribute('tabindex', '0').hasAttribute('aria-hidden', 'false').hasAttribute('aria-expanded', 'false');
    await click('[data-div] .euiAccordion__arrow');
    assert.dom('[data-div]').hasClass('euiAccordion-isOpen');
  });

  test('accordion: disabled and loading states', async function (assert) {
    class State {
      @tracked disabled = true;
      @tracked loading = true;
    }
    const state = new State();
    let toggles = 0;
    const onToggle = () => toggles++;
    await render(
      <template>
        <EuiAccordion @isDisabled={{state.disabled}} @onToggle={{onToggle}} data-disabled>
          <:buttonContent>Disabled</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
        <EuiAccordion
          @isLoading={{state.loading}}
          @isLoadingMessage={{true}}
          @initialIsOpen={{true}}
          @extraAction={{true}}
          data-loading
        >
          <:buttonContent>Loading</:buttonContent>
          <:content><span data-content>Ready</span></:content>
          <:extraAction><button type="button" data-extra>x</button></:extraAction>
        </EuiAccordion>
        <EuiAccordion @isLoading={{true}} @isLoadingMessage="Fetching rows" @initialIsOpen={{true}} data-message>
          <:buttonContent>Custom</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
      </template>
    );
    const trigger = el(this.element, '[data-disabled] .euiAccordion__button') as HTMLButtonElement;
    assert.true(trigger.disabled, 'trigger disabled');
    assert.strictEqual(getComputedStyle(trigger).cursor, 'not-allowed');
    assert.strictEqual(getComputedStyle(trigger).color, rgb(light.colors.disabledText));
    assert.true((el(this.element, '[data-disabled] .euiAccordion__arrow') as HTMLButtonElement).disabled, 'arrow disabled');
    await click('[data-disabled] .euiAccordion__arrow').catch(() => {});
    assert.strictEqual(toggles, 0, 'disabled accordions do not toggle');
    assert.dom('[data-disabled]').doesNotHaveClass('euiAccordion-isOpen');

    state.disabled = false;
    await settled();
    assert.strictEqual(el(this.element, '[data-disabled] .euiAccordion__button'), trigger, 'trigger kept');
    assert.false(trigger.disabled);
    assert.notStrictEqual(getComputedStyle(trigger).color, rgb(light.colors.disabledText));
    await click(trigger);
    assert.strictEqual(toggles, 1);

    const loading = el(this.element, '[data-loading]');
    assert.dom('.euiAccordion__optionalAction .euiBorealisLoadingSpinner', loading).exists('spinner replaces the extra action');
    assert.dom('[data-extra]', loading).doesNotExist();
    const children = el(loading, '.euiAccordion__children');
    assert.dom(children).hasClass('euiAccordion__children-isLoading');
    assert.strictEqual(getComputedStyle(children).display, 'flex');
    assert.strictEqual(getComputedStyle(children).alignItems, 'center');
    assert.strictEqual(style(loading, '.euiAccordion__spinner').marginRight, light.size.xs);
    assert.dom('.euiText p', children).hasText('Loading');
    assert.dom('[data-message] .euiAccordion__children p').hasText('Fetching rows');

    state.loading = false;
    await settled();
    assert.strictEqual(el(loading, '.euiAccordion__children'), children, 'children kept');
    assert.dom(children).doesNotHaveClass('euiAccordion__children-isLoading');
    assert.dom('[data-content]', loading).hasText('Ready');
    assert.dom('[data-extra]', loading).exists();
  });

  test('accordion: padding sizes, trigger padding, borders and forceState', async function (assert) {
    class State {
      @tracked force: 'open' | 'closed' = 'closed';
    }
    const state = new State();
    const requested: boolean[] = [];
    const onToggle = (open: boolean) => requested.push(open);
    const buttonProps = { paddingSize: 'm' as const };
    await render(
      <template>
        {{#each (array "xs" "s" "m" "l" "xl") as |size|}}
          <EuiAccordion @paddingSize={{size}} @initialIsOpen={{true}} data-padding={{size}}>
            <:buttonContent>p</:buttonContent>
            <:content>c</:content>
          </EuiAccordion>
        {{/each}}
        <EuiAccordion @buttonProps={{buttonProps}} data-trigger-padding>
          <:buttonContent>p</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
        <EuiAccordion @borders="horizontal" data-horizontal>
          <:buttonContent>h</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
        <EuiAccordion @borders="horizontal" data-horizontal-2>
          <:buttonContent>h2</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
        <EuiAccordion @borders="all" data-all>
          <:buttonContent>a</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
        <EuiAccordion @forceState={{state.force}} @onToggle={{onToggle}} data-forced>
          <:buttonContent>f</:buttonContent>
          <:content><p style="height: 20px; margin: 0">c</p></:content>
        </EuiAccordion>
      </template>
    );
    const sizes: Record<string, string> = {
      xs: light.size.xs,
      s: light.size.s,
      m: light.size.base,
      l: light.size.l,
      xl: light.size.xl
    };
    for (const [size, value] of Object.entries(sizes))
      assert.strictEqual(style(this.element, `[data-padding="${size}"] .euiAccordion__children`).paddingTop, value, `padding ${size}`);

    const trigger = style(this.element, '[data-trigger-padding] .euiAccordion__button');
    assert.strictEqual(trigger.paddingTop, light.size.base, 'buttonProps.paddingSize');
    assert.strictEqual(trigger.paddingRight, light.size.base);
    assert.strictEqual(trigger.paddingLeft, '0px', 'no padding on the arrow side');

    const horizontal = style(this.element, '[data-horizontal]');
    assert.strictEqual(horizontal.borderTopStyle, 'solid');
    assert.strictEqual(horizontal.borderBottomStyle, 'solid');
    assert.strictEqual(horizontal.borderLeftStyle, 'none');
    assert.strictEqual(horizontal.borderTopColor, rgb(light.border.color));
    assert.strictEqual(style(this.element, '[data-horizontal-2]').borderTopStyle, 'none', 'adjacent bordered accordions share a border');
    const all = style(this.element, '[data-all]');
    assert.strictEqual(all.borderLeftStyle, 'solid');
    assert.strictEqual(all.borderLeftWidth, light.border.width.thin);

    const forced = el(this.element, '[data-forced]');
    await click(el(forced, '.euiAccordion__button'));
    assert.deepEqual(requested, [true], 'forceState only requests the change');
    assert.dom(forced).doesNotHaveClass('euiAccordion-isOpen');
    state.force = 'open';
    await layoutSettled();
    assert.strictEqual(el(this.element, '[data-forced]'), forced, 'root kept');
    assert.dom(forced).hasClass('euiAccordion-isOpen');
    await waitUntil(() => el(forced, '.euiAccordion__childWrapper').style.blockSize === '20px', { timeout: 2000 });
    assert.strictEqual(el(forced, '.euiAccordion__childWrapper').style.blockSize, '20px');
  });

  test('accordion: height transition only under reduced-motion no-preference; none for initially open', async function (assert) {
    await render(
      <template>
        <EuiAccordion data-closed>
          <:buttonContent>t</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
        <EuiAccordion @initialIsOpen={{true}} data-initial>
          <:buttonContent>t</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
        <EuiAccordion @element="fieldset" data-fieldset>
          <:buttonContent>Legend</:buttonContent>
          <:content>c</:content>
        </EuiAccordion>
      </template>
    );
    const wrapper = el(this.element, '[data-closed] .euiAccordion__childWrapper');
    assert.deepEqual(
      mediaConditionsFor(emotionClass(wrapper)),
      ['screen and (prefers-reduced-motion: no-preference)'],
      'the transition lives behind euiCanAnimate'
    );
    assert.strictEqual(
      getComputedStyle(wrapper).transitionProperty.includes('block-size') || getComputedStyle(wrapper).transitionProperty.includes('height'),
      canAnimate()
    );
    const initial = el(this.element, '[data-initial] .euiAccordion__childWrapper');
    assert.strictEqual(getComputedStyle(initial).transitionProperty, 'none', 'initially open: no transition');
    assert.strictEqual(getComputedStyle(initial).transitionDuration, '0s');
    await click('[data-initial] .euiAccordion__button');
    assert.strictEqual(
      getComputedStyle(initial).transitionDuration !== '0s',
      canAnimate(),
      'closing an initially open accordion turns the transition on'
    );
    await click('[data-initial] .euiAccordion__button');
    assert.strictEqual(getComputedStyle(initial).transitionDuration !== '0s', canAnimate(), 'and keeps it');

    assert.dom('[data-fieldset]').hasTagName('fieldset');
    assert.dom('[data-fieldset] .euiAccordion__button').hasTagName('legend').doesNotHaveAttribute('aria-expanded');
    assert.dom('[data-fieldset] .euiAccordion__arrow').hasAttribute('tabindex', '0').hasAttribute('aria-expanded', 'false');
  });

  // ------------------------------------------------------------------ Toast

  test('toast: every color sets the highlight, default notification icon and class', async function (assert) {
    await render(
      <template>
        {{#each TOAST_COLORS as |color|}}
          <EuiToast @color={{color}} @title="Title" data-color={{color}} />
        {{/each}}
        <EuiToast @title="Default" data-default />
        <EuiToast @color="none" @title="Neutral" data-none />
        <EuiToast @color="success" @iconType="check" @title="Custom" data-custom />
      </template>
    );
    for (const color of TOAST_COLORS) {
      const toast = el(this.element, `[data-color="${color}"]`);
      assert.dom(toast).hasClass('euiToast').hasClass(`euiToast--${color}`);
      const decor = el(toast, '.euiToastDecor');
      assert.dom(decor).hasAttribute('role', 'presentation');
      assert.strictEqual(getComputedStyle(decor, '::after').borderTopColor, rgb(token(light, 'borderStrong', color)), `${color}: highlight`);
      assert.strictEqual(getComputedStyle(decor, '::before').borderTopColor, rgb(token(light, 'backgroundLight', color)), `${color}: highlight track`);
      assert.strictEqual(
        getComputedStyle(decor, '::after').borderTopWidth,
        `${parseFloat(light.border.width.thin) + parseFloat(light.border.width.thick)}px`
      );
      assert.dom('svg.euiNotificationIcon', toast).exists({ count: 1 }, `${color}: default icon`);
      assert.dom('svg.euiNotificationIcon', toast).hasAttribute('aria-hidden', 'true');
    }
    assert.dom('[data-default]').hasClass('euiToast--primary', 'defaults to primary (upstream)');
    const base = style(this.element, '[data-default]');
    assert.strictEqual(base.backgroundColor, rgb(light.colors.backgroundBasePlain));
    assert.strictEqual(base.borderTopLeftRadius, light.border.radius.panel);
    assert.notStrictEqual(base.boxShadow, 'none', 'large shadow');
    assert.strictEqual(base.position, 'relative');
    assert.strictEqual(base.paddingBottom, light.size.base);
    assert.strictEqual(base.paddingLeft, light.size.base);
    assert.strictEqual(
      base.paddingTop,
      `${parseFloat(light.size.base) + parseFloat(light.border.width.thin) + parseFloat(light.border.width.thick)}px`,
      'top padding includes the highlight'
    );

    assert.dom('[data-none] svg').doesNotExist('neutral toasts have no default icon');
    assert.strictEqual(getComputedStyle(el(this.element, '[data-none] .euiToastDecor'), '::after').borderTopColor, 'rgba(0, 0, 0, 0)');

    const custom = el(this.element, '[data-custom] svg');
    assert.dom(custom).doesNotHaveClass('euiNotificationIcon').hasAttribute('aria-hidden', 'true');
    assert.strictEqual(getComputedStyle(custom).color, rgb(token(light, 'borderStrong', 'success')), 'custom icon in the highlight color');
  });

  test('toast: title, body, extra content, dismiss button, actions and a11y order', async function (assert) {
    let closed = 0;
    const onClose = () => closed++;
    const clicks: string[] = [];
    const actionProps = {
      primary: { children: 'Retry', onClick: () => clicks.push('primary'), 'data-test-subj': 'primary' },
      secondary: { children: 'Details', onClick: () => clicks.push('secondary'), 'data-test-subj': 'secondary' }
    };
    await render(
      <template>
        <EuiToast @title="Saved" @body="All good" @onClose={{onClose}} @actionProps={{actionProps}} data-full>
          <a href="#more" data-more>More</a>
        </EuiToast>
        <EuiToast @body="Only body" @onClose={{onClose}} data-body />
        <div dir="rtl"><EuiToast @title="RTL" @onClose={{onClose}} data-rtl /></div>
      </template>
    );
    const toast = el(this.element, '[data-full]');
    assert.dom('.euiScreenReaderOnly', toast).hasText('A new notification appears');
    const title = el(toast, '[data-test-subj="euiToastHeader__title"]');
    assert.dom(title).hasTagName('p').hasClass('euiTitle').hasText('Saved');
    const header = getComputedStyle(title);
    assert.strictEqual(header.display, 'flex');
    assert.strictEqual(header.fontWeight, String(light.font.weight.bold));
    assert.strictEqual(header.color, rgb(light.colors.textHeading));
    assert.strictEqual(header.paddingRight, light.size.l, 'room for the dismiss button');
    assert.strictEqual(header.marginTop, '0px');

    const close = el(toast, '[data-test-subj="toastCloseButton"]');
    assert.dom(close).hasAttribute('aria-label', 'Dismiss toast').hasClass('euiButtonIcon');
    // DOM order: title, dismiss button, then the body
    const content = title.parentElement!;
    const order = Array.from(content.children).map((child) => child.getAttribute('data-test-subj'));
    assert.deepEqual(order, ['euiToastHeader__title', 'toastCloseButton', 'euiToastBody']);
    assert.strictEqual(getComputedStyle(close).position, 'absolute');
    assert.strictEqual(getComputedStyle(close).right, light.size.s);
    assert.dom('[data-test-subj="euiToastText"]', toast).hasClass('euiToast__text').hasText('All good');
    assert.strictEqual(style(toast, '.euiToast__text').color, rgb(light.colors.textParagraph));
    assert.dom('.euiToast__additionalContent [data-more]', toast).exists();

    // body without title: body first, then the dismiss button
    const bodyOnly = el(el(this.element, '[data-body]'), '[data-test-subj="euiToastBody"]').parentElement!;
    assert.deepEqual(
      Array.from(bodyOnly.children).map((child) => child.getAttribute('data-test-subj')),
      ['euiToastBody', 'toastCloseButton']
    );

    const rtlClose = getComputedStyle(el(this.element, '[data-rtl] [data-test-subj="toastCloseButton"]'));
    assert.strictEqual(rtlClose.left, light.size.s, 'RTL: the dismiss button sits in the start corner');
    assert.strictEqual(style(this.element, '[data-rtl] .euiToastHeader__title').paddingLeft, light.size.l);

    await click(close);
    assert.strictEqual(closed, 1);

    const primary = el(toast, '[data-test-subj="primary"]');
    const secondary = el(toast, '[data-test-subj="secondary"]');
    assert.dom(primary).hasClass('euiButton').hasText('Retry');
    assert.dom(secondary).hasClass('euiButtonEmpty').hasText('Details');
    assert.strictEqual(getComputedStyle(primary.parentElement!).display, 'flex');
    assert.strictEqual(getComputedStyle(primary.parentElement!).columnGap, light.size.s);
    await click(primary);
    await click(secondary);
    assert.deepEqual(clicks, ['primary', 'secondary']);
  });

  test('toast: reactive color and lifetime animation without element replacement; animation behind reduced motion', async function (assert) {
    class State {
      @tracked color: EuiToastColor = 'success';
      @tracked ms: number | undefined = undefined;
    }
    const state = new State();
    await render(
      <template>
        <EuiToast @color={{state.color}} @animationMs={{state.ms}} @title="t" style="max-width: 300px" data-toast />
      </template>
    );
    const toast = el(this.element, '[data-toast]');
    const decor = el(toast, '.euiToastDecor');
    assert.strictEqual(getComputedStyle(decor, '::after').animationName, 'none');
    state.color = 'danger';
    state.ms = 5000;
    await settled();
    assert.strictEqual(el(this.element, '[data-toast]'), toast, 'toast kept');
    assert.dom(toast).hasClass('euiToast--danger').doesNotHaveClass('euiToast--success');
    assert.strictEqual(toast.style.maxWidth, '300px', 'caller style kept');
    assert.strictEqual(getComputedStyle(toast).getPropertyValue('--euiToastAnimationMs').trim(), '5000ms');
    assert.strictEqual(getComputedStyle(decor, '::after').borderTopColor, rgb(token(light, 'borderStrong', 'danger')));
    assert.strictEqual(getComputedStyle(decor, '::after').animationName !== 'none', canAnimate(), 'countdown animates unless reduced motion');
    if (canAnimate()) assert.strictEqual(getComputedStyle(decor, '::after').animationDuration, '5s');
    assert.true(
      mediaConditionsFor(emotionClass(decor)).includes('screen and (prefers-reduced-motion: no-preference)'),
      'the countdown lives behind euiCanAnimate'
    );
  });

  // -------------------------------------------------------- GlobalToastList

  test('global toast list: sides, fixed position, :empty padding and role', async function (assert) {
    const toaster = this.owner.lookup('service:eui-toaster') as EuiToasterService;
    class State {
      @tracked side: 'left' | 'right' = 'right';
    }
    const state = new State();
    await render(<template><EuiGlobalToastList @side={{state.side}} @toastLifeTimeMs={{60000}} /></template>);
    const list = el(this.element, '.euiGlobalToastList');
    assert.dom(list).hasAttribute('role', 'log').hasAttribute('aria-live', 'polite');
    assert.strictEqual(list.childElementCount, 0);
    assert.true(list.matches(':empty'), 'no toasts: the list is :empty');
    let computed = getComputedStyle(list);
    assert.strictEqual(computed.position, 'fixed');
    assert.strictEqual(computed.zIndex, String(light.levels.toast));
    assert.strictEqual(computed.paddingTop, '0px', 'no padding while empty');
    assert.strictEqual(computed.width, `${light.base * 27.5}px`);
    assert.strictEqual(computed.bottom, '0px');

    // Ember timers keep settled() waiting: pause them (hover) before settling.
    toaster.show({ id: 'a', title: 'Hello' });
    await waitUntil(() => list.querySelector('.euiToast'));
    await triggerEvent(list, 'mouseenter');
    assert.strictEqual(el(this.element, '.euiGlobalToastList'), list, 'list kept');
    computed = getComputedStyle(list);
    assert.strictEqual(computed.paddingTop, light.size.base);
    assert.strictEqual(computed.right, '0px');
    assert.strictEqual(computed.paddingLeft, `${light.base * 4}px`, 'shadow room on the inner side (above m)');
    assert.strictEqual(computed.paddingRight, light.size.base);
    const item = el(list, '.euiGlobalToastListItem');
    assert.dom(item).hasClass('euiToast');
    assert.notStrictEqual(getComputedStyle(item).animationName, 'none', 'show animation');
    assert.strictEqual(getComputedStyle(item).flexShrink, '0');

    state.side = 'left';
    await settled();
    computed = getComputedStyle(list);
    assert.strictEqual(computed.left, '0px');
    assert.strictEqual(computed.paddingRight, `${light.base * 4}px`);
    toaster.toasts = [];
    await settled();
  });

  test('global toast list: lifetime timers dismiss with a fade, pause while hovered, clear all and count badge', async function (assert) {
    const toaster = this.owner.lookup('service:eui-toaster') as EuiToasterService;
    const dismissed: string[] = [];
    const dismiss = (toast: { id?: string }) => dismissed.push(toast.id!);
    let cleared = 0;
    const onClear = () => cleared++;
    await render(
      <template>
        <EuiGlobalToastList
          @toastLifeTimeMs={{150}}
          @dismissToast={{dismiss}}
          @onClearAllToasts={{onClear}}
          @showNotificationBadge={{true}}
        />
      </template>
    );
    const list = el(this.element, '.euiGlobalToastList');

    // A short-lived toast fades (dismissed styles) and is removed once.
    toaster.show({ id: 'short', title: 'Short', toastLifeTimeMs: 30 });
    await waitUntil(() => list.querySelector('.euiToast'));
    const toast = el(list, '.euiToast');
    assert.strictEqual(getComputedStyle(toast).getPropertyValue('--euiToastAnimationMs').trim(), '30ms', 'countdown matches the lifetime');
    await waitUntil(() => getComputedStyle(toast).transitionProperty.includes('opacity'), { timeout: 2000 });
    assert.dom(el(list, '[data-test-subj="euiGlobalToastListNotificationBadge"].euiNotificationBadge')).hasText('1');
    await waitUntil(() => toaster.toasts.length === 0, { timeout: 2000 });
    await settled();
    assert.deepEqual(dismissed, ['short'], 'dismissed once after the fade');
    assert.dom('.euiToast', list).doesNotExist();

    // Hovering pauses the timers; leaving resumes them.
    toaster.show({ id: 'paused', title: 'Paused' });
    await waitUntil(() => list.querySelector('.euiToast'));
    await triggerEvent(list, 'mouseenter');
    await new Promise((resolve) => setTimeout(resolve, 450));
    assert.strictEqual(toaster.toasts.length, 1, 'paused while hovered');
    await triggerEvent(list, 'mouseleave');
    await waitUntil(() => toaster.toasts.length === 0, { timeout: 2000 });
    assert.deepEqual(dismissed, ['short', 'paused']);

    // Focus inside a toast also pauses (upstream onFocus/onBlur).
    toaster.show({ id: 'focus', title: 'Focus', onClose: noop });
    await waitUntil(() => list.querySelector('[data-test-subj="toastCloseButton"]'));
    el(list, '[data-test-subj="toastCloseButton"]').focus();
    await new Promise((resolve) => setTimeout(resolve, 450));
    assert.strictEqual(toaster.toasts.length, 1, 'paused while focused');
    el(list, '[data-test-subj="toastCloseButton"]').blur();
    await waitUntil(() => toaster.toasts.length === 0, { timeout: 2000 });

    // "Clear all" appears at three toasts and dismisses them immediately.
    toaster.show({ id: 'one', title: '1', toastLifeTimeMs: 60000 });
    toaster.show({ id: 'two', title: '2', toastLifeTimeMs: 60000 });
    await waitUntil(() => list.querySelectorAll('.euiToast').length === 2);
    await triggerEvent(list, 'mouseenter');
    assert.dom('[data-test-subj="euiClearAllToastsButton"]', list).doesNotExist('below the threshold');
    toaster.show({ id: 'three', title: '3', toastLifeTimeMs: 60000 });
    await waitUntil(() => list.querySelectorAll('.euiToast').length === 3);
    await triggerEvent(list, 'mouseenter');
    const clear = el(list, '[data-test-subj="euiClearAllToastsButton"]');
    assert.dom(clear).hasText('Clear all').hasAttribute('aria-label', 'Clear all toast notifications');
    assert.strictEqual(getComputedStyle(clear).position, 'sticky', 'the button itself is the sticky list item');
    assert.dom(clear).hasClass('euiGlobalToastListItem').hasClass('euiButton');
    assert.dom(el(list, '[data-test-subj="euiGlobalToastListNotificationBadge"]')).hasText('3');
    assert.strictEqual(style(list, '[data-test-subj="euiGlobalToastListNotificationBadge"]').position, 'absolute');
    await click(clear);
    assert.deepEqual(dismissed.slice(-3), ['one', 'two', 'three']);
    assert.strictEqual(cleared, 1);
    assert.strictEqual(toaster.toasts.length, 0);
    assert.true(el(this.element, '.euiGlobalToastList').matches(':empty'));
  });

  // ---------------------------------------------------------------- Comments

  test('comment list: timeline layout, regular/update/custom events, avatars and borders', async function (assert) {
    await render(
      <template>
        <EuiCommentList data-list>
          <EuiComment @eventIcon="pencil" @eventIconAriaLabel="edit" data-regular>
            <:username>janed</:username>
            <:event>added a comment</:event>
            <:timestamp>on Jan 1</:timestamp>
            <:actions><button type="button" data-action>…</button></:actions>
            <:body><p>Looks good</p></:body>
          </EuiComment>
          <EuiComment @timelineIcon="tag" @eventIcon="tag" data-update>
            <:username>bot</:username>
            <:event>added a tag</:event>
          </EuiComment>
          <EuiComment data-custom>
            <:body><p>Custom body</p></:body>
          </EuiComment>
        </EuiCommentList>
      </template>
    );
    const list = el(this.element, '[data-list]');
    assert.dom(list).hasTagName('ol').hasAttribute('role', 'list').hasClass('euiCommentList');
    assert.strictEqual(getComputedStyle(list).display, 'flex');
    assert.strictEqual(getComputedStyle(list).flexDirection, 'column');
    assert.strictEqual(getComputedStyle(list).rowGap, light.size.l, 'gutter l (default)');
    assert.strictEqual(getComputedStyle(list).listStyleType, 'none');
    assert.strictEqual(getComputedStyle(list).paddingLeft, '0px');

    const regular = el(list, '[data-regular]');
    assert.dom(regular).hasTagName('li').hasClass('euiComment');
    assert.strictEqual(getComputedStyle(regular).display, 'flex');
    const iconColumn = regular.firstElementChild as HTMLElement;
    assert.strictEqual(getComputedStyle(iconColumn).alignItems, 'flex-start', 'regular: top aligned');
    assert.strictEqual(getComputedStyle(iconColumn).marginRight, light.size.base);
    // The vertical timeline line between avatars (upstream EuiTimeline)
    const line = getComputedStyle(iconColumn, '::before');
    assert.strictEqual(line.position, 'absolute');
    assert.strictEqual(line.borderLeftWidth, light.border.width.thick);
    assert.strictEqual(line.borderLeftColor, rgb(light.border.color));
    assert.dom('.euiAvatar.euiCommentAvatar', iconColumn).exists('default user avatar');
    assert.dom('.euiCommentAvatar svg', iconColumn).hasAttribute('data-icon-type', 'user');
    assert.strictEqual(style(iconColumn, '.euiCommentAvatar').backgroundColor, rgb(light.colors.lightestShade), 'subdued avatar');

    const event = el(regular, '.euiCommentEvent');
    assert.dom(event).hasTagName('figure').hasAttribute('data-type', 'regular');
    assert.dom(el(event, '.euiCommentEvent__header')).hasTagName('figcaption');
    const eventStyle = getComputedStyle(event);
    assert.strictEqual(eventStyle.borderTopStyle, 'solid');
    assert.strictEqual(eventStyle.borderTopWidth, light.border.width.thin);
    assert.strictEqual(eventStyle.borderTopColor, rgb(light.colors.borderBaseSubdued), 'highlighted events get a subdued border');
    assert.strictEqual(eventStyle.borderTopLeftRadius, light.border.radius.panel);
    assert.strictEqual(eventStyle.overflow, 'hidden');
    assert.strictEqual(eventStyle.marginTop, '0px', 'figure reset');
    const header = el(event, '.euiCommentEvent__header');
    assert.strictEqual(getComputedStyle(header).borderBottomStyle, 'solid');
    assert.strictEqual(style(header, '.euiPanelBorealis').backgroundColor, rgb(light.colors.backgroundBaseHighlighted));
    assert.strictEqual(style(header, '.euiPanelBorealis').paddingTop, light.size.s);
    assert.strictEqual(style(header, '.euiCommentEvent__headerMain').columnGap, light.size.s);
    assert.strictEqual(style(header, '.euiCommentEvent__headerUsername').fontWeight, String(light.font.weight.semiBold));
    assert.dom('.euiCommentEvent__headerTimestamp time', header).hasText('on Jan 1');
    assert.dom('.euiCommentEvent__headerActions [data-action]', header).exists();
    const eventIcon = el(header, '.euiCommentEvent__headerEventIcon');
    assert.dom(eventIcon).hasClass('euiAvatar').hasAttribute('aria-label', 'edit').doesNotHaveAttribute('aria-hidden');
    assert.strictEqual(getComputedStyle(eventIcon).marginRight, light.size.xs);
    assert.strictEqual(style(event, '.euiCommentEvent__body').paddingTop, light.size.s);

    const update = el(list, '[data-update]');
    assert.strictEqual(getComputedStyle(update.firstElementChild!).alignItems, 'center', 'update: centered');
    assert.dom('.euiCommentAvatar svg', update).hasAttribute('data-icon-type', 'tag');
    const updateEvent = el(update, '.euiCommentEvent');
    assert.dom(updateEvent).hasTagName('div').hasAttribute('data-type', 'update');
    assert.strictEqual(getComputedStyle(updateEvent).borderTopStyle, 'none');
    assert.strictEqual(style(updateEvent, '.euiPanelBorealis').backgroundColor, 'rgba(0, 0, 0, 0)', 'transparent update');
    assert.dom('.euiCommentEvent__headerEventIcon', updateEvent).hasAttribute('aria-hidden', 'true');
    assert.dom('.euiCommentEvent__body', updateEvent).doesNotExist();

    const custom = el(list, '[data-custom] .euiCommentEvent');
    assert.dom(custom).hasAttribute('data-type', 'custom');
    assert.dom('.euiCommentEvent__header', custom).doesNotExist();
    assert.strictEqual(style(custom, '.euiCommentEvent__body').paddingTop, '0px');
  });

  test('comment: event colors, gutter sizes, custom timeline content and RTL', async function (assert) {
    class State {
      @tracked color: 'primary' | 'danger' = 'primary';
      @tracked gutter: 'm' | 'xl' = 'm';
    }
    const state = new State();
    await render(
      <template>
        <EuiCommentList @gutterSize={{state.gutter}} data-list>
          <EuiComment @eventColor={{state.color}} data-colored>
            <:username>u</:username>
            <:event>e</:event>
            <:body>b</:body>
          </EuiComment>
          <EuiComment data-block>
            <:timelineIcon><span data-custom-avatar>JD</span></:timelineIcon>
            <:username>u</:username>
            <:event>e</:event>
          </EuiComment>
        </EuiCommentList>
        <div dir="rtl">
          <EuiCommentList><EuiComment data-rtl><:username>u</:username><:event>e</:event></EuiComment></EuiCommentList>
        </div>
      </template>
    );
    const list = el(this.element, '[data-list]');
    assert.strictEqual(getComputedStyle(list).rowGap, light.size.base, 'gutter m');
    const colored = el(this.element, '[data-colored] .euiCommentEvent');
    assert.strictEqual(getComputedStyle(colored).borderTopColor, rgb(light.colors.borderBasePrimary));
    assert.strictEqual(style(colored, '.euiPanelBorealis').backgroundColor, rgb(light.colors.backgroundBasePrimary));

    state.color = 'danger';
    state.gutter = 'xl';
    await settled();
    assert.strictEqual(el(this.element, '[data-colored] .euiCommentEvent'), colored, 'event kept');
    assert.strictEqual(getComputedStyle(colored).borderTopColor, rgb(light.colors.borderBaseDanger));
    assert.strictEqual(getComputedStyle(list).rowGap, light.size.xl);

    assert.dom('[data-block] [data-custom-avatar]').hasText('JD');
    assert.dom('[data-block] .euiCommentAvatar').doesNotExist();

    const rtlIcon = el(this.element, '[data-rtl]').firstElementChild as HTMLElement;
    assert.strictEqual(getComputedStyle(rtlIcon).marginLeft, light.size.base, 'RTL: avatar gap on the logical end');
    assert.strictEqual(getComputedStyle(rtlIcon).marginRight, '0px');
  });

  // ------------------------------------------------------ NotificationEvent

  test('notification event: read/unread states react without replacing elements', async function (assert) {
    class State {
      @tracked isRead = false;
    }
    const state = new State();
    const reads: boolean[] = [];
    const onRead = () => {
      reads.push(state.isRead);
      state.isRead = !state.isRead;
    };
    await render(
      <template>
        <EuiNotificationEvent @id="btn" @title="With button" @messages={{MESSAGES}} @isRead={{state.isRead}} @onRead={{onRead}} data-button />
        <EuiNotificationEvent @id="icn" @title="With icon" @messages={{MESSAGES}} @isRead={{state.isRead}} data-icon />
        <EuiNotificationEvent @id="none" @title="No state" @messages={{MESSAGES}} data-none />
      </template>
    );
    const title = el(this.element, '[data-icon] .euiNotificationEvent__title');
    assert.dom(title).hasTagName('h2').hasClass('euiTitle');
    assert.strictEqual(getComputedStyle(title).fontWeight, String(light.font.weight.bold), 'unread: bold');
    assert.strictEqual(getComputedStyle(title).color, rgb(light.colors.textHeading));
    const dot = el(this.element, '[data-icon] .euiNotificationEventReadIcon svg');
    assert.dom(dot).hasAttribute('aria-label', 'With icon is unread').hasAttribute('title', 'Unread');
    assert.strictEqual(getComputedStyle(dot).color, rgb(light.colors.textPrimary), 'unread: filled primary dot');
    assert.notStrictEqual(getComputedStyle(dot).fill, 'none');
    const button = el(this.element, '[data-button] .euiNotificationEventReadButton');
    assert.dom(button).hasAttribute('aria-label', 'Mark With button as read').hasAttribute('title', 'Unread');
    assert.strictEqual(style(this.element, '[data-button] .euiNotificationEvent__readButton').marginRight, light.size.s);
    assert.dom('[data-none] .euiNotificationEvent__readButton').doesNotExist();

    await click(button);
    assert.deepEqual(reads, [false]);
    assert.strictEqual(el(this.element, '[data-icon] .euiNotificationEvent__title'), title, 'title kept');
    assert.strictEqual(el(this.element, '[data-button] .euiNotificationEventReadButton'), button, 'button kept');
    assert.strictEqual(getComputedStyle(title).fontWeight, String(light.font.weight.regular), 'read: regular');
    assert.dom(dot).hasAttribute('aria-label', 'With icon is read').hasAttribute('title', 'Read');
    assert.strictEqual(getComputedStyle(dot).fill, 'rgba(0, 0, 0, 0)', 'read: hollow dot');
    assert.strictEqual(getComputedStyle(dot).stroke, rgb(light.colors.textSubdued));
    assert.dom(button).hasAttribute('aria-label', 'Mark With button as unread');
    assert.strictEqual(style(button, '.euiButtonIcon__icon').fill, 'rgba(0, 0, 0, 0)');
  });

  test('notification event: layout, meta, title action, messages accordion and context menu (LTR/RTL)', async function (assert) {
    let titleClicks = 0;
    const onClickTitle = () => titleClicks++;
    await render(
      <template>
        <div data-feed>
          <EuiNotificationEvent
            @id="e1"
            @type="Alert"
            @severity="Critical"
            @badgeColor="danger"
            @iconType="alert"
            @iconAriaLabel="Alert icon"
            @time="1 min ago"
            @title="CPU usage"
            @onClickTitle={{onClickTitle}}
            @messages={{MESSAGES}}
            @accordionButtonText="+ 2 more"
            @accordionHideText="hide"
            data-first
          >
            <:primaryAction><button type="button" data-primary>View</button></:primaryAction>
            <:contextMenu><span class="menu-item">Mute</span></:contextMenu>
          </EuiNotificationEvent>
          <EuiNotificationEvent @id="e2" @title="Second" @messages={{MESSAGES}} data-second />
        </div>
        <div dir="rtl">
          <EuiNotificationEvent @id="e3" @title="RTL" @time="now" @messages={{MESSAGES}} data-rtl>
            <:contextMenu><span>Menu</span></:contextMenu>
          </EuiNotificationEvent>
        </div>
      </template>
    );
    const first = el(this.element, '[data-first]');
    assert.dom(first).hasTagName('article');
    const root = getComputedStyle(first);
    assert.strictEqual(root.display, 'flex');
    assert.strictEqual(root.paddingTop, light.size.base);
    assert.strictEqual(root.borderTopStyle, 'none', 'no separator before the first event');
    assert.strictEqual(style(this.element, '[data-second]').borderTopStyle, 'solid', 'separator between events');
    assert.strictEqual(style(this.element, '[data-second]').borderTopColor, rgb(light.border.color));

    const content = getComputedStyle(el(first, '.euiNotificationEvent__content'));
    assert.strictEqual(content.flexDirection, 'column');
    assert.strictEqual(content.rowGap, light.size.s);

    const meta = el(first, '.euiNotificationEventMeta');
    assert.strictEqual(getComputedStyle(meta).display, 'flex');
    assert.strictEqual(getComputedStyle(meta).justifyContent, 'space-between');
    assert.dom('.euiNotificationEventMeta__badge', meta).hasClass('euiBadge').containsText('Alert: Critical');
    assert.dom('.euiNotificationEventMeta__icon', meta).hasAttribute('aria-label', 'Alert icon');
    const time = el(meta, '.euiNotificationEventMeta__time');
    assert.dom(time).hasText('1 min ago');
    assert.strictEqual(getComputedStyle(time).color, rgb(light.colors.textSubdued));
    assert.true(parseFloat(getComputedStyle(time).fontSize) < parseFloat(getComputedStyle(first).fontSize) || parseFloat(getComputedStyle(time).fontSize) <= 14, 'xs time');

    const menuButton = el(meta, '[data-test-subj="e1-notificationEventMetaButton"]');
    assert.dom(menuButton).hasAttribute('aria-label', 'Menu for CPU usage').hasAttribute('aria-haspopup', 'true').hasAttribute('aria-expanded', 'false');
    const wrapper = getComputedStyle(el(meta, '.euiNotificationEventMeta__contextMenuWrapper'));
    assert.strictEqual(wrapper.position, 'absolute');
    assert.strictEqual(wrapper.right, '0px');
    assert.notStrictEqual(getComputedStyle(meta).paddingRight, '0px', 'room for the menu button');
    const rtlWrapper = style(this.element, '[data-rtl] .euiNotificationEventMeta__contextMenuWrapper');
    assert.strictEqual(rtlWrapper.left, '0px', 'RTL: menu in the start corner');

    await click(menuButton);
    await waitUntil(() => document.querySelector('.menu-item'));
    assert.dom(menuButton).hasAttribute('aria-expanded', 'true');

    const titleLink = el(first, '.euiNotificationEvent__title');
    assert.dom(titleLink).hasTagName('button');
    assert.dom('h2.euiTitle', titleLink).hasText('CPU usage');
    assert.dom(first).hasAttribute('aria-labelledby', titleLink.id);
    await click(titleLink);
    assert.strictEqual(titleClicks, 1);

    const messages = el(first, '.euiNotificationEventMessages');
    assert.dom('.euiText p', messages).hasText('First message');
    const accordionButton = el(messages, '.euiNotificationEventMessages__accordionButton');
    assert.strictEqual(getComputedStyle(accordionButton).color, rgb(light.colors.textPrimary));
    assert.dom(messages.querySelector('.euiAccordion__arrow')).doesNotExist();
    assert.dom(accordionButton).containsText('(hide)');
    await click(accordionButton);
    assert.dom(accordionButton).doesNotContainText('(hide)');
    assert.dom('.euiNotificationEventMessages__accordionContent p', messages).exists({ count: 2 });
    assert.dom('.euiNotificationEvent__primaryAction [data-primary]', first).exists();
  });

  // ------------------------------------------------ Providers and contrast

  test('light/dark follow the nearest provider; siblings stay isolated', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiToast @color="warning" @title="t" data-toast />
          <EuiAccordion @borders="all" data-acc><:buttonContent>a</:buttonContent><:content>c</:content></EuiAccordion>
          <EuiCommentList><EuiComment data-comment><:username>u</:username><:event>e</:event><:body>b</:body></EuiComment></EuiCommentList>
          <EuiNotificationEvent @title="n" @time="now" @messages={{MESSAGES}} data-event />
          <EuiEmotionProvider @colorMode="light">
            <EuiToast @color="warning" @title="t" data-nested />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiToast @color="warning" @title="t" data-sibling />
          <EuiNotificationEvent @title="n" @time="now" @messages={{MESSAGES}} data-sibling-event />
        </EuiEmotionProvider>
      </template>
    );
    const toast = el(this.element, '[data-toast]');
    assert.strictEqual(getComputedStyle(toast).backgroundColor, rgb(light.colors.backgroundBasePlain));

    state.mode = 'dark';
    await settled();
    assert.strictEqual(el(this.element, '[data-toast]'), toast, 'toast kept');
    assert.strictEqual(getComputedStyle(toast).backgroundColor, rgb(dark.colors.backgroundBasePlain));
    assert.strictEqual(getComputedStyle(el(toast, '.euiToastDecor'), '::after').borderTopColor, rgb(token(dark, 'borderStrong', 'warning')));
    assert.strictEqual(style(toast, '.euiToastHeader__title').color, rgb(dark.colors.textHeading));
    assert.strictEqual(style(this.element, '[data-acc]').borderTopColor, rgb(dark.border.color));
    assert.strictEqual(
      style(this.element, '[data-comment] .euiPanelBorealis').backgroundColor,
      rgb(dark.colors.backgroundBaseHighlighted)
    );
    assert.strictEqual(style(this.element, '[data-event] .euiNotificationEventMeta__time').color, rgb(dark.colors.textSubdued));
    assert.strictEqual(style(this.element, '[data-nested]').backgroundColor, rgb(light.colors.backgroundBasePlain), 'nested light provider');
    assert.strictEqual(style(this.element, '[data-sibling]').backgroundColor, rgb(light.colors.backgroundBasePlain), 'sibling toast isolated');
    assert.strictEqual(
      style(this.element, '[data-sibling-event] .euiNotificationEventMeta__time').color,
      rgb(light.colors.textSubdued),
      'sibling event isolated'
    );
  });

  test('native token overrides (JS objects) and high contrast', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @borealisOverrides={{state.overrides}} @highContrastMode={{state.contrast}}>
          <EuiToast @color="success" @title="t" data-toast />
          <EuiCommentList>
            <EuiComment data-update><:username>u</:username><:event>e</:event></EuiComment>
          </EuiCommentList>
          <EuiAccordion @borders="horizontal" data-acc><:buttonContent>a</:buttonContent><:content>c</:content></EuiAccordion>
          <EuiNotificationEvent @title="n" @time="now" @messages={{MESSAGES}} @isRead={{true}} data-event />
        </EuiEmotionProvider>
        <EuiToast @color="success" @title="t" data-outside />
      </template>
    );
    state.overrides = {
      colors: { LIGHT: { borderStrongSuccess: '#123456', textSubdued: '#0a0b0c' } },
      size: { s: '10px' }
    };
    await settled();
    const decor = el(this.element, '[data-toast] .euiToastDecor');
    assert.strictEqual(getComputedStyle(decor, '::after').borderTopColor, 'rgb(18, 52, 86)');
    assert.strictEqual(style(this.element, '[data-event] .euiNotificationEventMeta__time').color, 'rgb(10, 11, 12)');
    assert.strictEqual(style(this.element, '[data-event] .euiNotificationEvent__readButton').marginRight, '10px');
    assert.strictEqual(
      getComputedStyle(el(this.element, '[data-outside] .euiToastDecor'), '::after').borderTopColor,
      rgb(token(light, 'borderStrong', 'success')),
      'overrides stay scoped'
    );

    state.overrides = {};
    state.contrast = 'preferred';
    await settled();
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    assert.strictEqual(
      getComputedStyle(decor, '::before').borderTopColor,
      rgb(hc.colors.borderBasePlain),
      'contrast: the highlight track uses the plain border'
    );
    assert.strictEqual(style(this.element, '[data-toast]').borderTopStyle, 'solid', 'contrast: toast border');
    const update = el(this.element, '[data-update] .euiCommentEvent');
    assert.strictEqual(getComputedStyle(update).borderTopStyle, 'solid', 'contrast: update events get a border');
    assert.strictEqual(style(update, '.euiPanelBorealis').borderTopStyle, 'none', 'no duplicate panel border');
    assert.strictEqual(style(this.element, '[data-acc]').borderTopColor, rgb(hc.border.color));
    assert.strictEqual(
      style(this.element, '[data-event] .euiNotificationEventReadIcon svg').stroke,
      rgb(hc.colors.textParagraph),
      'contrast: stronger read outline'
    );

    await clearRender();
    assert.dom('.euiToast, .euiComment, .euiAccordion, .euiNotificationEvent').doesNotExist('teardown');
  });
});
