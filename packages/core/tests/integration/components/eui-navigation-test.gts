import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  clearRender,
  click,
  focus,
  render,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiBreadcrumbs from '#src/components/eui-breadcrumbs.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiPagination from '#src/components/eui-pagination.gts';
import EuiStep from '#src/components/eui-step.gts';
import EuiStepHorizontal from '#src/components/eui-step-horizontal.gts';
import EuiStepNumber from '#src/components/eui-step-number.gts';
import EuiSteps from '#src/components/eui-steps.gts';
import EuiStepsHorizontal from '#src/components/eui-steps-horizontal.gts';
import EuiSubSteps from '#src/components/eui-sub-steps.gts';
import EuiTab from '#src/components/eui-tab.gts';
import EuiTabbedContent from '#src/components/eui-tabbed-content.gts';
import EuiTabs from '#src/components/eui-tabs.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiBreadcrumb } from '#src/components/eui-breadcrumbs.gts';
import type { EuiStepStatus } from '#src/components/eui-step-number.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
type Theme = typeof light;

function el(root: ParentNode, selector: string): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function all(root: ParentNode, selector: string): HTMLElement[] {
  return Array.from(root.querySelectorAll<HTMLElement>(selector));
}

/** Finish running animations/transitions so values are read at their end. */
function style(root: ParentNode, selector: string, pseudo?: string) {
  const element = el(root, selector);
  element
    .getAnimations({ subtree: true })
    .filter((animation) => animation.effect?.getComputedTiming().endTime !== Infinity)
    .forEach((animation) => animation.finish());
  return getComputedStyle(element, pseudo);
}

/** ember-qunit may scale #ember-testing; measure in layout pixels. */
function rect(root: ParentNode, selector: string) {
  const element = el(root, selector);
  const container = element.closest<HTMLElement>('#ember-testing');
  const factor =
    container && container.offsetWidth
      ? container.getBoundingClientRect().width / container.offsetWidth
      : 1;
  const box = element.getBoundingClientRect();
  return {
    left: box.left / factor,
    right: box.right / factor,
    top: box.top / factor,
    width: box.width / factor,
    height: box.height / factor
  };
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

function near(
  assert: Assert,
  actual: number,
  expected: number,
  message: string,
  tolerance = 0.6
) {
  assert.true(
    Math.abs(actual - expected) <= tolerance,
    `${message} (expected ${expected}, got ${actual})`
  );
}

/** Upstream rem font sizes are relative to the 14px body scale. */
function fontPx(theme: Theme, scale: keyof Theme['font']['scale']) {
  const root = px(getComputedStyle(document.documentElement).fontSize);
  return (theme.font.scale[scale] / theme.font.scale.s) * root;
}

function contrast(a: string, b: string) {
  const lum = (color: string) => {
    const [r, g, bl] = color
      .match(/\d+(\.\d+)?/g)!
      .slice(0, 3)
      .map((c) => {
        const v = Number(c) / 255;
        return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
      });
    return 0.2126 * r! + 0.7152 * g! + 0.0722 * bl!;
  };
  const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x);
  return (hi! + 0.05) / (lo! + 0.05);
}

const TABS = [
  { id: 'nav-one', name: 'One' },
  { id: 'nav-two', name: 'Two' },
  { id: 'nav-three', name: 'Three', disabled: true },
  { id: 'nav-four', name: 'Four' }
];

const STATUSES: (EuiStepStatus | undefined)[] = [
  undefined,
  'incomplete',
  'complete',
  'warning',
  'danger',
  'disabled',
  'loading',
  'current'
];

module('Integration | Component | Borealis navigation', function (hooks) {
  setupRenderingTest(hooks);

  test('tabs: sizes set the gap and content typography', async function (assert) {
    await render(
      <template>
        <EuiTabs @size="s" data-s><EuiTab @isSelected={{true}}>A</EuiTab><EuiTab>B</EuiTab></EuiTabs>
        <EuiTabs data-m><EuiTab @isSelected={{true}}>A</EuiTab><EuiTab>B</EuiTab></EuiTabs>
        <EuiTabs @size="l" data-l><EuiTab @isSelected={{true}}>A</EuiTab><EuiTab>B</EuiTab></EuiTabs>
        <EuiTabs @size="xl" data-xl><EuiTab @isSelected={{true}}>A</EuiTab><EuiTab>B</EuiTab></EuiTabs>
      </template>
    );

    const expectations = [
      ['s', light.size.m, 'xs', light.size.xl],
      ['m', light.size.base, 's', light.size.xxl],
      ['l', light.size.l, 'm', '40px'],
      ['xl', light.size.l, 'm', '40px']
    ] as const;
    for (const [size, gap, scale, lineHeight] of expectations) {
      const tabs = style(this.element, `[data-${size}]`);
      assert.strictEqual(tabs.display, 'flex', `${size} flex`);
      assert.strictEqual(tabs.columnGap, gap, `${size} gap`);
      assert.strictEqual(tabs.overflowX, 'auto', `${size} scrolls horizontally`);
      assert.strictEqual(tabs.flexShrink, '0');
      const content = style(this.element, `[data-${size}] .euiTab__content`);
      near(assert, px(content.fontSize), fontPx(light, scale), `${size} font size`);
      assert.strictEqual(content.lineHeight, lineHeight, `${size} line height`);
      assert.strictEqual(content.fontWeight, String(light.font.weight.semiBold));
      assert.strictEqual(content.textOverflow, 'ellipsis', 'content truncates');
      assert.strictEqual(content.whiteSpace, 'nowrap');
      near(
        assert,
        rect(this.element, `[data-${size}] .euiTab`).height,
        px(lineHeight),
        `${size} tab height is the line height`
      );
      const gapMeasured =
        rect(this.element, `[data-${size}] .euiTab:nth-child(2)`).left -
        rect(this.element, `[data-${size}] .euiTab:nth-child(1)`).left -
        rect(this.element, `[data-${size}] .euiTab:nth-child(1)`).width;
      near(assert, gapMeasured, px(gap), `${size} measured gap`);
    }
    assert.dom('[data-xl]').doesNotHaveClass('euiTabs--xlarge', 'no legacy size class');
  });

  test('tabs: selected indicator, disabled, link, expand and bottom border', async function (assert) {
    await render(
      <template>
        <div style="width: 600px">
          <EuiTabs @expand={{true}} data-tabs>
            <EuiTab @isSelected={{true}} data-selected>
              <:prepend><span data-prepend>*</span></:prepend>
              <:default>Selected</:default>
              <:append><span data-append>9</span></:append>
            </EuiTab>
            <EuiTab data-plain>Plain</EuiTab>
            <EuiTab @disabled={{true}} data-disabled>Disabled</EuiTab>
            <EuiTab @disabled={{true}} @isSelected={{true}} data-disabled-selected>DS</EuiTab>
            <EuiTab @href="#x" @target="_blank" data-link>Link</EuiTab>
            <EuiTab @href="javascript:alert(1)" data-js>JS</EuiTab>
          </EuiTabs>
        </div>
        <EuiTabs @bottomBorder={{false}} data-no-border><EuiTab>A</EuiTab></EuiTabs>
        <EuiTabs @display="condensed" data-condensed><EuiTab>A</EuiTab></EuiTabs>
      </template>
    );

    const selected = style(this.element, '[data-selected]');
    assert.strictEqual(selected.color, rgb(light.colors.textHeading), 'selected color');
    assert.strictEqual(selected.fontWeight, String(light.font.weight.semiBold));
    assert.strictEqual(selected.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(selected.paddingLeft, '0px');
    assert.strictEqual(selected.backgroundColor, 'rgba(0, 0, 0, 0)', 'button reset');
    assert.strictEqual(selected.borderTopStyle, 'none');
    const indicator = style(this.element, '[data-selected]', '::after');
    assert.strictEqual(indicator.content, '""', 'selected indicator rendered');
    assert.strictEqual(indicator.position, 'absolute');
    assert.strictEqual(indicator.bottom, '0px');
    assert.strictEqual(indicator.borderBottomStyle, 'solid');
    assert.strictEqual(indicator.borderBottomWidth, light.border.width.thick);
    assert.strictEqual(indicator.borderBottomColor, rgb(light.colors.primary));
    assert.strictEqual(indicator.left, '0px');
    assert.strictEqual(indicator.right, '0px');

    const plain = style(this.element, '[data-plain]');
    assert.strictEqual(plain.color, rgb(light.colors.textSubdued), 'unselected color');
    assert.strictEqual(style(this.element, '[data-plain]', '::after').content, 'none', 'no indicator');

    const disabled = style(this.element, '[data-disabled]');
    assert.strictEqual(disabled.color, rgb(light.colors.textDisabled));
    assert.strictEqual(disabled.cursor, 'not-allowed');
    assert.dom('[data-disabled]').isDisabled().hasAttribute('aria-selected', 'false');
    assert.strictEqual(
      style(this.element, '[data-disabled-selected]', '::after').borderBottomColor,
      rgb(light.colors.textDisabled),
      'disabled selected indicator is disabled colored'
    );

    assert.dom('[data-link]').hasTagName('a').hasAttribute('href', '#x').hasAttribute('rel', 'noopener noreferrer').hasAttribute('role', 'tab');
    assert.dom('[data-js]').hasTagName('button').isDisabled('javascript: URLs disable the tab');

    assert.dom('[data-selected]').hasAttribute('tabindex', '0').hasAttribute('aria-selected', 'true').hasClass('euiTab-isSelected');
    assert.dom('[data-plain]').hasAttribute('tabindex', '-1').hasAttribute('aria-selected', 'false');
    assert.dom('[data-selected] .euiTab__prepend [data-prepend]').exists();
    assert.dom('[data-selected] .euiTab__append [data-append]').exists();
    assert.dom('[data-disabled]').doesNotHaveClass('euiTab-isDisabled', 'no legacy class');

    // expand: equal widths, centered content
    // flex-basis 0 + grow 1: tabs without wider content share the width equally.
    const widths = all(this.element, '[data-tabs] .euiTab').slice(1).map((tab) => tab.getBoundingClientRect().width);
    assert.true(Math.max(...widths) - Math.min(...widths) < 1, `expanded tabs are equal width (${widths.join(', ')})`);
    assert.strictEqual(selected.justifyContent, 'center');
    assert.strictEqual(selected.flexGrow, '1');

    assert.true(style(this.element, '[data-tabs]').boxShadow.includes('inset'), 'bottom border is an inset shadow');
    assert.true(style(this.element, '[data-tabs]').boxShadow.startsWith(rgb(light.border.color)), 'border color');
    assert.strictEqual(style(this.element, '[data-no-border]').boxShadow, 'none');
    assert.strictEqual(style(this.element, '[data-condensed]').boxShadow, 'none', 'condensed alias has no border');
    assert.dom('[data-condensed]').doesNotHaveClass('euiTabs--condensed');
  });

  test('tabs: arrow keys move focus between enabled tabs and wrap', async function (assert) {
    const clicked: string[] = [];
    const onTabClick = (tab: { id: string }) => clicked.push(tab.id);
    await render(
      <template>
        <EuiTabbedContent @tabs={{TABS}} @onTabClick={{onTabClick}}>
          <:selectedTabContent as |tab|>Panel {{tab.name}}</:selectedTabContent>
        </EuiTabbedContent>
      </template>
    );

    const tablist = el(this.element, '[role="tablist"]');
    await focus('#nav-one');
    await triggerKeyEvent(tablist, 'keydown', 'ArrowRight');
    assert.dom('#nav-two').isFocused('right moves to the next tab');
    await triggerKeyEvent(tablist, 'keydown', 'ArrowRight');
    assert.dom('#nav-four').isFocused('disabled tabs are skipped');
    await triggerKeyEvent(tablist, 'keydown', 'ArrowRight');
    assert.dom('#nav-one').isFocused('wraps to the first tab');
    await triggerKeyEvent(tablist, 'keydown', 'ArrowLeft');
    assert.dom('#nav-four').isFocused('left wraps to the last tab');
    await triggerKeyEvent(tablist, 'keydown', 'ArrowLeft');
    assert.dom('#nav-two').isFocused();
    await triggerKeyEvent(tablist, 'keydown', 'ArrowDown');
    assert.dom('#nav-two').isFocused('other keys do nothing');
    assert.deepEqual(clicked, [], 'arrow keys only move focus (manual activation)');
    assert.dom('[role="tabpanel"]').hasText('Panel One');

    await triggerKeyEvent('#nav-two', 'keydown', 'Enter');
    await click('#nav-two');
    assert.deepEqual(clicked, ['nav-two']);
    assert.dom('#nav-two').hasAttribute('tabindex', '0').hasAttribute('aria-selected', 'true').isFocused();
    assert.dom('#nav-one').hasAttribute('tabindex', '-1');
    const panel = el(this.element, '[role="tabpanel"]');
    assert.dom(panel).hasText('Panel Two').hasAttribute('aria-labelledby', 'nav-two');
    assert.dom('#nav-two').hasAttribute('aria-controls', panel.id);
  });

  test('tabs: reactive args update in place', async function (assert) {
    class State {
      @tracked size: 's' | 'm' | 'l' = 's';
      @tracked selected = false;
      @tracked disabled = false;
      @tracked expand = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiTabs @size={{state.size}} @expand={{state.expand}} data-tabs>
          <EuiTab @isSelected={{state.selected}} @disabled={{state.disabled}} data-tab>A</EuiTab>
          <EuiTab data-other>B</EuiTab>
        </EuiTabs>
      </template>
    );
    const tabs = el(this.element, '[data-tabs]');
    const tab = el(this.element, '[data-tab]');
    assert.strictEqual(getComputedStyle(tabs).columnGap, light.size.m);

    state.size = 'l';
    state.selected = true;
    state.expand = true;
    await settled();
    assert.strictEqual(el(this.element, '[data-tabs]'), tabs, 'tablist kept');
    assert.strictEqual(el(this.element, '[data-tab]'), tab, 'tab kept');
    assert.strictEqual(getComputedStyle(tabs).columnGap, light.size.l);
    assert.strictEqual(style(this.element, '[data-tab] .euiTab__content').lineHeight, '40px');
    assert.strictEqual(getComputedStyle(tab).color, rgb(light.colors.textHeading));
    assert.strictEqual(getComputedStyle(tab).flexGrow, '1');
    assert.dom(tab).hasAttribute('tabindex', '0');

    state.disabled = true;
    await settled();
    assert.strictEqual(el(this.element, '[data-tab]'), tab, 'disabling keeps the button');
    assert.dom(tab).isDisabled();
    assert.strictEqual(style(this.element, '[data-tab]', '::after').borderBottomColor, rgb(light.colors.textDisabled));
  });

  test('breadcrumbs: page type separators, truncation and aria-current', async function (assert) {
    let clicks = 0;
    const crumbs: EuiBreadcrumb[] = [
      { text: 'Home', href: '#home' },
      { text: 'A very long breadcrumb that is truncated at ten times the base size', onClick: () => clicks++ },
      { text: 'Never truncated breadcrumb with a long text that keeps going', truncate: false },
      { text: 'Current page with a very long title that fills the remaining space' }
    ];
    const short: EuiBreadcrumb[] = [{ text: 'Home', href: '#h' }, { text: 'Here' }];
    await render(
      <template>
        <div style="width: 900px">
          <EuiBreadcrumbs @breadcrumbs={{crumbs}} data-crumbs />
          <EuiBreadcrumbs @breadcrumbs={{crumbs}} @truncate={{false}} data-wrap />
          <EuiBreadcrumbs @breadcrumbs={{short}} @lastBreadcrumbIsCurrentPage={{false}} data-not-current />
        </div>
      </template>
    );

    assert.dom('[data-crumbs]').hasTagName('nav').hasAttribute('aria-label', 'Breadcrumbs');
    const list = style(this.element, '[data-crumbs] ol');
    assert.strictEqual(list.display, 'flex');
    assert.strictEqual(list.flexWrap, 'nowrap', 'truncated lists stay on one line');
    assert.strictEqual(list.whiteSpace, 'nowrap');
    assert.strictEqual(list.lineHeight, light.size.l);
    assert.strictEqual(list.rowGap, light.size.xs);
    assert.strictEqual(list.listStyleType, 'none');
    assert.strictEqual(list.paddingLeft, '0px');
    near(assert, px(list.fontSize), fontPx(light, 's'), 'list font size s');
    assert.strictEqual(style(this.element, '[data-wrap] ol').flexWrap, 'wrap');

    const items = all(this.element, '[data-crumbs] li');
    assert.strictEqual(items.length, 4);
    for (const [index, item] of items.slice(0, -1).entries()) {
      const separator = getComputedStyle(item, '::after');
      assert.strictEqual(separator.content, '""', `item ${index} has a separator`);
      assert.strictEqual(separator.borderRightWidth, light.border.width.thin);
      assert.strictEqual(separator.borderRightColor, rgb(light.border.color));
      assert.strictEqual(separator.height, light.size.base);
      assert.strictEqual(separator.marginLeft, light.size.s);
      assert.strictEqual(separator.marginRight, light.size.s);
      assert.notStrictEqual(separator.transform, 'none', 'slanted separator');
    }
    assert.strictEqual(getComputedStyle(items[3]!, '::after').content, 'none', 'no separator after the last');
    assert.strictEqual(getComputedStyle(items[0]!).display, 'flex');
    assert.strictEqual(getComputedStyle(items[0]!).overflow, 'hidden', 'truncated items clip');
    assert.strictEqual(getComputedStyle(items[2]!).overflow, 'visible', 'per-breadcrumb truncate=false');

    const tenBase = `${px(light.size.base) * 10}px`;
    const link = style(this.element, '[data-crumbs] li:nth-child(2) .euiBreadcrumb__content');
    assert.strictEqual(link.maxWidth, tenBase, 'truncated to 10 × size.base');
    assert.strictEqual(link.textOverflow, 'ellipsis');
    assert.true(rect(this.element, '[data-crumbs] li:nth-child(2) .euiBreadcrumb__content').width <= px(tenBase) + 0.6, 'measured truncation');
    assert.strictEqual(style(this.element, '[data-crumbs] li:nth-child(3) .euiBreadcrumb__content').maxWidth, 'none');
    const last = style(this.element, '[data-crumbs] li:nth-child(4) .euiBreadcrumb__content');
    assert.strictEqual(last.maxWidth, 'none', 'last fills the remaining space');
    assert.strictEqual(last.textOverflow, 'ellipsis');
    assert.strictEqual(last.color, rgb(light.colors.textSubdued), 'plain breadcrumbs are subdued');
    assert.strictEqual(last.fontWeight, String(light.font.weight.regular));
    assert.strictEqual(style(this.element, '[data-wrap] li:nth-child(2) .euiBreadcrumb__content').maxWidth, 'none', 'no truncation');

    assert.dom('[data-crumbs] li:nth-child(1) a').hasAttribute('href', '#home').hasClass('euiLink');
    assert.strictEqual(style(this.element, '[data-crumbs] li:nth-child(1) a').color, rgb(light.colors.textSubdued), 'links default to subdued');
    assert.true(style(this.element, '[data-crumbs] li:nth-child(1) a').textDecorationStyle === 'dotted', 'interactive dotted underline');
    assert.true(
      el(this.element, '[data-crumbs] li:nth-child(1) a').className.includes('euiLink-subdued'),
      'subdued link label lets upstream hover/focus color selector match'
    );
    assert.dom('[data-crumbs] li:nth-child(4) span').hasAttribute('aria-current', 'page');
    assert.dom('[data-crumbs] [aria-current]').exists({ count: 1 });
    assert.dom('[data-not-current] [aria-current]').doesNotExist();
    assert.dom('[data-crumbs] li:nth-child(2) .euiBreadcrumb__content').hasAttribute('title', crumbs[1]!.text as string);
    assert.dom('[data-crumbs] li').hasAttribute('data-test-subj', 'euiBreadcrumb');
    assert.dom('[data-crumbs]').doesNotHaveClass('euiBreadcrumbs--truncate', 'no legacy class');
    assert.dom('[data-crumbs] .euiBreadcrumb--last').doesNotExist();

    await click('[data-crumbs] li:nth-child(2) .euiBreadcrumb__content');
    assert.strictEqual(clicks, 1);
  });

  test('breadcrumbs: max and responsive collapse into a popover', async function (assert) {
    const crumbs: EuiBreadcrumb[] = ['One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven'].map((text) => ({ text, href: `#${text}` }));
    class State {
      @tracked max: number | null = 3;
    }
    const state = new State();
    await render(
      <template>
        <EuiBreadcrumbs @breadcrumbs={{crumbs}} @max={{state.max}} data-max />
        <EuiBreadcrumbs @breadcrumbs={{crumbs}} data-default />
        <EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{hash xl=2}} data-responsive />
        <EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}} @max={{0}} data-all />
      </template>
    );

    const texts = (selector: string) =>
      all(this.element, `${selector} > ol > li`).map((li) => li.textContent!.trim());
    assert.deepEqual(texts('[data-max]'), ['One', '…', 'Six', 'Seven'], 'max 3 keeps first and the last two');
    assert.deepEqual(texts('[data-default]'), ['One', 'Two', '…', 'Five', 'Six', 'Seven'], 'default max 5');
    assert.deepEqual(texts('[data-responsive]'), ['One', '…', 'Seven'], 'responsive object for the current (xl) breakpoint');
    assert.strictEqual(texts('[data-all]').length, 7, 'max 0 shows all');

    const collapsed = el(this.element, '[data-max] > ol > li:nth-child(2)');
    assert.strictEqual(getComputedStyle(collapsed).flexShrink, '0', 'collapsed item never shrinks');
    const button = el(collapsed, '.euiBreadcrumb__content');
    assert.dom(button).hasTagName('button').hasAttribute('aria-label', 'See collapsed breadcrumbs').hasAttribute('title', 'See collapsed breadcrumbs');
    assert.strictEqual(getComputedStyle(button).display, 'inline-flex');
    assert.strictEqual(getComputedStyle(button).columnGap, light.size.xs);
    assert.strictEqual(getComputedStyle(button).color, rgb(light.colors.textSubdued));
    assert.dom(button.querySelector('svg')).exists('chevron icon');
    assert.strictEqual(
      getComputedStyle(collapsed.querySelector('.euiPopover')!).maxInlineSize,
      `calc(100% - ${px(light.size.base) + 1}px)`,
      'popover wrapper leaves room for the separator'
    );

    await click(button);
    await waitUntil(() => document.querySelector('.euiPopover__panel nav'));
    const popover = document.querySelector<HTMLElement>('.euiPopover__panel nav')!;
    assert.deepEqual(
      all(popover, 'li').map((li) => li.textContent!.trim()),
      ['Two', 'Three', 'Four', 'Five'],
      'popover lists the collapsed breadcrumbs'
    );
    assert.dom('[aria-current]', popover).doesNotExist('popover breadcrumbs are not the current page');
    assert.strictEqual(getComputedStyle(el(popover, 'ol')).flexWrap, 'wrap', 'popover breadcrumbs are not truncated');

    state.max = null;
    await settled();
    assert.strictEqual(texts('[data-max]').length, 7, 'null max shows all, reactively');
  });

  test('breadcrumbs: application type', async function (assert) {
    const crumbs: EuiBreadcrumb[] = [
      { text: 'Root', href: '#r' },
      { text: 'Middle', onClick: () => {} },
      { text: 'Plain' },
      { text: 'Current' }
    ];
    const only: EuiBreadcrumb[] = [{ text: 'Only' }];
    class State {
      @tracked type: 'page' | 'application' = 'application';
    }
    const state = new State();
    await render(
      <template>
        <EuiBreadcrumbs @breadcrumbs={{crumbs}} @type={{state.type}} data-app />
        <EuiBreadcrumbs @breadcrumbs={{only}} @type="application" data-only />
      </template>
    );

    const content = (n: number) => el(this.element, `[data-app] li:nth-child(${n}) .euiBreadcrumb__content`);
    const first = getComputedStyle(content(1));
    assert.strictEqual(first.backgroundColor, rgb(light.colors.backgroundLightPrimary), 'clickable app crumbs use the primary light background');
    assert.true(contrast(first.color, first.backgroundColor) >= 4.5, 'clickable app crumb text contrast');
    assert.strictEqual(first.textDecorationLine, 'none');
    assert.strictEqual(first.fontWeight, String(light.font.weight.medium));
    assert.strictEqual(first.lineHeight, light.size.base);
    assert.strictEqual(first.paddingTop, light.size.xs);
    assert.strictEqual(first.paddingLeft, light.size.m, 'first child padding');
    assert.true(first.clipPath.startsWith('polygon'), 'first child arrow shape');
    near(assert, px(first.fontSize), fontPx(light, 'xs'), 'xs font');
    assert.strictEqual(first.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(first.borderTopRightRadius, '0px');

    const plain = getComputedStyle(content(3));
    assert.strictEqual(plain.backgroundColor, rgb(light.components.breadcrumbsApplicationBackground));
    assert.strictEqual(plain.color, rgb(light.components.breadcrumbsApplicationColor));
    assert.true(contrast(plain.color, plain.backgroundColor) >= 4.5, 'application text contrast');
    assert.true(getComputedStyle(content(2)).clipPath.includes(light.size.s), 'intermediate arrow');
    const last = getComputedStyle(content(4));
    assert.strictEqual(last.paddingRight, light.size.m, 'last child padding');
    assert.strictEqual(last.borderTopRightRadius, light.border.radius.control);
    assert.strictEqual(
      getComputedStyle(el(this.element, '[data-app] li:nth-child(1)'), '::after').content,
      'none',
      'no slash separators'
    );
    assert.strictEqual(getComputedStyle(el(this.element, '[data-app] li:nth-child(1)')).marginRight, `-${light.size.xs}`, 'chips overlap');
    const onlyStyle = style(this.element, '[data-only] .euiBreadcrumb__content');
    assert.strictEqual(onlyStyle.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(onlyStyle.borderTopRightRadius, light.border.radius.control);
    assert.strictEqual(onlyStyle.clipPath, 'none');

    const element = content(1);
    state.type = 'page';
    await settled();
    assert.strictEqual(content(1), element, 'type change keeps the link');
    assert.strictEqual(getComputedStyle(element).backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.strictEqual(getComputedStyle(el(this.element, '[data-app] li:nth-child(1)'), '::after').content, '""');
  });

  test('pagination: pages, active page, ellipsis and disabled ends', async function (assert) {
    class State {
      @tracked activePage = 0;
      clicked: number[] = [];
      select = (page: number) => {
        this.clicked.push(page);
        this.activePage = page;
      };
    }
    const state = new State();
    await render(
      <template>
        <EuiPagination @pageCount={{20}} @activePage={{state.activePage}} @onPageClick={{state.select}} data-pagination />
      </template>
    );

    const nav = style(this.element, '[data-pagination]');
    assert.strictEqual(nav.display, 'flex');
    assert.strictEqual(nav.alignItems, 'center');
    assert.strictEqual(nav.overflowX, 'auto');
    const list = style(this.element, '[data-pagination] ul');
    assert.strictEqual(list.display, 'flex');
    assert.strictEqual(list.alignItems, 'baseline');
    assert.strictEqual(list.listStyleType, 'none');
    assert.deepEqual(
      all(this.element, '[data-pagination] li').map((li) => li.textContent!.trim()),
      ['1', '2', '3', '4', '5', '…', '20']
    );
    assert.dom('[data-pagination] li.euiPagination__item').exists({ count: 7 });

    const active = el(this.element, '[aria-current="page"]');
    assert.dom(active).hasText('1').hasAttribute('aria-label', 'Page 1 of 20').isDisabled().hasClass('euiPaginationButton').hasAttribute('data-test-subj', 'pagination-button-0');
    assert.strictEqual(getComputedStyle(active).color, rgb(light.colors.primary), 'active page is primary');
    assert.strictEqual(getComputedStyle(active).fontWeight, String(light.font.weight.bold));
    assert.strictEqual(getComputedStyle(active).textDecorationLine, 'underline');
    assert.strictEqual(getComputedStyle(active).cursor, 'default');
    assert.strictEqual(getComputedStyle(active).outlineOffset, `-${light.focus.width}`);
    const other = el(this.element, '[aria-label="Page 2 of 20"]');
    assert.strictEqual(getComputedStyle(other).color, rgb(light.colors.textParagraph), 'other pages use text color');
    assert.strictEqual(style(this.element, '[aria-label="Page 2 of 20"] .euiButtonEmpty__text').paddingLeft, '0px', 'no text padding');
    near(assert, rect(this.element, '[aria-label="Page 2 of 20"]').height, 32, 'small button height');

    const ellipsis = el(this.element, 'li[aria-label]');
    assert.dom(ellipsis).hasAttribute('aria-label', 'Skipping pages 6 to 19');
    assert.strictEqual(getComputedStyle(ellipsis).color, rgb(light.colors.textDisabled));
    assert.strictEqual(getComputedStyle(ellipsis).paddingLeft, light.size.s);

    assert.dom('[data-test-subj="pagination-button-previous"]').isDisabled().hasAttribute('aria-label', 'Previous page');
    assert.dom('[data-test-subj="pagination-button-next"]').isNotDisabled().hasAttribute('aria-label', 'Next page');
    assert.dom('[data-test-subj="pagination-button-first"]').doesNotExist('first/last arrows only when compressed');
    assert.dom('[role="status"]').hasText('Page 1 of 20');
    const status = getComputedStyle(el(this.element, '[role="status"]').parentElement!);
    assert.strictEqual(status.position, 'absolute', 'status is screen reader only');
    assert.strictEqual(status.width, '1px');

    await click('[data-test-subj="pagination-button-next"]');
    await click('[aria-label="Page 20 of 20"]');
    assert.deepEqual(state.clicked, [1, 19]);
    assert.dom('[aria-current="page"]').hasText('20');
    assert.dom('[data-test-subj="pagination-button-next"]').isDisabled();
    assert.dom('[data-test-subj="pagination-button-previous"]').isNotDisabled();
    assert.deepEqual(
      all(this.element, '[data-pagination] li').map((li) => li.textContent!.trim()),
      ['1', '…', '16', '17', '18', '19', '20']
    );
    assert.dom('li[aria-label]').hasAttribute('aria-label', 'Skipping pages 2 to 15');
    assert.dom('[role="status"]').hasText('Page 20 of 20');
  });

  test('pagination: compressed, responsive and aria-controls', async function (assert) {
    class State {
      @tracked compressed = true;
      @tracked activePage = 1;
      clicked: number[] = [];
      select = (page: number) => {
        this.clicked.push(page);
      };
    }
    const state = new State();
    await render(
      <template>
        <div id="nav-content" tabindex="-1">content</div>
        <EuiPagination
          @pageCount={{5}}
          @activePage={{state.activePage}}
          @compressed={{state.compressed}}
          @onPageClick={{state.select}}
          aria-controls="nav-content"
          @ariaControls="nav-content"
          data-pagination
        />
        <EuiPagination @pageCount={{5}} @responsive={{false}} data-not-responsive />
      </template>
    );

    assert.dom('[data-pagination] ul').doesNotExist();
    const text = el(this.element, '[data-pagination] .euiPagination__compressedText');
    assert.dom(text).hasText('2 of 5');
    // `inline-flex` is blockified to `flex` inside the flex nav.
    assert.strictEqual(getComputedStyle(text).display, 'flex');
    assert.strictEqual(getComputedStyle(text).alignItems, 'center');
    assert.strictEqual(getComputedStyle(text).lineHeight, `${px(getComputedStyle(text).fontSize)}px`, 'line-height 1');
    const [page, total] = all(text, 'span');
    assert.dom(page).hasText('2');
    assert.dom(total).hasText('5');
    assert.strictEqual(getComputedStyle(page!).color, rgb(light.colors.textPrimary), 'current page is primary');
    assert.strictEqual(getComputedStyle(page!).fontWeight, String(light.font.weight.semiBold));
    assert.strictEqual(getComputedStyle(total!).marginLeft, light.size.s);

    const types = all(this.element, '[data-pagination] .euiPaginationArrowButton').map((b) => b.getAttribute('data-test-subj'));
    assert.deepEqual(types, ['first', 'previous', 'next', 'last'].map((t) => `pagination-button-${t}`));
    assert.dom('[data-test-subj="pagination-button-first"]').hasAttribute('aria-label', 'First page').hasTagName('a').hasAttribute('href', '#nav-content').hasAttribute('aria-controls', 'nav-content');
    assert.dom('[data-test-subj="pagination-button-last"]').hasAttribute('aria-label', 'Last page');

    await click('[data-test-subj="pagination-button-last"]');
    await click('[data-test-subj="pagination-button-first"]');
    assert.deepEqual(state.clicked, [4, 0]);
    assert.dom('#nav-content').isFocused('aria-controls content is focused');
    assert.strictEqual(window.location.hash, '', 'linked arrows do not navigate');

    state.activePage = 0;
    await settled();
    assert.dom('[data-test-subj="pagination-button-first"]').hasTagName('button').isDisabled().doesNotHaveAttribute('href');
    assert.dom('[data-test-subj="pagination-button-previous"]').isDisabled();

    const nav = el(this.element, '[data-pagination]');
    state.compressed = false;
    await settled();
    assert.strictEqual(el(this.element, '[data-pagination]'), nav, 'nav kept when toggling compressed');
    assert.dom('[data-pagination] ul li').exists({ count: 5 });
    assert.dom('[data-pagination] [aria-label="Page 2 of 5"]').hasAttribute('href', '#nav-content').hasAttribute('aria-controls', 'nav-content');
    assert.dom('[data-not-responsive] ul li').exists({ count: 5 }, 'wide viewport is not compressed');
  });

  test('steps: every status color and number content', async function (assert) {
    await render(
      <template>
        <EuiSteps>
          {{#each STATUSES as |status index|}}
            <EuiStep @step={{index}} @title="Step" @status={{status}} data-step={{if status status "none"}}>Body</EuiStep>
          {{/each}}
        </EuiSteps>
      </template>
    );

    const number = (status: string) => style(this.element, `[data-step="${status}"] .euiStepNumber`);
    const buttons = light.components.buttons;
    const expectations: [string, string, string][] = [
      ['none', light.colors.primary, light.colors.emptyShade],
      ['current', light.colors.primary, light.colors.emptyShade],
      ['complete', buttons.backgroundFilledSuccess, buttons.textColorFilledSuccess],
      ['warning', buttons.backgroundFilledWarning, buttons.textColorFilledWarning],
      ['danger', buttons.backgroundFilledDanger, buttons.textColorFilledDanger],
      ['disabled', buttons.backgroundFilledDisabled, buttons.textColorFilledDisabled]
    ];
    for (const [status, background, color] of expectations) {
      const s = number(status);
      assert.strictEqual(s.backgroundColor, rgb(background), `${status} background`);
      assert.strictEqual(s.color, rgb(color), `${status} color`);
      assert.strictEqual(s.borderTopLeftRadius, '50%');
      assert.strictEqual(s.width, light.size.xl, `${status} 32px circle`);
      assert.strictEqual(s.fontWeight, String(light.font.weight.medium));
    }
    const incomplete = number('incomplete');
    assert.strictEqual(incomplete.backgroundColor, 'rgba(0, 0, 0, 0)', 'incomplete is hollow');
    assert.strictEqual(incomplete.color, rgb(light.colors.textParagraph));
    assert.strictEqual(incomplete.borderTopWidth, light.border.width.thick);
    assert.strictEqual(number('loading').backgroundColor, 'rgba(0, 0, 0, 0)');
    const current = number('current');
    assert.strictEqual(current.transform, 'matrix(1.1, 0, 0, 1.1, 0, 0)', 'current is enlarged');
    assert.true(current.boxShadow.includes('inset'), 'current inner ring');
    assert.strictEqual(current.borderTopColor, rgb(light.colors.primary));
    assert.strictEqual(current.borderTopWidth, light.border.width.thick);

    // content
    assert.dom('[data-step="none"] .euiStepNumber__number').hasText('0').hasAttribute('aria-hidden', 'true');
    assert.dom('[data-step="none"] .euiStepNumber').includesText('Step 0');
    assert.dom('[data-step="incomplete"] .euiStepNumber').includesText('Step 1 is incomplete');
    assert.dom('[data-step="disabled"] .euiStepNumber').includesText('Step 5 is disabled');
    assert.dom('[data-step="current"] .euiStepNumber').includesText('Current step is 7');
    assert.dom('[data-step="current"] .euiStepNumber__number').hasText('7');
    for (const [status, label] of [
      ['complete', 'Step 2 is complete'],
      ['warning', 'Step 3 has warnings'],
      ['danger', 'Step 4 has errors']
    ] as const) {
      assert.dom(`[data-step="${status}"] .euiStepNumber__number`).doesNotExist(`${status} shows an icon`);
      assert.dom(`[data-step="${status}"] svg.euiStepNumber__icon`).exists().hasAttribute('aria-label', label);
    }
    assert.strictEqual(style(this.element, '[data-step="complete"] .euiStepNumber__icon').stroke, number('complete').color, 'icon stroke is currentColor');
    assert.strictEqual(style(this.element, '[data-step="warning"] .euiStepNumber__icon').marginTop, '-2px');
    assert.dom('[data-step="loading"] .euiStepNumber__loader').exists();
    assert.dom('[data-step="loading"] .euiStepNumber').includesText('Step 6 is loading');
    const sr = el(this.element, '[data-step="incomplete"] .euiStepNumber > span:first-child');
    assert.strictEqual(getComputedStyle(sr).position, 'absolute', 'status text is screen reader only');
    assert.dom('.euiStepNumber--complete').doesNotExist('no legacy classes');
    assert.dom('.euiStep-isDisabled').doesNotExist();
    assert.notStrictEqual(
      style(this.element, '[data-step="disabled"] .euiStep__title').color,
      style(this.element, '[data-step="none"] .euiStep__title').color,
      'disabled title is greyed'
    );
  });

  test('steps: title sizes, vertical line and content layout', async function (assert) {
    await render(
      <template>
        <EuiSteps>
          <EuiStep @title="M" @titleSize="m" @headingElement="h3" data-step="m">Body<EuiSubSteps data-sub>sub</EuiSubSteps></EuiStep>
          <EuiStep @title="S" data-step="s">Body</EuiStep>
          <EuiStep @title="XS" @titleSize="xs" data-step="xs">Body</EuiStep>
          <EuiStep @title="XXS" @titleSize="xxs" data-step="xxs">Body</EuiStep>
          <EuiStep @title="Last" data-step="last">Body</EuiStep>
        </EuiSteps>
      </template>
    );

    const sizes = [
      ['m', light.size.xl],
      ['s', light.size.xl],
      ['xs', light.size.l],
      ['xxs', light.size.base]
    ] as const;
    for (const [size, numberSize] of sizes) {
      const box = rect(this.element, `[data-step="${size}"] .euiStepNumber`);
      near(assert, box.width, px(numberSize), `${size} number width`);
      near(assert, box.height, px(numberSize), `${size} number height`);
      const line = style(this.element, `[data-step="${size}"]`, '::before');
      assert.strictEqual(line.content, '""', `${size} has a connecting line`);
      assert.strictEqual(line.top, numberSize, `${size} line starts below the number`);
      assert.strictEqual(line.left, `${px(numberSize) / 2 - px(light.border.width.thick) / 2}px`, `${size} line is centered`);
      assert.strictEqual(line.borderLeftWidth, light.border.width.thick);
      const content = style(this.element, `[data-step="${size}"] .euiStep__content`);
      assert.strictEqual(content.marginLeft, `${px(numberSize) / 2}px`, `${size} content margin`);
      assert.strictEqual(content.paddingLeft, `${px(numberSize) / 2 + px(light.size.base)}px`);
      assert.strictEqual(content.paddingTop, light.size.base);
      assert.strictEqual(content.paddingBottom, `${px(light.size.xl) + px(light.size.s)}px`);
      assert.strictEqual(style(this.element, `[data-step="${size}"] .euiStep__titleWrapper`).columnGap, light.size.base);
    }
    assert.strictEqual(style(this.element, '[data-step="last"]', '::before').content, 'none', 'no line after the last step');
    assert.dom('[data-step="m"] h3.euiStep__title').hasText('M');
    assert.dom('[data-step="s"] p.euiStep__title').exists('default heading element is p');
    assert.strictEqual(style(this.element, '[data-step="s"] .euiStep__title').paddingTop, light.size.xs, 's title padding');
    assert.dom('[data-step="xxs"] .euiStepNumber__number').doesNotExist('xxs is a dot');
    assert.strictEqual(style(this.element, '[data-step="xxs"] .euiStep__title').lineHeight, light.size.base);

    const sub = style(this.element, '[data-sub]');
    assert.strictEqual(sub.backgroundColor, rgb(light.colors.lightestShade));
    assert.strictEqual(sub.paddingTop, light.size.base);
    assert.strictEqual(sub.marginBottom, light.size.base);
    assert.strictEqual(sub.borderTopStyle, 'none');
  });

  test('step number: standalone sizes and statuses, reactive without replacement', async function (assert) {
    class State {
      @tracked status: EuiStepStatus | undefined = undefined;
      @tracked size: 'none' | 'xs' | 's' | 'm' = 's';
    }
    const state = new State();
    await render(
      <template>
        <EuiStepNumber @number={{4}} @status={{state.status}} @titleSize={{state.size}} data-number />
        <EuiStepNumber @number={{2}} @isHollow={{true}} @stepAriaLabel="Custom" data-hollow />
      </template>
    );
    const number = el(this.element, '[data-number]');
    assert.strictEqual(getComputedStyle(number).backgroundColor, rgb(light.colors.primary));

    state.status = 'danger';
    state.size = 'xs';
    await settled();
    assert.strictEqual(el(this.element, '[data-number]'), number, 'element kept');
    assert.strictEqual(style(this.element, '[data-number]').backgroundColor, rgb(light.components.buttons.backgroundFilledDanger));
    assert.strictEqual(getComputedStyle(number).width, light.size.l);
    assert.dom('[data-number] svg').hasAttribute('aria-label', 'Step 4 has errors');

    state.size = 'none';
    state.status = 'warning';
    await settled();
    assert.strictEqual(getComputedStyle(number).width, light.size.base);
    assert.strictEqual(style(this.element, '[data-number] svg').marginTop, '-0.5px');

    assert.strictEqual(getComputedStyle(el(this.element, '[data-hollow]')).backgroundColor, 'rgba(0, 0, 0, 0)', 'isHollow alias');
    assert.dom('[data-hollow]').includesText('Custom', 'stepAriaLabel wins');
  });

  test('horizontal steps: layout, sizes, clicks, a11y and RTL', async function (assert) {
    const clicked: number[] = [];
    const click2 = () => clicked.push(2);
    const click4 = () => clicked.push(4);
    class State {
      @tracked size: 'xs' | 's' | 'm' = 'm';
      @tracked status: EuiStepStatus = 'incomplete';
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 800px">
          <EuiStepsHorizontal @size={{state.size}} data-steps>
            <EuiStepHorizontal @step={{1}} @title="Done" @isComplete={{true}} />
            <EuiStepHorizontal @step={{2}} @title="Now" @isSelected={{true}} @onStepClick={{click2}} />
            <EuiStepHorizontal @step={{3}} @title="Next" @status={{state.status}} data-third />
            <EuiStepHorizontal @step={{4}} @title="Locked" @disabled={{true}} @onStepClick={{click4}} />
          </EuiStepsHorizontal>
        </div>
        <div dir="rtl" style="width: 800px">
          <EuiStepsHorizontal data-rtl>
            <EuiStepHorizontal @step={{1}} @title="A" />
            <EuiStepHorizontal @step={{2}} @title="B" />
          </EuiStepsHorizontal>
        </div>
      </template>
    );

    const list = style(this.element, '[data-steps]');
    assert.strictEqual(list.display, 'flex');
    assert.strictEqual(list.alignItems, 'stretch');
    assert.strictEqual(list.listStyleType, 'none');
    const items = all(this.element, '[data-steps] > li');
    assert.strictEqual(items.length, 4);
    const widths = items.map((li) => li.getBoundingClientRect().width);
    assert.true(Math.max(...widths) - Math.min(...widths) < 1, 'items share the width equally');
    assert.dom(items[1]).hasClass('euiStepsHorizontal__item').hasAttribute('aria-current', 'step');
    assert.dom('[data-steps] [aria-current]').exists({ count: 1 });

    const buttons = all(this.element, '[data-steps] button.euiStepHorizontal');
    const first = getComputedStyle(buttons[0]!);
    assert.strictEqual(first.paddingTop, light.size.l);
    assert.strictEqual(first.paddingLeft, light.size.base);
    assert.strictEqual(first.flexDirection, 'column');
    assert.strictEqual(first.alignItems, 'center');
    assert.strictEqual(first.cursor, 'pointer');
    assert.strictEqual(getComputedStyle(buttons[0]!, '::before').display, 'none', 'no line before the first');
    assert.strictEqual(getComputedStyle(buttons[3]!, '::after').display, 'none', 'no line after the last');
    const line = getComputedStyle(buttons[1]!, '::before');
    assert.strictEqual(line.borderTopWidth, light.border.width.thick);
    near(assert, px(line.width), buttons[1]!.offsetWidth / 2 - px(light.size.xl) / 2, 'line spans to the number');
    assert.strictEqual(line.top, `${px(light.size.l) + px(light.size.xl) / 2}px`, 'line is centered on the number');

    assert.dom(buttons[0]).hasAttribute('data-step-status', 'complete').hasAttribute('aria-label', 'Step 1: Done is complete');
    assert.dom(buttons[1]).hasAttribute('data-step-status', 'current').hasAttribute('aria-label', 'Current step 2: Now');
    assert.dom(buttons[2]).hasAttribute('data-step-status', 'incomplete').hasAttribute('aria-label', 'Step 3: Next is incomplete');
    assert.dom(buttons[3]).hasAttribute('data-step-status', 'disabled').hasAttribute('aria-disabled', 'true').isDisabled();
    assert.strictEqual(getComputedStyle(buttons[3]!).cursor, 'not-allowed');
    assert.notStrictEqual(
      style(buttons[3]!, '.euiStepHorizontal__title').color,
      style(buttons[2]!, '.euiStepHorizontal__title').color,
      'disabled title is greyed'
    );
    const title = style(buttons[1]!, '.euiStepHorizontal__title');
    assert.strictEqual(title.fontWeight, String(light.font.weight.bold));
    assert.strictEqual(title.marginTop, light.size.s);
    assert.strictEqual(title.textAlign, 'center');
    assert.strictEqual(style(buttons[1]!, '.euiStepNumber').transform, 'matrix(1.1, 0, 0, 1.1, 0, 0)');
    near(assert, rect(buttons[1]!, '.euiStepNumber').width, 32 * 1.1, 'm number (scaled)');

    await click(buttons[1]!);
    buttons[3]!.disabled = false;
    await click(buttons[3]!);
    assert.deepEqual(clicked, [2], 'disabled step ignores clicks');

    const third = el(this.element, '[data-third]');
    state.size = 's';
    state.status = 'warning';
    await settled();
    assert.strictEqual(el(this.element, '[data-third]'), third, 'step element kept');
    assert.strictEqual(style(third, '.euiStepNumber').width, light.size.l, 's number');
    assert.strictEqual(getComputedStyle(buttons[1]!, '::before').top, `${px(light.size.l) + 12}px`);
    assert.dom(third).hasAttribute('data-step-status', 'warning');
    state.size = 'xs';
    await settled();
    assert.strictEqual(style(third, '.euiStepNumber').width, light.size.base, 'xs dot');
    assert.dom('[data-third] .euiStepNumber__number').doesNotExist();

    // RTL: logical connecting lines and order
    const rtlButtons = all(this.element, '[data-rtl] button');
    assert.true(rtlButtons[0]!.getBoundingClientRect().left > rtlButtons[1]!.getBoundingClientRect().left, 'first step on the right');
    assert.strictEqual(getComputedStyle(rtlButtons[1]!, '::before').right, '0px', 'line before is at the inline start (right)');
    assert.strictEqual(getComputedStyle(rtlButtons[0]!, '::after').left, '0px', 'line after is at the inline end (left)');
  });

  test('light/dark follow the nearest provider with sibling isolation', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'dark';
    }
    const state = new State();
    const crumbs: EuiBreadcrumb[] = [{ text: 'A', href: '#a' }, { text: 'B' }];
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <div data-light>
            <EuiTabs><EuiTab @isSelected={{true}}>A</EuiTab><EuiTab>B</EuiTab></EuiTabs>
            <EuiStepNumber @number={{1}} @status="incomplete" />
            <EuiSubSteps>s</EuiSubSteps>
            <EuiBreadcrumbs @breadcrumbs={{crumbs}} />
            <EuiPagination @pageCount={{3}} />
          </div>
          <EuiEmotionProvider @colorMode={{state.mode}}>
            <div data-dark>
              <EuiTabs><EuiTab @isSelected={{true}}>A</EuiTab><EuiTab>B</EuiTab></EuiTabs>
              <EuiStepNumber @number={{1}} @status="incomplete" />
              <EuiSubSteps>s</EuiSubSteps>
              <EuiBreadcrumbs @breadcrumbs={{crumbs}} />
              <EuiPagination @pageCount={{3}} />
            </div>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );

    for (const [name, theme] of [['light', light], ['dark', dark]] as const) {
      const scope = `[data-${name}]`;
      assert.strictEqual(style(this.element, `${scope} .euiTab-isSelected`).color, rgb(theme.colors.textHeading), `${name} selected tab`);
      assert.strictEqual(style(this.element, `${scope} .euiTab-isSelected`, '::after').borderBottomColor, rgb(theme.colors.primary), `${name} indicator`);
      assert.strictEqual(style(this.element, `${scope} .euiTab:not(.euiTab-isSelected)`).color, rgb(theme.colors.textSubdued));
      assert.strictEqual(style(this.element, `${scope} .euiStepNumber`).color, rgb(theme.colors.textParagraph), `${name} hollow number`);
      assert.strictEqual(style(this.element, `${scope} .euiSubSteps`).backgroundColor, rgb(theme.colors.lightestShade), `${name} sub steps`);
      assert.strictEqual(style(this.element, `${scope} .euiBreadcrumb:last-child .euiBreadcrumb__content`).color, rgb(theme.colors.textSubdued), `${name} breadcrumb`);
      assert.strictEqual(style(this.element, `${scope} [aria-current="page"].euiPaginationButton`).color, rgb(theme.colors.primary), `${name} active page`);
    }
    assert.true(
      contrast(style(this.element, '[data-dark] .euiTab-isSelected').color, rgb(dark.colors.emptyShade)) >= 4.5,
      'dark selected tab contrast'
    );

    state.mode = 'light';
    await settled();
    assert.strictEqual(style(this.element, '[data-dark] .euiSubSteps').backgroundColor, rgb(light.colors.lightestShade), 'reactive mode switch');
    assert.strictEqual(style(this.element, '[data-light] .euiSubSteps').backgroundColor, rgb(light.colors.lightestShade), 'sibling untouched');
  });

  test('native token overrides from JS objects and high contrast', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides | undefined = {
        colors: { LIGHT: { primary: '#663399', lightestShade: '#fafa00' } },
        size: { base: '20px', m: '10px' }
      };
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light" @borealisOverrides={{state.overrides}} @highContrastMode={{state.contrast}}>
          <div data-inside>
            <EuiTabs data-tabs><EuiTab @isSelected={{true}}>A</EuiTab><EuiTab>B</EuiTab></EuiTabs>
            <EuiTabs @size="s" data-small><EuiTab>A</EuiTab><EuiTab>B</EuiTab></EuiTabs>
            <EuiStepNumber @number={{1}} data-number />
            <EuiSubSteps data-sub>s</EuiSubSteps>
          </div>
        </EuiEmotionProvider>
        <EuiStepNumber @number={{1}} data-outside />
      </template>
    );

    assert.strictEqual(style(this.element, '[data-number]').backgroundColor, 'rgb(102, 51, 153)', 'primary override');
    assert.strictEqual(style(this.element, '[data-tabs] .euiTab-isSelected', '::after').borderBottomColor, 'rgb(102, 51, 153)');
    assert.strictEqual(style(this.element, '[data-sub]').backgroundColor, rgb('#fafa00'));
    assert.strictEqual(style(this.element, '[data-tabs]').columnGap, '20px', 'size.base override');
    assert.strictEqual(style(this.element, '[data-small]').columnGap, '10px', 'size.m override');
    assert.strictEqual(style(this.element, '[data-sub]').paddingTop, '20px');
    assert.strictEqual(style(this.element, '[data-outside]').backgroundColor, rgb(light.colors.primary), 'outside unaffected');

    state.overrides = undefined;
    state.contrast = 'preferred';
    await settled();
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    assert.strictEqual(style(this.element, '[data-number]').backgroundColor, rgb(hc.colors.primary), 'overrides removed');
    assert.strictEqual(style(this.element, '[data-sub]').borderTopStyle, 'solid', 'preferred contrast borders sub steps');
    assert.strictEqual(style(this.element, '[data-number]').borderTopWidth, hc.border.width.thick, 'preferred contrast step number border');
    assert.true(
      px(style(this.element, '[data-tabs] .euiTab-isSelected', '::after').borderBottomWidth) > px(hc.border.width.thick),
      'preferred contrast thickens the selected indicator'
    );

    state.contrast = 'forced';
    await settled();
    assert.strictEqual(style(this.element, '[data-tabs]').boxShadow, 'none', 'forced contrast uses a real border');
    assert.strictEqual(style(this.element, '[data-tabs]').borderBottomStyle, 'solid');

    await clearRender();
    assert.dom('[data-number]').doesNotExist();
  });

  test('attributes, classes and events pass through', async function (assert) {
    let tabClicks = 0;
    const onTab = () => tabClicks++;
    await render(
      <template>
        <EuiTabs @className="custom-tabs" aria-label="Sections" data-test-subj="tabs">
          <EuiTab @id="my-tab" class="custom-tab" data-test-subj="tab" {{on "click" onTab}}>A</EuiTab>
        </EuiTabs>
        <EuiSteps class="custom-steps"><EuiStep @title="T" class="custom-step" /></EuiSteps>
        <EuiSubSteps class="custom-sub" />
      </template>
    );
    assert.dom('[data-test-subj="tabs"]').hasClass('euiTabs').hasClass('custom-tabs').hasAttribute('aria-label', 'Sections').hasAttribute('role', 'tablist');
    assert.dom('#my-tab').hasClass('euiTab').hasClass('custom-tab').hasAttribute('type', 'button');
    await click('#my-tab');
    assert.strictEqual(tabClicks, 1);
    assert.dom('.custom-steps').hasClass('euiSteps');
    assert.dom('.custom-step').hasClass('euiStep');
    assert.dom('.custom-step .euiStepNumber__number').hasText('1', 'step defaults to 1');
    assert.dom('.custom-sub').hasClass('euiSubSteps');
  });
});
