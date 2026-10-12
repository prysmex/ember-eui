import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  render,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiDatePickerRange from '#src/components/eui-date-picker-range.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiRefreshInterval from '#src/components/eui-refresh-interval.gts';
import EuiSuperDatePicker from '#src/components/eui-super-date-picker.gts';
import EuiSuperUpdateButton from '#src/components/eui-super-date-picker/eui-super-update-button.gts';
import {
  euiButtonFillColor,
  euiFontSize
} from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const lightContext = resolveBorealisTheme('light');
const light = lightContext.euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const darkContext = resolveBorealisTheme('dark');
/** Upstream filled button colors (`{ color, backgroundColor }`). */
const fill = (context: typeof lightContext, color: string) =>
  euiButtonFillColor(context, color) as { color: string; backgroundColor: string };
const forms = (theme: typeof light) =>
  theme.components.forms as unknown as Record<string, string>;

type TimeChange = {
  start: string;
  end: string;
  isQuickSelection: boolean;
  isInvalid: boolean;
};

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** The computed px value of a CSS font-size expression (rem-based sizes). */
function fontSizePx(value: string) {
  const probe = document.createElement('span');
  probe.style.fontSize = value;
  document.body.appendChild(probe);
  const size = getComputedStyle(probe).fontSize;
  probe.remove();
  return size;
}

function el<T extends Element = HTMLElement>(selector: string, root: ParentNode = document) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function css(selector: string | Element, root: ParentNode = document) {
  return getComputedStyle(typeof selector === 'string' ? el(selector, root) : selector);
}

/**
 * Measured box in CSS pixels. The ember-qunit container is scaled, so rects
 * inside it are divided by that scale; portaled popovers are not scaled.
 */
function box(element: Element) {
  const container = document.querySelector<HTMLElement>('#ember-testing')!;
  const scale = container.contains(element)
    ? container.getBoundingClientRect().width / container.offsetWidth
    : 1;
  const rect = element.getBoundingClientRect();
  const round = (n: number) => Math.round(n * 100) / 100;
  return {
    width: round(rect.width / scale),
    height: round(rect.height / scale),
    left: rect.left / scale,
    right: rect.right / scale
  };
}

const inside = (key: string, selector: string) => `[data-p="${key}"] ${selector}`;

async function openStart(key: string) {
  await click(inside(key, '.euiDatePopoverButton--start'));
  await waitUntil(() => document.querySelector('.euiDatePopoverContent'));
}

async function openQuickSelect(key: string) {
  await click(inside(key, '[data-test-subj="superDatePickerToggleQuickMenuButton"]'));
  await waitUntil(() => document.querySelector('.euiQuickSelectPopover'));
}

async function chooseTab(name: string) {
  const tab = [...document.querySelectorAll<HTMLElement>('.euiDatePopoverContent .euiTab')].find(
    (t) => t.textContent!.trim() === name
  )!;
  await click(tab);
}

module('Integration | Component | Borealis date pickers', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiSuperDatePicker widths: restricted, without update button, full, auto, quick select only', async function (assert) {
    const noop = () => {};
    await render(
      <template>
        <div style="width: 900px">
          <EuiSuperDatePicker @onTimeChange={{noop}} data-p="restricted" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @showUpdateButton={{false}} data-p="no-button" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @width="full" data-p="full" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @width="full" @showUpdateButton={{false}} data-p="full-no-button" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @width="auto" data-p="auto" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @width="auto" @showUpdateButton={{false}} data-p="auto-no-button" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @isQuickSelectOnly={{true}} @width="full" data-p="quick" />
        </div>
      </template>
    );
    const base = light.base;
    const gap = 8;
    const button = base * 7;
    const input = base * 30;
    const root = (key: string) => el(`[data-p="${key}"]`);

    assert.strictEqual(css(root('restricted')).display, 'flex');
    assert.strictEqual(css(root('restricted')).columnGap, `${gap}px`);
    assert.strictEqual(box(root('restricted')).width, input + gap + button, 'restricted: 30 × base + gap + button');
    assert.strictEqual(box(root('no-button')).width, input, 'restricted without the update button');
    assert.strictEqual(box(root('full')).width, 900);
    assert.strictEqual(box(root('full-no-button')).width, 900);
    assert.strictEqual(css(root('auto')).display, 'inline-flex');
    assert.strictEqual(css(root('auto')).minWidth, `min(${400 / 2 + gap + button}px, 100%)`);
    assert.strictEqual(css(root('auto-no-button')).minWidth, 'min(200px, 100%)');

    // the range grows and the update button keeps upstream's 118px minimum
    const range = el(inside('restricted', '.euiDatePickerRange'));
    assert.strictEqual(css(range).flexGrow, '1');
    assert.strictEqual(css(range).overflow, 'hidden');
    const update = el(inside('restricted', '.euiSuperUpdateButton'));
    assert.strictEqual(box(update).width, 118);
    assert.strictEqual(box(range).width, input + gap + button - gap - 118);

    // quick select only forces auto width and hides the dates
    assert.strictEqual(css(root('quick')).display, 'inline-flex');
    assert.strictEqual(css(root('quick')).minWidth, '0px');
    assert.dom(inside('quick', '.euiDatePopoverButton')).doesNotExist();
    assert.dom(inside('quick', '[data-test-subj="superDatePickerToggleQuickMenuButton"]')).exists();
    assert.strictEqual(css(inside('quick', '.euiFormControlLayoutDelimited__delimiter')).paddingLeft, '0px');
    assert.strictEqual(css(inside('quick', '.euiFormControlLayout__prepend')).maxWidth, 'none');
    assert.true(box(root('quick')).width < 300, 'shrinks to the quick select and button');
  });

  test('EuiSuperDatePicker layout, popover buttons and quick select button: sizes, typography, compressed', async function (assert) {
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <EuiSuperDatePicker @onTimeChange={{noop}} @start="now-15m" @end="now" data-p="m" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @start="now-15m" @end="now" @compressed={{true}} data-p="s" />
        </EuiEmotionProvider>
      </template>
    );
    const layout = el(inside('m', '.euiFormControlLayout'));
    assert.dom(layout).hasClass('euiFormControlLayoutDelimited');
    assert.strictEqual(box(layout).height, 40);
    assert.strictEqual(css(layout).borderTopLeftRadius, '8px');
    assert.strictEqual(box(el(inside('s', '.euiFormControlLayout'))).height, 32);

    const wrapper = el(inside('m', '.euiFormControlLayout__childrenWrapper'));
    assert.strictEqual(css(wrapper).backgroundColor, rgb(forms(light)['background']!));
    assert.strictEqual(css(wrapper).color, rgb(light.colors.textParagraph));
    assert.strictEqual(css(wrapper).boxShadow, 'none', 'the state styles drop the wrapper border');

    // start/end popover buttons fill the range; "now" is narrower (upstream)
    const start = el(inside('m', '.euiDatePopoverButton--start'));
    const end = el(inside('m', '.euiDatePopoverButton--end'));
    for (const button of [start, end]) {
      assert.strictEqual(box(button).height, 40);
      assert.strictEqual(css(button).fontSize, fontSizePx(euiFontSize(lightContext, 's').fontSize));
      assert.true(css(button).fontFamily.includes('Inter'), 'Borealis font');
      assert.strictEqual(css(button).paddingLeft, '8px');
      assert.strictEqual(css(button).paddingRight, '8px');
      assert.strictEqual(css(button).backgroundColor, 'rgba(0, 0, 0, 0)');
      assert.strictEqual(css(button).borderTopWidth, '0px');
      assert.strictEqual(css(button).whiteSpace, 'nowrap');
      assert.strictEqual(css(button).textOverflow, 'ellipsis');
    }
    const startPopover = start.closest('.euiPopover')!;
    const endPopover = end.closest('.euiPopover')!;
    assert.strictEqual(css(startPopover).flexGrow, '1');
    assert.strictEqual(css(endPopover).flexGrow, '0.5', 'the "now" end is narrower');
    assert.true(box(startPopover).width > box(endPopover).width);
    assert.strictEqual(box(el(inside('s', '.euiDatePopoverButton--start'))).height, 32);
    assert.dom(start).hasAttribute('data-test-subj', 'superDatePickerstartDatePopoverButton').hasAttribute('type', 'button');
    assert.dom(end).hasAttribute('data-test-subj', 'superDatePickerendDatePopoverButton').hasAttribute('title', 'now');

    // delimiter
    const delimiter = el(inside('m', '.euiFormControlLayoutDelimited__delimiter'));
    assert.dom(delimiter).hasText('→');
    assert.strictEqual(css(delimiter).color, rgb(light.colors.textSubdued));

    // quick select prepend: upstream EuiFormPrepend button
    const quick = el(inside('m', '[data-test-subj="superDatePickerToggleQuickMenuButton"]'));
    assert.dom(quick).hasClass('euiFormPrepend').hasAttribute('aria-label', 'Date quick select').hasAttribute('type', 'button');
    assert.dom(quick.closest('.euiFormControlLayout__prepend')).exists('inside the layout prepend');
    assert.strictEqual(css(quick).display, 'flex');
    assert.strictEqual(css(quick).columnGap, '8px');
    assert.strictEqual(css(quick).color, rgb(light.colors.textPrimary));
    assert.strictEqual(css(quick).borderTopWidth, '0px');
    assert.strictEqual(quick.querySelectorAll('.euiIcon').length, 2, 'calendar and arrow icons');
    const compressedQuick = el(inside('s', '[data-test-subj="superDatePickerToggleQuickMenuButton"]'));
    assert.strictEqual(css(compressedQuick).paddingLeft, '4px', 'compressed side padding');
    assert.strictEqual(css(quick).paddingLeft, '8px');

    // update button sizes
    assert.strictEqual(box(el(inside('m', '.euiSuperUpdateButton'))).height, 40);
    assert.strictEqual(box(el(inside('s', '.euiSuperUpdateButton'))).height, 32);
  });

  test('EuiSuperDatePicker states: disabled, invalid, loading and default', async function (assert) {
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <EuiSuperDatePicker @onTimeChange={{noop}} @isDisabled={{true}} data-p="disabled" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @start="now" @end="now-15m" data-p="invalid" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @isLoading={{true}} data-p="loading" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @isLoading={{true}} @showUpdateButton={{false}} data-p="layout-loading" />
        </EuiEmotionProvider>
      </template>
    );
    // disabled
    const disabledWrapper = css(inside('disabled', '.euiFormControlLayout__childrenWrapper'));
    assert.strictEqual(disabledWrapper.backgroundColor, rgb(forms(light)['backgroundDisabled']!));
    assert.strictEqual(disabledWrapper.color, rgb(forms(light)['colorDisabled']!));
    assert.strictEqual(disabledWrapper.cursor, 'not-allowed');
    assert.dom(inside('disabled', '.euiFormControlLayout')).hasClass('euiFormControlLayout-isDisabled');
    for (const position of ['start', 'end']) {
      const button = el(inside('disabled', `.euiDatePopoverButton--${position}`));
      assert.dom(button).isDisabled().hasClass('euiDatePopoverButton-disabled');
      assert.strictEqual(css(button).cursor, 'not-allowed');
    }
    const quick = el(inside('disabled', '[data-test-subj="superDatePickerToggleQuickMenuButton"]'));
    assert.dom(quick).isDisabled();
    assert.strictEqual(css(quick).color, rgb(forms(light)['colorDisabled']!));
    assert.dom(inside('disabled', '.euiSuperUpdateButton')).isDisabled();
    assert.dom(inside('disabled', '.euiSuperDatePicker')).doesNotExist();
    assert.dom('[data-p="disabled"]').doesNotHaveClass('euiSuperDatePicker--needsUpdating');

    // invalid: danger text, invalid outline, warning icon, danger delimiter
    const invalidWrapper = css(inside('invalid', '.euiFormControlLayout__childrenWrapper'));
    assert.strictEqual(invalidWrapper.color, rgb(light.colors.textDanger));
    assert.strictEqual(invalidWrapper.outlineStyle, 'solid');
    assert.strictEqual(invalidWrapper.outlineWidth, '1px');
    assert.strictEqual(invalidWrapper.outlineColor, rgb(forms(light)['borderInvalid']!));
    assert.dom(inside('invalid', '.euiFormControlLayoutIcons [data-icon-type="warning"], .euiFormControlLayoutIcons .euiIcon')).exists('warning icon');
    assert.strictEqual(css(inside('invalid', '.euiFormControlLayoutDelimited__delimiter')).color, rgb(light.colors.textDanger));
    assert.dom(inside('invalid', '.euiFormControlLayoutDelimited')).hasClass('euiFormControlLayoutDelimited--isInvalid');
    const invalidStart = el(inside('invalid', '.euiDatePopoverButton--start'));
    assert.dom(invalidStart).hasClass('euiDatePopoverButton-isInvalid').hasAttribute('title', /^Invalid date: /);
    assert.dom(inside('invalid', '.euiSuperUpdateButton')).isDisabled();

    // loading: the update button spins; without it the layout spins (upstream)
    assert.dom(inside('loading', '.euiSuperUpdateButton')).hasAttribute('aria-busy', 'true').hasText('Updating');
    assert.dom(inside('loading', '.euiSuperUpdateButton .euiBorealisLoadingSpinner')).exists();
    assert.dom(inside('loading', '.euiFormControlLayoutIcons .euiBorealisLoadingSpinner')).doesNotExist();
    assert.dom(inside('layout-loading', '.euiFormControlLayoutIcons .euiBorealisLoadingSpinner')).exists();
  });

  test('EuiSuperDatePicker selected and needs-updating states, update button labels and colors', async function (assert) {
    const changes: TimeChange[] = [];
    const refreshes: unknown[] = [];
    const onTimeChange = (change: TimeChange) => changes.push(change);
    const onRefresh = (props: unknown) => refreshes.push(props);
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <EuiSuperDatePicker @onTimeChange={{onTimeChange}} @onRefresh={{onRefresh}} @start="now-15m" @end="now" data-p="a" />
        </EuiEmotionProvider>
      </template>
    );
    const update = el(inside('a', '.euiSuperUpdateButton'));
    assert.dom(update).hasText('Refresh').hasAttribute('data-test-subj', 'superDatePickerApplyTimeButton');
    assert.strictEqual(css(update).backgroundColor, rgb(fill(lightContext, 'primary').backgroundColor), 'filled primary');

    // open the start popover: the selected button gets the focus outline
    await openStart('a');
    const start = el(inside('a', '.euiDatePopoverButton--start'));
    assert.dom(start).hasClass('euiDatePopoverButton-isSelected').hasAttribute('aria-expanded', 'true');
    assert.strictEqual(css(start).outlineStyle, 'solid');
    assert.strictEqual(css(start).outlineWidth, `${parseFloat(light.border.width.thick)}px`);
    assert.strictEqual(css(start).outlineColor, rgb(forms(light)['borderFocused']!));

    // change the start from the Relative tab: the range needs updating
    await chooseTab('Relative');
    await fillIn(el('[data-test-subj="superDatePickerRelativeDateInputNumber"]'), '4');
    assert.strictEqual(changes.length, 0, 'with the update button nothing applies yet');
    await triggerKeyEvent(el('.euiDatePopoverContent').closest('.euiPopover__panel')!, 'keydown', 'Escape');
    await waitUntil(() => !document.querySelector('.euiDatePopoverContent'));

    assert.dom('[data-p="a"]').hasClass('euiSuperDatePicker--needsUpdating');
    const wrapper = css(inside('a', '.euiFormControlLayout__childrenWrapper'));
    assert.strictEqual(wrapper.color, rgb(light.colors.textSuccess));
    assert.strictEqual(wrapper.outlineStyle, 'solid');
    assert.strictEqual(wrapper.outlineColor, rgb(light.colors.success));
    assert.dom(inside('a', '.euiDatePopoverButton--start')).hasClass('euiDatePopoverButton-needsUpdating').hasAttribute('title', /^Update needed: .*minutes ago$/);
    assert.strictEqual(css(inside('a', '.euiFormControlLayoutDelimited__delimiter')).color, rgb(light.colors.textSuccess), 'delimiter inherits');
    assert.dom(update).hasText('Update');
    assert.strictEqual(css(update).backgroundColor, rgb(fill(lightContext, 'success').backgroundColor), 'success fill');

    await click(update);
    assert.deepEqual(changes, [{ start: 'now-4m', end: 'now', isQuickSelection: false, isInvalid: false }]);
    assert.strictEqual(refreshes.length, 0);
    assert.dom(update).hasText('Refresh');
    await click(update);
    assert.strictEqual(refreshes.length, 1, 'unchanged: refresh');
  });

  test('EuiSuperUpdateButton variants: fill, base, icon only, needs update, loading, disabled', async function (assert) {
    class State {
      @tracked needsUpdate = false;
      @tracked isLoading = false;
    }
    const state = new State();
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <EuiSuperUpdateButton @onClick={{noop}} @needsUpdate={{state.needsUpdate}} @isLoading={{state.isLoading}} data-b="fill" />
          <EuiSuperUpdateButton @onClick={{noop}} @fill={{false}} data-b="base" />
          <EuiSuperUpdateButton @onClick={{noop}} @iconOnly={{true}} @needsUpdate={{state.needsUpdate}} data-b="icon" />
          <EuiSuperUpdateButton @onClick={{noop}} @iconOnly={{true}} @size="s" data-b="icon-s" />
          <EuiSuperUpdateButton @onClick={{noop}} @isDisabled={{true}} data-b="disabled" />
        </EuiEmotionProvider>
      </template>
    );
    const filled = el('[data-b="fill"]');
    assert.dom(filled).hasText('Refresh').doesNotHaveAttribute('aria-busy');
    assert.strictEqual(css(filled).backgroundColor, rgb(fill(lightContext, 'primary').backgroundColor));
    assert.strictEqual(css(filled).minInlineSize, '118px');
    assert.dom(filled.querySelector('.euiIcon')).exists('refresh icon');

    const base = el('[data-b="base"]');
    assert.notStrictEqual(css(base).backgroundColor, rgb(fill(lightContext, 'primary').backgroundColor), 'not filled');

    const icon = el('[data-b="icon"]');
    assert.dom(icon).hasClass('euiSuperUpdateButton').hasAttribute('aria-label', 'Refresh').hasAttribute('data-test-subj', 'superDatePickerApplyTimeButton');
    assert.strictEqual(box(icon).width, 40);
    assert.strictEqual(box(icon).height, 40);
    assert.strictEqual(css(icon).backgroundColor, rgb(fill(lightContext, 'primary').backgroundColor), 'filled by default');
    assert.strictEqual(box(el('[data-b="icon-s"]')).height, 32);

    state.needsUpdate = true;
    await settled();
    assert.strictEqual(el('[data-b="fill"]'), filled, 'no element replacement');
    assert.dom(filled).hasText('Update');
    assert.strictEqual(css(filled).backgroundColor, rgb(fill(lightContext, 'success').backgroundColor));
    assert.dom(icon).hasAttribute('aria-label', 'Update');
    assert.strictEqual(css(icon).backgroundColor, rgb(fill(lightContext, 'success').backgroundColor));

    state.isLoading = true;
    await settled();
    assert.dom(filled).hasText('Updating').hasAttribute('aria-busy', 'true').isDisabled();

    const disabled = el('[data-b="disabled"]');
    assert.dom(disabled).isDisabled();
    assert.strictEqual(css(disabled).cursor, 'not-allowed');
  });

  test('quick select popover: panels, quick select keyboard and aria, commonly and recently used', async function (assert) {
    const changes: TimeChange[] = [];
    const onTimeChange = (change: TimeChange) => changes.push(change);
    const recent = [
      { start: 'now-2d', end: 'now', label: 'Last two days' },
      { start: 'now-1y', end: 'now' }
    ];
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <EuiSuperDatePicker @onTimeChange={{onTimeChange}} @recentlyUsedRanges={{recent}} @start="now-15m" @end="now" data-p="a" />
        </EuiEmotionProvider>
      </template>
    );
    await openQuickSelect('a');
    const popover = el('.euiQuickSelectPopover');
    assert.dom(popover).hasAttribute('data-test-subj', 'superDatePickerQuickMenu');
    assert.strictEqual(box(popover).width, 400, 'form max width');
    assert.dom(inside('a', '[data-test-subj="superDatePickerToggleQuickMenuButton"]')).hasAttribute('aria-expanded', 'true');

    const panels = [...popover.querySelectorAll<HTMLElement>('.euiQuickSelectPanel')];
    assert.strictEqual(panels.length, 3, 'quick select, commonly used, recently used');
    assert.deepEqual(panels.map((p) => p.tagName), ['FIELDSET', 'FIELDSET', 'FIELDSET']);
    assert.strictEqual(css(panels[0]!).borderTopStyle, 'none', 'first panel has no divider');
    assert.strictEqual(css(panels[0]!).marginInlineStart, '0px', 'fieldset reset');
    for (const panel of panels.slice(1)) {
      assert.strictEqual(css(panel).borderTopWidth, '1px');
      assert.strictEqual(css(panel).borderTopColor, rgb(light.border.color));
      assert.strictEqual(css(panel).paddingTop, '12px');
      assert.strictEqual(css(panel).marginTop, '12px');
    }
    const titles = panels.map((p) => el('legend.euiQuickSelectPanel__title', p));
    assert.deepEqual(titles.map((t) => t.textContent!.trim()), ['Quick select', 'Commonly used', 'Recently used date ranges']);
    for (const title of titles) {
      assert.dom(title).hasClass('euiTitle');
      assert.strictEqual(css(title).float, 'left');
      assert.strictEqual(css(title).marginBottom, '12px');
      assert.strictEqual(css(title).fontWeight, String(light.font.weight.bold));
      assert.strictEqual(css(title).color, rgb(light.colors.textHeading));
    }
    const section = css(el('.euiQuickSelectPanel__section', panels[1]!));
    assert.strictEqual(section.maxHeight, '144px');
    assert.strictEqual(section.overflowY, 'auto');
    assert.strictEqual(section.clear, 'both');

    // quick select: previous/next above the inputs, labelled; SR description
    const quick = panels[0]!;
    assert.dom(quick).hasAttribute('aria-describedby');
    const description = el(`#${quick.getAttribute('aria-describedby')}`);
    assert.dom(description).hasText('Currently set to last 15 Minutes.');
    const windowButtons = el('.euiQuickSelect__timeWindowButtons', quick);
    assert.strictEqual(css(windowButtons).position, 'absolute');
    assert.strictEqual(css(windowButtons).right, '0px');
    assert.dom('[aria-label="Previous time window"]', quick).exists();
    assert.dom('[aria-label="Next time window"]', quick).exists();
    const value = el<HTMLInputElement>('input[aria-label="Time value"]', quick);
    assert.dom(value).hasValue('15').hasAttribute('aria-describedby', `${description.id} ${el('legend', quick).id}`);
    assert.strictEqual(box(value).height, 32, 'compressed');
    const apply = el('[data-test-subj="superDatePickerQuickSelectApplyButton"]', quick);
    await fillIn(value, '');
    assert.dom(apply).isDisabled('an empty value cannot apply');
    await fillIn(value, '3');
    await fillIn(el('select[aria-label="Time unit"]', quick), 'h');
    await triggerKeyEvent(value, 'keydown', 'Enter');
    assert.deepEqual(changes.at(-1), { start: 'now-3h', end: 'now', isQuickSelection: true, isInvalid: false }, 'Enter applies');
    await waitUntil(() => !document.querySelector('.euiQuickSelectPopover'));

    // commonly used: upstream test subjects, two columns, click applies
    await openQuickSelect('a');
    const today = el('[data-test-subj="superDatePickerCommonlyUsed_Today"]');
    assert.dom(today.closest('li')).hasClass('euiQuickSelectPopover__sectionItem');
    const list = today.closest('ul')!;
    assert.strictEqual(css(list).listStyleType, 'none');
    assert.strictEqual(css(list).paddingLeft, '0px');
    assert.dom(list).hasAttribute('aria-labelledby', el('.euiQuickSelectPanel:nth-child(2) legend').id);
    await click(today);
    assert.deepEqual(changes.at(-1), { start: 'now/d', end: 'now/d', isQuickSelection: true, isInvalid: false });
    await waitUntil(() => !document.querySelector('.euiQuickSelectPopover'));

    // recently used: label, or "start → end"
    await openQuickSelect('a');
    const recentLinks = [...document.querySelectorAll<HTMLElement>('.euiQuickSelectPanel:nth-child(3) .euiLink')];
    assert.deepEqual(recentLinks.map((l) => l.textContent!.trim()), ['Last two days', 'now-1y → now']);
    await click(recentLinks[1]!);
    assert.deepEqual(changes.at(-1), { start: 'now-1y', end: 'now', isQuickSelection: true, isInvalid: false });
  });

  test('refresh interval: quick select panel styles, compressed full-width fields, invalid while running', async function (assert) {
    class State {
      @tracked isPaused = false;
      @tracked refreshInterval = 5000;
    }
    const state = new State();
    const changes: { refreshInterval: number; isPaused: boolean }[] = [];
    const apply = (change: { refreshInterval: number; isPaused: boolean }) => changes.push(change);
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <div style="width: 400px">
            <EuiRefreshInterval @isPaused={{state.isPaused}} @refreshInterval={{state.refreshInterval}} @applyRefreshInterval={{apply}} data-r="a" />
          </div>
          <EuiSuperDatePicker @onTimeChange={{noop}} @onRefreshChange={{apply}} data-p="p" />
        </EuiEmotionProvider>
      </template>
    );
    const root = el('[data-r="a"]');
    assert.strictEqual(root.tagName, 'FIELDSET');
    assert.dom(root).hasClass('euiRefreshInterval').hasClass('euiQuickSelectPanel');
    assert.strictEqual(css(root).borderTopStyle, 'none', 'first panel');
    assert.strictEqual(css(root).paddingLeft, '0px', 'fieldset reset');
    assert.dom('legend', root).hasText('Refresh every');
    const input = el<HTMLInputElement>('[data-test-subj="superDatePickerRefreshIntervalInput"]', root);
    const select = el('[data-test-subj="superDatePickerRefreshIntervalUnitsSelect"]', root);
    assert.strictEqual(box(input).height, 32);
    assert.strictEqual(box(select).height, 32);
    assert.strictEqual(css(input).maxWidth, '100%', 'full width');
    assert.dom(input).hasAttribute('aria-label', 'Refresh interval value').doesNotHaveAttribute('aria-invalid');
    assert.dom(select).hasAttribute('aria-label', 'Refresh interval units');
    assert.dom('.euiRefreshInterval__startButton', root).hasText('Stop');

    await fillIn(input, '');
    assert.dom(input).hasAttribute('aria-invalid', 'true', 'invalid while running');
    state.isPaused = true;
    await settled();
    assert.dom(input).doesNotHaveAttribute('aria-invalid', 'not while paused');

    // inside the super date picker it is the last quick select panel
    await openQuickSelect('p');
    const panels = [...document.querySelectorAll('.euiQuickSelectPopover .euiQuickSelectPanel')];
    const last = panels.at(-1)!;
    assert.dom(last).hasClass('euiRefreshInterval');
    assert.strictEqual(css(last).borderTopWidth, '1px', 'divider like the other panels');
  });

  test('date popover: tabs, absolute calendar, relative and now tabs', async function (assert) {
    const changes: TimeChange[] = [];
    const onTimeChange = (change: TimeChange) => changes.push(change);
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <EuiSuperDatePicker
            @onTimeChange={{onTimeChange}}
            @showUpdateButton={{false}}
            @start="2020-03-10T10:30:00.000Z"
            @end="now"
            data-p="a"
          />
        </EuiEmotionProvider>
      </template>
    );
    await openStart('a');
    const content = el('.euiDatePopoverContent');
    assert.strictEqual(box(content).width, 400, 'form max width');
    assert.deepEqual(
      [...content.querySelectorAll('.euiTab')].map((t) => t.textContent!.trim()),
      ['Absolute', 'Relative', 'Now']
    );
    assert.dom('.euiTab[aria-selected="true"]', content).hasText('Absolute', 'absolute dates open the Absolute tab');

    // the calendar: upstream react-datepicker styles on the Ember markup
    const picker = el('.euiDatePicker', content);
    assert.strictEqual(css(picker).display, 'block');
    assert.strictEqual(css(el('.euiFormControlLayout', picker)).boxShadow, 'none', 'inline: no frame');
    const calendar = el('.react-datepicker', content);
    assert.strictEqual(css(calendar).display, 'flex');
    assert.strictEqual(css(calendar).paddingTop, '8px');
    assert.strictEqual(css(calendar).fontSize, fontSizePx(euiFontSize(lightContext, 'xs').fontSize));
    assert.strictEqual(css(calendar).color, rgb(light.colors.textParagraph));
    const previous = el('.react-datepicker__navigation--previous', calendar);
    assert.dom(previous).hasClass('euiButtonIcon').hasAttribute('aria-label', 'Previous month');
    assert.strictEqual(css(previous).position, 'absolute');
    assert.strictEqual(css(previous).top, '8px');
    assert.strictEqual(box(previous).width, 32, 'size s button icon');
    assert.dom('.react-datepicker__navigation--next', calendar).hasAttribute('aria-label', 'Next month');
    assert.dom('select[aria-label="Month"]', calendar).hasValue('2');
    assert.dom('select[aria-label="Year"]', calendar).hasValue('2020');

    const days = [...calendar.querySelectorAll<HTMLElement>('.react-datepicker__day')];
    const day = days.find((d) => !d.className.includes('--outside-month') && !d.className.includes('--selected'))!;
    assert.strictEqual(box(day).width, 32);
    assert.strictEqual(box(day).height, 32);
    assert.strictEqual(css(day).borderRadius, '8px');
    assert.strictEqual(css(day).color, rgb(light.colors.textHeading));
    assert.strictEqual(css(day).fontWeight, String(light.font.weight.medium));
    const outside = days.find((d) => d.className.includes('--outside-month'))!;
    assert.strictEqual(css(outside).color, rgb(light.colors.textSubdued));
    const selected = el('.react-datepicker__day--selected', calendar);
    assert.dom(selected).hasText('10');
    assert.strictEqual(css(selected).backgroundColor, rgb(fill(lightContext, 'primary').backgroundColor));
    assert.strictEqual(css(selected).color, rgb(fill(lightContext, 'primary').color));
    assert.strictEqual(css(el('.react-datepicker__week', calendar)).display, 'flex');
    assert.strictEqual(css(el('.react-datepicker__day-name', calendar)).color, rgb(light.colors.textSubdued));

    const time = el('.react-datepicker__time-container', calendar);
    assert.strictEqual(css(time).backgroundColor, rgb(light.colors.backgroundBaseSubdued));
    const list = el('.react-datepicker__time-list', calendar);
    assert.strictEqual(css(list).overflowY, 'auto');
    assert.strictEqual(css(list).listStyleType, 'none');
    const selectedTime = el('.react-datepicker__time-list-item--selected', calendar);
    assert.strictEqual(css(selectedTime).backgroundColor, rgb(fill(lightContext, 'primary').backgroundColor));

    // the text input under the calendar
    const form = el('.euiAbsoluteTabDateForm', content);
    assert.strictEqual(css(form).paddingLeft, '8px');
    assert.strictEqual(css(form).paddingBottom, '8px');
    const text = el<HTMLInputElement>('[data-test-subj="superDatePickerAbsoluteDateInput"]', content);
    assert.dom(text).hasAttribute('aria-labelledby', el('.euiFormLabel', form).id);
    assert.dom(el('.euiFormLabel', form)).hasText('Start date');

    // picking a day changes the start (no update button: applied at once)
    const fifteenth = days.find((d) => d.textContent!.trim() === '15' && !d.className.includes('outside'))!;
    await click(fifteenth);
    assert.strictEqual(changes.length, 1);
    assert.true(changes[0]!.start.startsWith('2020-03-15'), changes[0]!.start);
    assert.dom(fifteenth).hasClass('react-datepicker__day--selected');

    // relative tab
    await chooseTab('Relative');
    const count = el<HTMLInputElement>('[data-test-subj="superDatePickerRelativeDateInputNumber"]', content);
    assert.dom(count).hasAttribute('aria-label', 'Time span amount');
    const countDescription = el(`#${count.getAttribute('aria-describedby')}`);
    assert.true(countDescription.textContent!.startsWith('The unit is changeable. Currently set to'));
    assert.dom('[data-test-subj="superDatePickerRelativeDateInputUnitSelector"]', content).hasAttribute('aria-label', 'Relative time span');
    assert.strictEqual(css(el('.euiForm', content)).paddingLeft, '8px', 'padding s');
    assert.dom('[data-test-subj="superDatePickerRelativeDateRoundSwitch"]', content).exists();
    await fillIn(count, '4');
    await fillIn(el('[data-test-subj="superDatePickerRelativeDateInputUnitSelector"]', content), 'h');
    assert.strictEqual(changes.at(-1)!.start, 'now-4h');
    await fillIn(count, '');
    assert.dom(count).hasAttribute('aria-invalid', 'true');

    // now tab
    await chooseTab('Now');
    const nowContent = el('.euiDatePopoverContent__now', content);
    assert.strictEqual(css(nowContent).paddingTop, '16px', 'padding m');
    const nowButton = el('[data-test-subj="superDatePickerNowButton"]', content);
    assert.dom(nowButton).hasText('Set start date and time to now');
    await click(nowButton);
    assert.strictEqual(changes.at(-1)!.start, 'now');
  });

  test('keyboard and aria: tab order, popover expansion, Escape closes, tab arrow keys', async function (assert) {
    const noop = () => {};
    await render(
      <template>
        <EuiSuperDatePicker @onTimeChange={{noop}} @start="now-15m" @end="now" data-p="a" />
      </template>
    );
    const focusables = [...el('[data-p="a"]').querySelectorAll<HTMLElement>('button:not([disabled])')];
    assert.deepEqual(
      focusables.map((b) => b.getAttribute('data-test-subj')),
      [
        'superDatePickerToggleQuickMenuButton',
        'superDatePickerstartDatePopoverButton',
        'superDatePickerendDatePopoverButton',
        'superDatePickerApplyTimeButton'
      ],
      'DOM (tab) order'
    );
    const start = el(inside('a', '.euiDatePopoverButton--start'));
    assert.dom(start).hasAttribute('aria-expanded', 'false');
    await openStart('a');
    const panel = el('.euiDatePopoverContent').closest<HTMLElement>('.euiPopover__panel')!;
    assert.dom(panel).hasAttribute('role', 'dialog');
    assert.dom(start).hasAttribute('aria-expanded', 'true').hasAttribute('aria-controls', panel.id);
    await waitUntil(() => panel.contains(document.activeElement));
    await triggerKeyEvent(panel, 'keydown', 'Escape');
    await waitUntil(() => !document.querySelector('.euiDatePopoverContent'));
    assert.dom(start).hasAttribute('aria-expanded', 'false');

    // tabs keep the navigation family's keyboard support
    await openStart('a');
    const tablist = el('.euiDatePopoverContent [role="tablist"]');
    const tabs = [...tablist.querySelectorAll<HTMLElement>('[role="tab"]')];
    tabs[1]!.focus();
    await triggerKeyEvent(tabs[1]!, 'keydown', 'ArrowRight');
    assert.strictEqual(document.activeElement, tabs[2], 'ArrowRight moves to Now');
  });

  test('reactive args update in place: compressed, disabled, width, update button, range', async function (assert) {
    class State {
      @tracked compressed = false;
      @tracked isDisabled = false;
      @tracked width: 'restricted' | 'full' | 'auto' = 'restricted';
      @tracked showUpdateButton: boolean | 'iconOnly' = true;
      @tracked start = 'now-15m';
      @tracked end = 'now';
    }
    const state = new State();
    const noop = () => {};
    await render(
      <template>
        <div style="width: 900px">
          <EuiSuperDatePicker
            @onTimeChange={{noop}}
            @compressed={{state.compressed}}
            @isDisabled={{state.isDisabled}}
            @width={{state.width}}
            @showUpdateButton={{state.showUpdateButton}}
            @start={{state.start}}
            @end={{state.end}}
            data-p="a"
          />
        </div>
      </template>
    );
    const root = el('[data-p="a"]');
    const layout = el(inside('a', '.euiFormControlLayout'));
    const start = el(inside('a', '.euiDatePopoverButton--start'));
    const quick = el(inside('a', '[data-test-subj="superDatePickerToggleQuickMenuButton"]'));

    state.compressed = true;
    await settled();
    assert.strictEqual(box(layout).height, 32);
    assert.strictEqual(css(quick).paddingLeft, '4px');

    state.isDisabled = true;
    await settled();
    assert.dom(start).isDisabled();
    assert.dom(quick).isDisabled();
    assert.strictEqual(css(inside('a', '.euiFormControlLayout__childrenWrapper')).cursor, 'not-allowed');

    state.isDisabled = false;
    state.width = 'full';
    await settled();
    assert.strictEqual(box(root).width, 900);
    state.width = 'auto';
    await settled();
    assert.strictEqual(css(root).display, 'inline-flex');

    state.showUpdateButton = 'iconOnly';
    await settled();
    assert.dom(inside('a', '.euiSuperUpdateButton')).hasAttribute('aria-label', 'Refresh');
    state.showUpdateButton = false;
    await settled();
    assert.dom(inside('a', '.euiSuperUpdateButton')).doesNotExist();

    state.start = 'now';
    state.end = 'now-1h';
    await settled();
    assert.dom(start).hasClass('euiDatePopoverButton-isInvalid');
    assert.strictEqual(css(inside('a', '.euiFormControlLayout__childrenWrapper')).color, rgb(light.colors.textDanger));

    assert.strictEqual(el('[data-p="a"]'), root, 'root kept');
    assert.strictEqual(el(inside('a', '.euiFormControlLayout')), layout, 'layout kept');
    assert.strictEqual(el(inside('a', '.euiDatePopoverButton--start')), start, 'button kept');
    assert.strictEqual(el(inside('a', '[data-test-subj="superDatePickerToggleQuickMenuButton"]')), quick, 'quick select kept');
  });

  test('light/dark nearest provider, sibling isolation and JS-object token overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const own: EuiBorealisOverrides = {
      border: { radius: { control: '13px' } },
      colors: { LIGHT: { textSubdued: '#663399' }, DARK: { textSubdued: '#aa77dd' } }
    };
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}}>
          <EuiSuperDatePicker @onTimeChange={{noop}} data-p="parent" />
          <EuiEmotionProvider @borealisOverrides={{own}}>
            <EuiSuperDatePicker @onTimeChange={{noop}} data-p="child" />
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <EuiSuperDatePicker @onTimeChange={{noop}} data-p="fixed" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiSuperDatePicker @onTimeChange={{noop}} data-p="sibling" />
        </EuiEmotionProvider>
      </template>
    );
    const wrapper = (key: string) => css(inside(key, '.euiFormControlLayout__childrenWrapper'));
    const delimiter = (key: string) => css(inside(key, '.euiFormControlLayoutDelimited__delimiter'));
    assert.strictEqual(wrapper('parent').backgroundColor, rgb(forms(light)['background']!));
    assert.strictEqual(wrapper('parent').color, rgb(light.colors.textParagraph));
    assert.strictEqual(css(inside('child', '.euiFormControlLayout')).borderTopLeftRadius, '13px');
    assert.strictEqual(delimiter('child').color, rgb('#663399'), 'override drives the delimiter');
    assert.strictEqual(delimiter('parent').color, rgb(light.colors.textSubdued));

    state.mode = 'dark';
    await settled();
    assert.strictEqual(wrapper('parent').backgroundColor, rgb(forms(dark)['background']!));
    assert.strictEqual(wrapper('parent').color, rgb(dark.colors.textParagraph));
    assert.strictEqual(delimiter('parent').color, rgb(dark.colors.textSubdued));
    assert.strictEqual(css(inside('parent', '.euiSuperUpdateButton')).backgroundColor, rgb(fill(darkContext, 'primary').backgroundColor));
    assert.strictEqual(wrapper('child').backgroundColor, rgb(forms(dark)['background']!), 'child inherits the mode');
    assert.strictEqual(delimiter('child').color, rgb('#aa77dd'), 'mode-specific override');
    assert.strictEqual(wrapper('fixed').backgroundColor, rgb(forms(light)['background']!), 'light island');
    assert.strictEqual(wrapper('sibling').backgroundColor, rgb(forms(light)['background']!), 'sibling isolated');

    // dark popovers: the quick select panel dividers follow the mode
    await openQuickSelect('parent');
    const divider = [...document.querySelectorAll<HTMLElement>('.euiQuickSelectPanel')][1]!;
    assert.strictEqual(css(divider).borderTopColor, rgb(dark.border.color));

    state.overrides = { border: { radius: { control: '4px' } } };
    await settled();
    assert.strictEqual(css(inside('parent', '.euiFormControlLayout')).borderTopLeftRadius, '4px');
    assert.strictEqual(css(inside('child', '.euiFormControlLayout')).borderTopLeftRadius, '13px', 'nearest override wins');
    assert.strictEqual(css(inside('sibling', '.euiFormControlLayout')).borderTopLeftRadius, '8px');
  });

  test('RTL, high contrast and EuiDatePickerRange', async function (assert) {
    class State {
      @tracked isInvalid = false;
      @tracked compressed = false;
    }
    const state = new State();
    const noop = () => {};
    await render(
      <template>
        <div dir="rtl" style="width: 900px">
          <EuiSuperDatePicker @onTimeChange={{noop}} data-p="rtl" />
        </div>
        <EuiEmotionProvider @highContrastMode="preferred">
          <EuiSuperDatePicker @onTimeChange={{noop}} data-p="hc" />
          <EuiSuperDatePicker @onTimeChange={{noop}} @start="now" @end="now-1h" data-p="hc-invalid" />
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiDatePickerRange @isInvalid={{state.isInvalid}} @compressed={{state.compressed}} data-p="range">
            <:start as |className|><input class={{className}} aria-label="Start date" type="date" /></:start>
            <:end as |className|><input class={{className}} aria-label="End date" type="date" /></:end>
          </EuiDatePickerRange>
          <EuiDatePickerRange @iconType={{false}} @fullWidth={{true}} @disabled={{true}} data-p="range-plain">
            <:start as |className|><input class={{className}} aria-label="Start" disabled /></:start>
            <:end as |className|><input class={{className}} aria-label="End" disabled /></:end>
          </EuiDatePickerRange>
          <EuiDatePickerRange @readOnly={{true}} @delimiter="to" data-p="range-ro">
            <:start as |className|><input class={{className}} aria-label="Start" readonly /></:start>
            <:end as |className|><input class={{className}} aria-label="End" readonly /></:end>
          </EuiDatePickerRange>
        </EuiEmotionProvider>
      </template>
    );
    // RTL: the quick select sits on the right, the update button on the left
    const quick = box(el(inside('rtl', '.euiFormControlLayout__prepend')));
    const start = box(el(inside('rtl', '.euiDatePopoverButton--start')));
    const update = box(el(inside('rtl', '.euiSuperUpdateButton')));
    assert.true(quick.left > start.left, 'prepend on the inline start (right)');
    assert.true(update.right < start.left, 'update button at the inline end (left)');

    // preferred high contrast: the group border, none on the inner wrapper
    const hcBorder = getComputedStyle(el(inside('hc', '.euiFormControlLayout')), '::after');
    assert.strictEqual(hcBorder.borderTopStyle, 'solid');
    assert.strictEqual(hcBorder.borderTopColor, rgb(light.border.color));
    assert.strictEqual(css(inside('hc', '.euiFormControlLayout__childrenWrapper')).borderTopStyle, 'none');
    assert.strictEqual(css(inside('hc-invalid', '.euiFormControlLayout__childrenWrapper')).outlineWidth, '2px', 'thicker invalid outline');

    // EuiDatePickerRange: delimited layout, calendar icon, centered inputs
    const range = el('[data-p="range"]');
    assert.dom(range).hasClass('euiDatePickerRange');
    const layout = el('.euiFormControlLayoutDelimited', range);
    assert.strictEqual(box(layout).height, 40);
    assert.strictEqual(box(layout).width, 400, 'form max width');
    assert.dom('.euiFormControlLayoutIcons .euiIcon', range).exists('calendar icon by default');
    const startInput = el('input[aria-label="Start date"]', range);
    assert.strictEqual(css(startInput).textAlign, 'center');
    assert.strictEqual(css(startInput).boxShadow, 'none');
    assert.strictEqual(css(el('.euiFormControlLayoutDelimited__delimiter', range)).color, rgb(light.colors.textSubdued));

    state.isInvalid = true;
    state.compressed = true;
    await settled();
    assert.strictEqual(el('.euiFormControlLayoutDelimited', range), layout, 'no replacement');
    assert.strictEqual(box(layout).height, 32);
    assert.dom(layout).hasClass('euiFormControlLayoutDelimited--isInvalid');
    assert.strictEqual(css(el('.euiFormControlLayoutDelimited__delimiter', range)).color, rgb(light.colors.textDanger));

    const plain = el('[data-p="range-plain"]');
    assert.dom('.euiFormControlLayoutIcons', plain).doesNotExist('@iconType={{false}}');
    assert.strictEqual(css(el('.euiFormControlLayout', plain)).maxWidth, '100%');
    assert.dom(el('.euiFormControlLayout', plain)).hasClass('euiFormControlLayout-isDisabled');
    assert.strictEqual(css(el('.euiFormControlLayout', plain)).backgroundColor, rgb(forms(light)['backgroundDisabled']!));

    const readOnly = el('[data-p="range-ro"]');
    assert.dom('.euiFormControlLayoutDelimited__delimiter', readOnly).hasText('to');
    assert.dom(el('.euiFormControlLayout', readOnly)).hasClass('euiFormControlLayout-readOnly');
    assert.strictEqual(css(el('.euiFormControlLayout', readOnly)).backgroundColor, rgb(forms(light)['backgroundReadOnly']!));
  });
});
