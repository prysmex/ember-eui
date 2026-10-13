import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  focus,
  render,
  rerender,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { array, fn, hash } from '@ember/helper';

import dateMath from '@elastic/datemath';

import EuiFieldText from '#src/components/eui-field-text.gts';
import EuiFormControlLayoutDelimited from '#src/components/eui-form-control-layout-delimited.gts';
import EuiLink from '#src/components/eui-link.gts';
import EuiSuperDatePicker from '#src/components/eui-super-date-picker.gts';
import { prettyDuration } from '#src/components/eui-super-date-picker/utils/pretty-duration.ts';

import type { TOC } from '@ember/component/template-only';
import type EuiI18n from '#src/services/eui-i18n';
import type {
  ApplyTime,
  QuickSelectPanel
} from '#src/components/eui-super-date-picker.gts';

type TimeChange = {
  start: string;
  end: string;
  isQuickSelection: boolean;
  isInvalid: boolean;
};

const noop = () => {};
const subj = (name: string) => `[data-test-subj="${name}"]`;
const showDatesButton = subj('superDatePickerShowDatesButton');

function el<T extends Element = HTMLElement>(selector: string, root: ParentNode = document) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

/** The text of the visible tooltip, once it shows. */
async function tooltipText() {
  await waitUntil(() => document.querySelector('.euiToolTipPopover, [role="tooltip"]'), { timeout: 2000 });
  return el('[role="tooltip"]').textContent!.trim();
}

async function hover(selector: string) {
  await triggerEvent(el(selector).closest('.euiToolTipAnchor')!, 'mouseover');
}

/** A picker whose parent applies every change (like the docs demos). */
class Range {
  @tracked start = 'now-15m';
  @tracked end = 'now';
  changes: TimeChange[] = [];

  onTimeChange = (change: TimeChange) => {
    this.changes.push(change);
    this.start = change.start;
    this.end = change.end;
  };
}

const AllTime: TOC<{ Args: object }> = <template>
  <span data-test-subj="customDisabledDisplay">All time</span>
</template>;

/** A custom panel: applies a fixed range through `@applyTime`. */
const MyPanel: TOC<{ Args: { applyTime: ApplyTime } }> = <template>
  <EuiLink
    data-test-subj="customPanelLink"
    {{on "click" (fn @applyTime (hash start="now-30d" end="now+7d"))}}
  >Entire dataset timerange</EuiLink>
</template>;
const panels: QuickSelectPanel[] = [{ title: 'My custom panel', content: MyPanel }];

module('Integration | Component | EuiSuperDatePicker pretty duration', function (hooks) {
  setupRenderingTest(hooks);

  test('a relative range shows as one pretty duration button (upstream DOM)', async function (assert) {
    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} /></template>);

    const layout = el('.euiSuperDatePicker > .euiFormControlLayout');
    assert.dom(layout).hasClass('euiFormControlLayout--group').doesNotHaveClass('euiFormControlLayoutDelimited');
    assert.dom(subj('superDatePickerToggleQuickMenuButton'), layout).exists('quick select prepend');

    const button = el(showDatesButton);
    assert.dom(button).hasTagName('button').hasAttribute('type', 'button').hasClass('euiFormControlButton')
      .hasClass('euiSuperDatePicker__prettyFormat').doesNotHaveClass('euiSuperDatePicker__prettyFormat--disabled')
      .hasText('Last 15 minutes').isNotDisabled();
    const text = [...button.querySelectorAll('span')].at(-1)!;
    assert.strictEqual(text.textContent!.trim(), 'Last 15 minutes');
    assert.strictEqual(getComputedStyle(text).textOverflow, 'ellipsis', 'truncated');
    assert.dom(button.closest('.euiToolTipAnchor')).exists('in a block tooltip anchor');
    assert.strictEqual(getComputedStyle(button.closest('.euiToolTipAnchor')!).display, 'block');
    assert.dom('.euiDatePopoverButton').doesNotExist('no start/end buttons');
    assert.dom('.euiSuperUpdateButton').hasText('Refresh');
  });

  test('pretty duration texts: quick range labels, last/next, rounded and fallback (upstream usePrettyDuration)', function (assert) {
    const euiI18n = this.owner.lookup('service:eui-i18n') as EuiI18n;
    const pretty = (timeFrom: string, timeTo: string, quickRanges?: { start: string; end: string; label?: string }[]) =>
      prettyDuration(euiI18n, { timeFrom, timeTo, quickRanges, dateFormat: 'MMM D, YYYY' });

    assert.strictEqual(pretty('now/d', 'now/d'), 'Today', 'commonly used label');
    assert.strictEqual(pretty('now-1w/w', 'now-1w/w', [{ start: 'now-1w/w', end: 'now-1w/w', label: 'Last week' }]), 'Last week');
    assert.strictEqual(pretty('now-15m', 'now'), 'Last 15 minutes');
    assert.strictEqual(pretty('now-1h', 'now'), 'Last 1 hour');
    assert.strictEqual(pretty('now', 'now+3d'), 'Next 3 days');
    assert.strictEqual(pretty('now-2h/h', 'now'), 'Last 2 hours rounded to the hour');
    assert.strictEqual(pretty('2024-01-01T00:00:00.000Z', 'now'), `${dateMath.parse('2024-01-01T00:00:00.000Z')!.format('MMM D, YYYY')} to now`, 'fallback');
  });

  test('the pretty duration tooltip shows the full range in @dateFormat', async function (assert) {
    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @start="now-3d" @end="now" @dateFormat="MMM D, YYYY" /></template>);

    await hover(showDatesButton);
    const start = dateMath.parse('now-3d')!.format('MMM D, YYYY');
    const end = dateMath.parse('now', { roundUp: true })!.format('MMM D, YYYY');
    assert.strictEqual(await tooltipText(), `${start} – ${end}`);
  });

  test('clicking it shows the range with the start popover open; Escape returns the focus to the start button', async function (assert) {
    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} /></template>);

    await focus(showDatesButton);
    await click(showDatesButton);
    await waitUntil(() => document.querySelector('.euiDatePopoverContent'));

    assert.dom(showDatesButton).doesNotExist();
    assert.dom('.euiSuperDatePicker .euiFormControlLayoutDelimited').exists('the range');
    const start = el(subj('superDatePickerstartDatePopoverButton'));
    assert.dom(start).hasClass('euiDatePopoverButton-isSelected').hasAttribute('aria-expanded', 'true');
    assert.dom(subj('superDatePickerendDatePopoverButton')).hasAttribute('aria-expanded', 'false');

    const panel = el('.euiDatePopoverContent').closest<HTMLElement>('.euiPopover__panel')!;
    await waitUntil(() => panel.contains(document.activeElement));
    assert.true(panel.contains(document.activeElement), 'the focus moves into the start popover');

    await triggerKeyEvent(panel, 'keydown', 'Escape');
    await waitUntil(() => !document.querySelector('.euiDatePopoverContent'));
    await settled();
    assert.strictEqual(document.activeElement, start, 'the focus returns to the start button');
    assert.dom(start).hasAttribute('aria-expanded', 'false');
    assert.dom(showDatesButton).doesNotExist('the range stays until new arguments');

    // the end popover opens from its own button
    await click(subj('superDatePickerendDatePopoverButton'));
    await waitUntil(() => document.querySelector('.euiDatePopoverContent'));
    assert.dom(subj('superDatePickerendDatePopoverButton')).hasAttribute('aria-expanded', 'true');
  });

  test('quick selections show as pretty durations again; others show the range', async function (assert) {
    const range = new Range();

    await render(
      <template>
        <EuiSuperDatePicker @start={{range.start}} @end={{range.end}} @onTimeChange={{range.onTimeChange}} @customQuickSelectPanels={{panels}} />
      </template>
    );

    await click(showDatesButton);
    await waitUntil(() => document.querySelector('.euiDatePopoverContent'));
    await triggerKeyEvent(el('.euiDatePopoverContent').closest('.euiPopover__panel')!, 'keydown', 'Escape');
    await waitUntil(() => !document.querySelector('.euiDatePopoverContent'));
    assert.dom(showDatesButton).doesNotExist();

    await click(subj('superDatePickerToggleQuickMenuButton'));
    await waitUntil(() => document.querySelector('.euiQuickSelectPopover'));
    const today = [...document.querySelectorAll<HTMLElement>('.euiQuickSelectPopover .euiLink')].find((l) => l.textContent!.trim() === 'Today')!;
    await click(today);
    assert.dom(showDatesButton).hasText('Today', 'a commonly used range');

    await click(subj('superDatePickerToggleQuickMenuButton'));
    await waitUntil(() => document.querySelector(subj('customPanelLink')));
    await click(el(subj('customPanelLink')));
    assert.deepEqual(range.changes.at(-1), { start: 'now-30d', end: 'now+7d', isQuickSelection: true, isInvalid: false });
    assert.dom(showDatesButton).doesNotExist('not relative to now: the range');
    assert.dom(subj('superDatePickerstartDatePopoverButton')).exists();

    range.start = 'now-1h';
    range.end = 'now';
    await rerender();
    assert.dom(showDatesButton).hasText('Last 1 hour', 'new arguments recompute it');
  });

  test('an absolute range shows the start/end buttons', async function (assert) {
    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @start="2024-01-01T00:00:00.000Z" @end="2024-01-02T00:00:00.000Z" /></template>);

    assert.dom(showDatesButton).doesNotExist();
    assert.dom(subj('superDatePickerstartDatePopoverButton')).exists();
  });

  test('@isQuickSelectOnly with a pretty duration: only the quick select (upstream)', async function (assert) {
    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @isQuickSelectOnly={{true}} /></template>);

    assert.dom(showDatesButton).doesNotExist();
    assert.dom('.euiDatePopoverButton').doesNotExist();
    assert.dom(subj('superDatePickerToggleQuickMenuButton')).exists();
    assert.dom('.euiFormControlLayout__childrenWrapper').hasNoText();
    assert.dom('.euiSuperUpdateButton').exists();
    assert.strictEqual(getComputedStyle(el('.euiSuperDatePicker')).display, 'inline-flex', 'auto width');
  });

  // ---------------------------------------------------------------- isDisabled

  test('@isDisabled={{true}} disables the pretty duration (upstream)', async function (assert) {
    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @isDisabled={{true}} /></template>);

    assert.dom(showDatesButton).isDisabled().hasText('Last 15 minutes').hasClass('euiSuperDatePicker__prettyFormat--disabled');
    assert.dom('.euiFormControlLayout').hasClass('euiFormControlLayout-isDisabled');
    assert.dom(subj('superDatePickerToggleQuickMenuButton')).isDisabled();
    assert.dom('.euiSuperUpdateButton').isDisabled();
  });

  test('@isDisabled={ display } shows the custom display in a disabled button, for any range', async function (assert) {
    class State {
      @tracked isDisabled: boolean | { display: unknown } = { display: 'All time' };
    }
    const state = new State();

    await render(
      <template>
        {{! @glint-expect-error: display is a string or a component }}
        <EuiSuperDatePicker @onTimeChange={{noop}} @isDisabled={{state.isDisabled}} @start="2024-01-01T00:00:00.000Z" @end="2024-01-02T00:00:00.000Z" />
      </template>
    );

    assert.dom(showDatesButton).isDisabled().hasText('All time').hasClass('euiSuperDatePicker__prettyFormat--disabled');
    assert.dom('.euiDatePopoverButton').doesNotExist('the display replaces the dates');
    assert.dom(subj('superDatePickerToggleQuickMenuButton')).isDisabled();

    state.isDisabled = { display: AllTime };
    await rerender();
    assert.dom(`${showDatesButton} ${subj('customDisabledDisplay')}`).hasText('All time', 'a component display');

    state.isDisabled = false;
    await rerender();
    assert.dom(showDatesButton).doesNotExist();
    assert.dom(subj('superDatePickerstartDatePopoverButton')).isNotDisabled();
  });

  // ---------------------------------------------------------------- quickSelectButtonProps

  test('@quickSelectButtonProps are spread over the quick select button (upstream)', async function (assert) {
    const calls: string[] = [];
    const props = {
      'aria-label': 'Quick Select',
      'data-test-subj': 'myQuickSelect',
      className: 'myQuickSelectClass',
      title: 'Pick a range',
      onMouseDown: () => calls.push('mousedown'),
      onClick: (event: MouseEvent) => calls.push(`click:${(event.target as HTMLElement).tagName}`)
    };

    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @quickSelectButtonProps={{props}} /></template>);

    const button = el(subj('myQuickSelect'));
    assert.dom(subj('superDatePickerToggleQuickMenuButton')).doesNotExist('test subject replaced');
    assert.dom(button).hasAttribute('aria-label', 'Quick Select').hasAttribute('title', 'Pick a range').hasClass('myQuickSelectClass').hasClass('euiFormPrepend');

    await triggerEvent(button, 'mousedown');
    assert.deepEqual(calls, ['mousedown']);

    await click(button);
    await waitUntil(() => document.querySelector(subj('superDatePickerQuickMenu')));
    assert.strictEqual(calls.filter((c) => c.startsWith('click')).length, 1, 'onClick called');
    assert.dom(button).hasAttribute('aria-expanded', 'true', 'and the popover still toggles');
  });

  test('@quickSelectButtonProps label and icons', async function (assert) {
    const props = { label: 'Dates', iconLeft: 'clock', iconRight: undefined };

    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @quickSelectButtonProps={{props}} /></template>);

    const button = el(subj('superDatePickerToggleQuickMenuButton'));
    assert.dom(button).hasText('Dates').hasAttribute('aria-label', 'Date quick select');
    assert.strictEqual(button.querySelectorAll('.euiIcon').length, 1, 'iconRight removed');
    assert.dom('.euiIcon', button).hasAttribute('data-icon-type', 'clock');
  });

  test('@isQuickSelectOnly with an onClick that expands the picker opens the quick select (upstream)', async function (assert) {
    class State {
      @tracked isCollapsed = false;
    }
    const state = new State();
    const collapse = () => (state.isCollapsed = true);
    const expand = () => (state.isCollapsed = false);
    const props = { onClick: expand, 'data-test-subj': 'euiSuperDatePickerQuickSelectButton' };

    await render(
      <template>
        <EuiFieldText data-test-subj="euiFieldText" aria-label="Search" {{on "focus" collapse}} />
        <EuiSuperDatePicker
          @start="2025-01-01T00:00:00.000Z"
          @end="now"
          @onTimeChange={{noop}}
          @isQuickSelectOnly={{state.isCollapsed}}
          @quickSelectButtonProps={{props}}
        />
      </template>
    );

    assert.dom(subj('superDatePickerstartDatePopoverButton')).exists();
    await focus(subj('euiFieldText'));
    assert.dom(subj('superDatePickerstartDatePopoverButton')).doesNotExist();

    await click(subj('euiSuperDatePickerQuickSelectButton'));
    await waitUntil(() => document.querySelector(subj('superDatePickerQuickMenu')));
    assert.dom(subj('superDatePickerQuickMenu'), document.body).exists('the quick select stays open while the picker expands');
    assert.dom(subj('superDatePickerstartDatePopoverButton')).exists('expanded');
    const panel = el(subj('superDatePickerQuickMenu')).closest('.euiPopover__panel')!;
    await waitUntil(() => panel.contains(document.activeElement));
    assert.true(panel.contains(document.activeElement), 'the focus moves into the quick select');
  });

  // ---------------------------------------------------------------- auto refresh append

  test('while refreshing, the auto refresh button is appended to the field (upstream)', async function (assert) {
    class State {
      @tracked isPaused = false;
    }
    const state = new State();
    const onRefresh = () => {};

    await render(
      <template><EuiSuperDatePicker @onTimeChange={{noop}} @onRefresh={{onRefresh}} @isPaused={{state.isPaused}} @refreshInterval={{60000}} /></template>
    );

    const append = el('.euiSuperDatePicker .euiFormControlLayout__append');
    assert.dom('.euiAutoRefreshButton', append).hasText('1 m', 'short hand');
    const quick = el(subj('superDatePickerToggleQuickMenuButton'));

    state.isPaused = true;
    await rerender();
    assert.dom('.euiAutoRefreshButton').doesNotExist('not while paused');
    assert.dom('.euiFormControlLayout__append').doesNotExist();
    assert.strictEqual(el(subj('superDatePickerToggleQuickMenuButton')), quick, 'the quick select is not remounted');

    state.isPaused = false;
    await rerender();
    assert.dom('.euiFormControlLayout__append .euiAutoRefreshButton').exists();
    assert.strictEqual(el(subj('superDatePickerToggleQuickMenuButton')), quick);
  });

  test('the appended button edits the interval (upstream "refreshInterval and refreshIntervalUnits")', async function (assert) {
    const changes: unknown[] = [];
    const onRefreshChange = (change: unknown) => changes.push(change);

    await render(
      <template>
        <EuiSuperDatePicker
          @onTimeChange={{noop}}
          @onRefreshChange={{onRefreshChange}}
          @refreshInterval={{3600000}}
          @refreshIntervalUnits="m"
          @isPaused={{false}}
          @start="2024-01-01T00:00:00.000Z"
          @end="2024-01-02T00:00:00.000Z"
        />
      </template>
    );

    assert.dom('.euiFormControlLayoutDelimited .euiFormControlLayout__append .euiAutoRefreshButton').hasText('60 m', 'in the range too');
    await click('.euiAutoRefreshButton');
    await waitUntil(() => document.querySelector(subj('superDatePickerRefreshIntervalInput')));
    assert.dom(subj('superDatePickerRefreshIntervalInput'), document.body).hasValue('60');
    assert.dom(subj('superDatePickerRefreshIntervalUnitsSelect'), document.body).hasValue('m');

    await fillIn(el(subj('superDatePickerRefreshIntervalInput')), '5');
    await waitUntil(() => changes.length > 0, { timeout: 2000 });
    assert.deepEqual(changes.at(-1), { refreshInterval: 300000, isPaused: false, intervalUnits: 'm' });
  });

  test('the append keeps an open quick select popover open when refreshing starts', async function (assert) {
    class State {
      @tracked isPaused = true;
    }
    const state = new State();

    await render(
      <template>
        <EuiSuperDatePicker @onTimeChange={{noop}} @isPaused={{state.isPaused}} @start="2024-01-01T00:00:00.000Z" @end="2024-01-02T00:00:00.000Z" />
      </template>
    );

    await click(subj('superDatePickerToggleQuickMenuButton'));
    await waitUntil(() => document.querySelector(subj('superDatePickerQuickMenu')));
    state.isPaused = false;
    await rerender();
    assert.dom(subj('superDatePickerQuickMenu'), document.body).exists('still open');
    assert.dom('.euiAutoRefreshButton').exists();
  });

  // ---------------------------------------------------------------- needs updating icon

  test('a pending update shows the checkCircle icon on the right (upstream)', async function (assert) {
    await render(
      <template><EuiSuperDatePicker @onTimeChange={{noop}} @start="2024-01-01T00:00:00.000Z" @end="2024-01-02T00:00:00.000Z" /></template>
    );

    assert.dom('.euiFormControlLayoutIcons').doesNotExist('no icon at rest');

    await click(subj('superDatePickerstartDatePopoverButton'));
    await waitUntil(() => document.querySelector(subj('superDatePickerAbsoluteDateInput')));
    await fillIn(el(subj('superDatePickerAbsoluteDateInput')), 'Jan 1, 2024 @ 06:00:00.000');
    await triggerKeyEvent(el(subj('superDatePickerAbsoluteDateInput')), 'keydown', 'Enter');

    await waitUntil(() => document.querySelector('.euiFormControlLayoutIcons'));
    const icons = el('.euiFormControlLayoutIcons');
    assert.dom('[data-icon-type="checkCircle"]', icons).exists();
    const end = el(subj('superDatePickerendDatePopoverButton'));
    assert.true(icons.getBoundingClientRect().left >= end.getBoundingClientRect().right - 1, 'after the end date');

    // not while invalid
    await fillIn(el(subj('superDatePickerAbsoluteDateInput')), 'Jan 3, 2024 @ 06:00:00.000');
    await triggerKeyEvent(el(subj('superDatePickerAbsoluteDateInput')), 'keydown', 'Enter');
    assert.dom('[data-icon-type="checkCircle"]').doesNotExist();
  });

  // ---------------------------------------------------------------- update button

  test('the update button tooltip: "Cannot update" while disabled, "Click to apply" after a change', async function (assert) {
    await render(
      <template>
        <div data-p="invalid"><EuiSuperDatePicker @onTimeChange={{noop}} @start="2024-01-02T00:00:00.000Z" @end="2024-01-01T00:00:00.000Z" /></div>
      </template>
    );

    assert.dom('.euiSuperUpdateButton').isDisabled();
    assert.dom(el('.euiSuperUpdateButton').parentElement!.closest('.euiToolTipAnchor')).exists('wrapped in a tooltip');
    await hover('.euiSuperUpdateButton');
    assert.strictEqual(await tooltipText(), 'Cannot update');
  });

  test('the "Click to apply" tooltip shows for 2 seconds once the date popover closes (upstream showTooltip)', async function (assert) {
    await render(
      <template><EuiSuperDatePicker @onTimeChange={{noop}} @start="2024-01-01T00:00:00.000Z" @end="2024-01-02T00:00:00.000Z" /></template>
    );

    await click(subj('superDatePickerstartDatePopoverButton'));
    await waitUntil(() => document.querySelector(subj('superDatePickerAbsoluteDateInput')));
    await fillIn(el(subj('superDatePickerAbsoluteDateInput')), 'Jan 1, 2024 @ 06:00:00.000');
    await triggerKeyEvent(el(subj('superDatePickerAbsoluteDateInput')), 'keydown', 'Enter');
    assert.dom('[role="tooltip"]', document.body).doesNotExist('not while the popover is open');

    await triggerKeyEvent(el('.euiDatePopoverContent').closest('.euiPopover__panel')!, 'keydown', 'Escape');
    assert.strictEqual(await tooltipText(), 'Click to apply');
    assert.dom('.euiSuperUpdateButton').hasText('Update');

    await waitUntil(() => !document.querySelector('[role="tooltip"]'), { timeout: 3500 });
    assert.dom('[role="tooltip"]', document.body).doesNotExist('hidden after 2 seconds');
  });

  test('@updateButtonProps: showTooltip, toolTipProps and responsive', async function (assert) {
    const all = ['xs', 's', 'm', 'l', 'xl'];
    const props = { responsive: all, toolTipProps: { content: 'Custom tip', position: 'top' as const } };

    await render(
      <template>
        <div data-p="responsive">
          {{! @glint-expect-error: breakpoint names }}
          <EuiSuperDatePicker @onTimeChange={{noop}} @updateButtonProps={{props}} />
        </div>
        <div data-p="default"><EuiSuperDatePicker @onTimeChange={{noop}} /></div>
        <div data-p="never"><EuiSuperDatePicker @onTimeChange={{noop}} @showUpdateButton="iconOnly" @updateButtonProps={{hash responsive=false}} /></div>
        <div data-p="sizes">
          <EuiSuperDatePicker @onTimeChange={{noop}} @updateButtonProps={{hash responsive=(array "xs")}} />
        </div>
      </template>
    );

    // collapsed on the current size: the label is for screen readers only
    const collapsed = el('[data-p="responsive"] .euiSuperUpdateButton');
    assert.dom('.euiScreenReaderOnly', collapsed).hasText('Refresh');
    assert.strictEqual(getComputedStyle(collapsed).minInlineSize, '0px', 'no 118px minimum');

    // the 1440px test window is "xl": the default ['xs', 's'] keeps the label
    const full = el('[data-p="default"] .euiSuperUpdateButton');
    assert.dom('.euiScreenReaderOnly', full).doesNotExist();
    assert.strictEqual(full.style.minInlineSize, '118px', 'inline min width (upstream)');
    assert.dom('[data-p="sizes"] .euiSuperUpdateButton .euiScreenReaderOnly').doesNotExist();

    // iconOnly forces the collapse even with responsive={false}
    assert.dom('[data-p="never"] .euiSuperUpdateButton .euiScreenReaderOnly').hasText('Refresh');

    await hover('[data-p="responsive"] .euiSuperUpdateButton');
    assert.strictEqual(await tooltipText(), 'Custom tip');
  });

  test('@updateButtonProps.showTooltip={{false}} keeps the "Click to apply" tooltip hidden', async function (assert) {
    const props = { showTooltip: false };
    await render(
      <template><EuiSuperDatePicker @onTimeChange={{noop}} @updateButtonProps={{props}} @start="2024-01-01T00:00:00.000Z" @end="2024-01-02T00:00:00.000Z" /></template>
    );

    await click(subj('superDatePickerstartDatePopoverButton'));
    await waitUntil(() => document.querySelector(subj('superDatePickerAbsoluteDateInput')));
    await fillIn(el(subj('superDatePickerAbsoluteDateInput')), 'Jan 1, 2024 @ 06:00:00.000');
    await triggerKeyEvent(el(subj('superDatePickerAbsoluteDateInput')), 'keydown', 'Enter');
    await triggerKeyEvent(el('.euiDatePopoverContent').closest('.euiPopover__panel')!, 'keydown', 'Escape');
    await waitUntil(() => !document.querySelector('.euiDatePopoverContent'));
    await settled();
    assert.dom('.euiSuperUpdateButton').hasText('Update');
    assert.dom('[role="tooltip"]', document.body).doesNotExist();
  });

  // ---------------------------------------------------------------- isQuickSelectOnly × isAutoRefreshOnly

  test('@isQuickSelectOnly and @isAutoRefreshOnly (upstream render())', async function (assert) {
    const onRefreshChange = () => {};
    await render(
      <template>
        <div data-p="both"><EuiSuperDatePicker @onTimeChange={{noop}} @onRefreshChange={{onRefreshChange}} @isQuickSelectOnly={{true}} @isAutoRefreshOnly={{true}} /></div>
        <div data-p="both-no-change"><EuiSuperDatePicker @onTimeChange={{noop}} @isQuickSelectOnly={{true}} @isAutoRefreshOnly={{true}} @showTimeWindowButtons={{true}} /></div>
        <div data-p="auto-only"><EuiSuperDatePicker @onTimeChange={{noop}} @onRefreshChange={{onRefreshChange}} @isAutoRefreshOnly={{true}} /></div>
      </template>
    );

    // with @onRefreshChange auto refresh wins: EuiAutoRefresh alone, in auto width
    const both = el('[data-p="both"] .euiSuperDatePicker');
    assert.dom('.euiAutoRefresh', both).exists();
    assert.dom(subj('superDatePickerToggleQuickMenuButton'), both).doesNotExist();
    assert.dom('.euiSuperUpdateButton', both).doesNotExist();
    assert.strictEqual(getComputedStyle(both).display, 'inline-flex', 'quick select only forces auto width');
    assert.strictEqual(getComputedStyle(el('[data-p="auto-only"] .euiSuperDatePicker')).display, 'block', 'restricted auto refresh only');

    // without it: the quick select only, no time window buttons
    const noChange = el('[data-p="both-no-change"] .euiSuperDatePicker');
    assert.dom(subj('superDatePickerToggleQuickMenuButton'), noChange).exists();
    assert.dom('.euiAutoRefresh', noChange).doesNotExist();
    assert.dom(showDatesButton, noChange).doesNotExist();
    assert.dom(subj('timeWindowButtons'), noChange).doesNotExist();
    assert.dom('.euiSuperUpdateButton', noChange).exists();
  });
});

module('Integration | Component | EuiFormControlLayoutDelimited side switches', function (hooks) {
  setupRenderingTest(hooks);

  test('@iconSide, @isPrependProvided and @isAppendProvided', async function (assert) {
    class State {
      @tracked isAppendProvided = true;
      @tracked isPrependProvided = false;
    }
    const state = new State();

    await render(
      <template>
        <EuiFormControlLayoutDelimited
          @icon="checkCircle"
          @iconSide="right"
          @isAppendProvided={{state.isAppendProvided}}
          @isPrependProvided={{state.isPrependProvided}}
        >
          <:prepend as |classes|><span class={{classes}} data-test-subj="pre">Pre</span></:prepend>
          <:startControl as |classes|><input class={{classes}} aria-label="Start" data-test-subj="start" /></:startControl>
          <:endControl as |classes|><input class={{classes}} aria-label="End" data-test-subj="end" /></:endControl>
          <:append as |classes|><span class={{classes}} data-test-subj="app">App</span></:append>
        </EuiFormControlLayoutDelimited>
      </template>
    );

    const icons = el('.euiFormControlLayoutIcons');
    assert.dom('[data-icon-type="checkCircle"]', icons).exists();
    assert.true(icons.getBoundingClientRect().left >= el(subj('end')).getBoundingClientRect().right - 1, 'icon after the end control');
    assert.dom(subj('pre')).doesNotExist('prepend switched off');
    assert.dom('.euiFormControlLayout__prepend').doesNotExist();
    assert.dom(subj('app')).exists();
    const startInput = el(subj('start'));

    state.isAppendProvided = false;
    state.isPrependProvided = true;
    await rerender();
    assert.dom(subj('app')).doesNotExist();
    assert.dom('.euiFormControlLayout__append').doesNotExist();
    assert.dom(subj('pre')).exists();
    assert.strictEqual(el(subj('start')), startInput, 'controls kept');
  });
});
