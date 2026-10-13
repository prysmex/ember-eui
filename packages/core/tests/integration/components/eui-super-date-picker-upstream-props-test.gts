import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  focus,
  render,
  rerender,
  select,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { fn, hash } from '@ember/helper';

import moment from 'moment';

import EuiDatePickerRange from '#src/components/eui-date-picker-range.gts';
import EuiFieldText from '#src/components/eui-field-text.gts';
import EuiLink from '#src/components/eui-link.gts';
import EuiSuperDatePicker from '#src/components/eui-super-date-picker.gts';
import EuiTimeWindowButtons from '#src/components/eui-super-date-picker/eui-time-window-buttons.gts';
import {
  ZOOM_DELTA_FALLBACK_MS,
  ZOOM_FACTOR_DEFAULT,
  useEuiTimeWindow
} from '#src/components/eui-super-date-picker/utils/time-window.ts';
import { euiButtonColor, euiButtonFillColor } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { TOC } from '@ember/component/template-only';
import type EuiI18n from '#src/services/eui-i18n';
import type {
  ApplyTime,
  QuickSelectPanel
} from '#src/components/eui-super-date-picker.gts';

const lightContext = resolveBorealisTheme('light');

type TimeChange = {
  start: string;
  end: string;
  isQuickSelection: boolean;
  isInvalid: boolean;
};

const noop = () => {};

function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function el<T extends Element = HTMLElement>(selector: string, root: ParentNode = document) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const subj = (name: string) => `[data-test-subj="${name}"]`;

async function openQuickSelect() {
  await click(subj('superDatePickerToggleQuickMenuButton'));
  await waitUntil(() => document.querySelector(subj('superDatePickerQuickMenu')));
}

async function openStart() {
  await click('.euiDatePopoverButton--start');
  await waitUntil(() => document.querySelector('.euiDatePopoverContent'));
}

async function chooseTab(name: string) {
  const tab = [...document.querySelectorAll<HTMLElement>('.euiDatePopoverContent .euiTab')].find(
    (t) => t.textContent!.trim() === name
  )!;
  await click(tab);
}

async function hover(selector: string, text: string) {
  const anchor = el(selector).closest('.euiToolTipAnchor')!;
  await triggerEvent(anchor, 'mouseover');
  await waitUntil(() => document.body.textContent!.includes(text), { timeout: 2000 });
}

/** A custom panel: applies a fixed range through `@applyTime`. */
const MyPanel: TOC<{ Args: { applyTime: ApplyTime } }> = <template>
  <EuiLink
    data-test-subj="customComponentSelectPanel"
    {{on "click" (fn @applyTime (hash start="now-30d" end="now+7d"))}}
  >Entire dataset timerange</EuiLink>
</template>;

const panels: QuickSelectPanel[] = [{ title: 'My custom panel', content: MyPanel }];

module('Integration | Component | EuiSuperDatePicker upstream props', function (hooks) {
  setupRenderingTest(hooks);

  // ---------------------------------------------------------------- update button

  test('@updateButtonProps: fill, color, label, test subject and min width win', async function (assert) {
    const props = { fill: false, color: 'danger' as const, children: 'Apply', 'data-test-subj': 'myApply', minWidth: false as const };

    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @updateButtonProps={{props}} /></template>);

    const button = el('.euiSuperUpdateButton');
    const base = euiButtonColor(lightContext, 'danger') as { color: string; backgroundColor: string };
    const filled = euiButtonFillColor(lightContext, 'danger') as { color: string; backgroundColor: string };
    const style = getComputedStyle(button);

    assert.dom(button).hasText('Apply').hasAttribute('data-test-subj', 'myApply');
    assert.strictEqual(style.color, rgb(base.color), 'danger base text color');
    assert.notStrictEqual(style.backgroundColor, rgb(filled.backgroundColor), 'not filled');
    assert.notStrictEqual(style.minInlineSize, '118px', 'min width removed');
  });

  test('@updateButtonProps: iconOnly and size override the picker', async function (assert) {
    const props = { iconOnly: true, size: 's' as const };

    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @updateButtonProps={{props}} /></template>);

    assert.dom('.euiSuperUpdateButton').hasAttribute('aria-label', 'Refresh').hasNoText();
    assert.strictEqual(el('.euiSuperUpdateButton').getBoundingClientRect().height > 0, true);
  });

  // ---------------------------------------------------------------- quick select panels

  test('@customQuickSelectPanels: rendered last with @applyTime, which applies a quick selection', async function (assert) {
    const changes: TimeChange[] = [];
    const onTimeChange = (change: TimeChange) => changes.push(change);
    const recent = [{ start: 'now-1h', end: 'now' }];

    await render(
      <template>
        <EuiSuperDatePicker
          @onTimeChange={{onTimeChange}}
          @onRefreshChange={{noop}}
          @recentlyUsedRanges={{recent}}
          @customQuickSelectPanels={{panels}}
        />
      </template>
    );
    await openQuickSelect();

    const menu = el(subj('superDatePickerQuickMenu'));
    // upstream: 5 sections in the default order
    assert.strictEqual(menu.childElementCount, 5);
    assert.true(menu.children[0]!.textContent!.includes('Quick select'));
    assert.true(menu.children[1]!.textContent!.includes('Commonly used'));
    assert.true(menu.children[2]!.textContent!.includes('Recently used'));
    assert.true(menu.children[3]!.textContent!.includes('Refresh every'));
    assert.true(menu.children[4]!.textContent!.includes('My custom panel'));
    assert.dom(menu.children[4]).hasClass('euiQuickSelectPanel');

    await click(el(subj('customComponentSelectPanel')));

    assert.deepEqual(changes, [{ start: 'now-30d', end: 'now+7d', isQuickSelection: true, isInvalid: false }]);
    await waitUntil(() => !document.querySelector(subj('superDatePickerQuickMenu')));
    assert.dom(subj('superDatePickerQuickMenu'), document.body).doesNotExist('the popover closes');
  });

  test('<:customQuickSelectRender>: re-orders, omits and adds content', async function (assert) {
    const recent = [{ start: 'now-1h', end: 'now' }];

    await render(
      <template>
        <EuiSuperDatePicker
          @onTimeChange={{noop}}
          @onRefreshChange={{noop}}
          @recentlyUsedRanges={{recent}}
          @customQuickSelectPanels={{panels}}
        >
          <:customQuickSelectRender as |p|>
            <p.customQuickSelectPanels />
            <p.refreshInterval />
            <p.quickSelect />
            <p.commonlyUsedRanges />
            <p.recentlyUsedRanges />
          </:customQuickSelectRender>
        </EuiSuperDatePicker>
      </template>
    );
    await openQuickSelect();

    const menu = el(subj('superDatePickerQuickMenu'));
    assert.strictEqual(menu.childElementCount, 5);
    assert.true(menu.children[0]!.textContent!.includes('My custom panel'));
    assert.true(menu.children[1]!.textContent!.includes('Refresh every'));
    assert.true(menu.children[2]!.textContent!.includes('Quick select'));
    assert.true(menu.children[3]!.textContent!.includes('Commonly used'));
    assert.true(menu.children[4]!.textContent!.includes('Recently used'));
  });

  test('<:customQuickSelectRender>: panels without data render nothing; custom content shows', async function (assert) {
    await render(
      <template>
        <EuiSuperDatePicker @onTimeChange={{noop}}>
          <:customQuickSelectRender as |p|>
            <span data-test-subj="hello">Hello world!</span>
            <p.refreshInterval />
            <p.customQuickSelectPanels />
            <p.quickSelect />
          </:customQuickSelectRender>
        </EuiSuperDatePicker>
      </template>
    );
    await openQuickSelect();

    const menu = el(subj('superDatePickerQuickMenu'));
    assert.strictEqual(menu.childElementCount, 2, 'custom content and quick select only');
    assert.dom(menu.children[0]).hasText('Hello world!');
    assert.true(menu.children[1]!.textContent!.includes('Quick select'));
    assert.dom('.euiRefreshInterval', document.body).doesNotExist('no @onRefreshChange: no refresh interval');
  });

  // ---------------------------------------------------------------- refresh interval

  test('@refreshIntervalUnits keeps the unit and adds intervalUnits to @onRefreshChange', async function (assert) {
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
        />
      </template>
    );
    await openQuickSelect();

    assert.dom(subj('superDatePickerRefreshIntervalInput'), document.body).hasValue('60');
    assert.dom(subj('superDatePickerRefreshIntervalUnitsSelect'), document.body).hasValue('m');

    await select(el(subj('superDatePickerRefreshIntervalUnitsSelect')), 'h');
    assert.deepEqual(changes.at(-1), { refreshInterval: 216000000, isPaused: false, intervalUnits: 'h' });
  });

  test('@refreshIntervalUnits={{undefined}} rounds units but still reports them (upstream onRefreshChange)', async function (assert) {
    const changes: unknown[] = [];
    const onRefreshChange = (change: unknown) => changes.push(change);
    const units = undefined;

    await render(
      <template>
        <EuiSuperDatePicker
          @onTimeChange={{noop}}
          @onRefreshChange={{onRefreshChange}}
          @refreshIntervalUnits={{units}}
          @isPaused={{false}}
        />
      </template>
    );
    await openQuickSelect();

    await select(el(subj('superDatePickerRefreshIntervalUnitsSelect')), 'h');
    assert.deepEqual(changes.at(-1), { refreshInterval: 3600000, isPaused: false, intervalUnits: 'h' });
  });

  test('@refreshMinInterval sets the smallest interval', async function (assert) {
    await render(
      <template>
        <EuiSuperDatePicker
          @onTimeChange={{noop}}
          @onRefreshChange={{noop}}
          @refreshInterval={{120000}}
          @refreshMinInterval={{60000}}
        />
      </template>
    );
    await openQuickSelect();

    assert.dom(subj('superDatePickerRefreshIntervalInput'), document.body).hasAttribute('min', '1');
  });

  test('@isAutoRefreshOnly with @onRefreshChange renders EuiAutoRefresh (upstream)', async function (assert) {
    const changes: unknown[] = [];
    const onRefreshChange = (change: unknown) => changes.push(change);

    await render(
      <template>
        <EuiSuperDatePicker
          @onTimeChange={{noop}}
          @onRefreshChange={{onRefreshChange}}
          @isAutoRefreshOnly={{true}}
          @isPaused={{false}}
          @refreshInterval={{5000}}
        />
      </template>
    );

    assert.dom('.euiDatePopoverButton').doesNotExist();
    assert.dom('.euiSuperUpdateButton').doesNotExist();
    assert.dom('.euiSuperDatePicker .euiAutoRefresh input, .euiSuperDatePicker input[readonly]').hasValue('5 seconds');
  });

  test('@isAutoRefreshOnly without @onRefreshChange keeps the range (as before)', async function (assert) {
    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @isAutoRefreshOnly={{true}} /></template>);

    assert.dom('.euiDatePopoverButton--start').exists();
  });

  // ---------------------------------------------------------------- time window buttons

  test('@showTimeWindowButtons renders the buttons only when passed', async function (assert) {
    class State {
      @tracked show = true;
    }
    const state = new State();
    const start = '2025-10-30T12:00:00.000Z';
    const end = '2025-10-30T13:00:00.000Z';

    await render(
      <template><EuiSuperDatePicker @start={{start}} @end={{end}} @onTimeChange={{noop}} @showTimeWindowButtons={{state.show}} /></template>
    );

    assert.dom(subj('timeWindowButtons')).exists().hasClass('euiSuperDatePicker__timeWindowButtons');
    assert.dom(subj('timeWindowButtonsPrevious')).hasAttribute('aria-label', 'Previous');
    assert.dom(subj('timeWindowButtonsZoomOut')).hasAttribute('aria-label', 'Zoom out');
    assert.dom(subj('timeWindowButtonsNext')).hasAttribute('aria-label', 'Next');
    assert.dom(subj('timeWindowButtonsZoomIn')).doesNotExist('zoom in is off by default');
    assert.dom(subj('timeWindowButtons')).hasAttribute('aria-label', 'Time window controls');
    // between the range and the update button
    const root = el('.euiSuperDatePicker');
    assert.strictEqual(root.children[1], el(subj('timeWindowButtons')));

    state.show = false;
    await rerender();
    assert.dom(subj('timeWindowButtons')).doesNotExist();
  });

  test('time window buttons shift the window (upstream "updates time when shifting")', async function (assert) {
    const changes: TimeChange[] = [];
    const onTimeChange = (change: TimeChange) => changes.push(change);
    const start = '2025-10-30T12:00:00.000Z';
    const end = '2025-10-30T13:00:00.000Z';

    await render(
      <template>
        <EuiSuperDatePicker
          @start={{start}}
          @end={{end}}
          @onTimeChange={{onTimeChange}}
          @showUpdateButton={{false}}
          @showTimeWindowButtons={{true}}
        />
      </template>
    );

    await click(subj('timeWindowButtonsPrevious'));
    assert.deepEqual(
      { start: changes[0]!.start, end: changes[0]!.end, isQuickSelection: changes[0]!.isQuickSelection },
      { start: '2025-10-30T11:00:00.000Z', end: '2025-10-30T12:00:00.000Z', isQuickSelection: true }
    );

    await click(subj('timeWindowButtonsNext'));
    assert.deepEqual(
      { start: changes[1]!.start, end: changes[1]!.end },
      { start: '2025-10-30T13:00:00.000Z', end: '2025-10-30T14:00:00.000Z' },
      'shifts from the applied range'
    );
  });

  test('time window buttons zoom out by the zoom factor', async function (assert) {
    const changes: TimeChange[] = [];
    const onTimeChange = (change: TimeChange) => changes.push(change);
    const start = '2025-10-30T12:00:00.000Z';
    const end = '2025-10-31T12:00:00.000Z';

    await render(
      <template>
        <EuiSuperDatePicker @start={{start}} @end={{end}} @onTimeChange={{onTimeChange}} @showTimeWindowButtons={{true}} />
      </template>
    );

    await click(subj('timeWindowButtonsZoomOut'));

    const initial = new Date(end).getTime() - new Date(start).getTime();
    const updated = new Date(changes[0]!.end).getTime() - new Date(changes[0]!.start).getTime();
    assert.true(new Date(changes[0]!.start).getTime() < new Date(start).getTime());
    assert.strictEqual(updated, initial * (1 + ZOOM_FACTOR_DEFAULT));
  });

  test('time window buttons are disabled while the range is invalid or the picker disabled', async function (assert) {
    class State {
      @tracked start = '2025-10-31T14:00:00.000Z';
      @tracked end = '2025-10-30T14:00:00.000Z';
      @tracked disabled = false;
    }
    const state = new State();

    await render(
      <template>
        <EuiSuperDatePicker
          @start={{state.start}}
          @end={{state.end}}
          @isDisabled={{state.disabled}}
          @onTimeChange={{noop}}
          @showTimeWindowButtons={{true}}
        />
      </template>
    );

    assert.dom(subj('timeWindowButtonsPrevious')).isDisabled();
    assert.dom(subj('timeWindowButtonsZoomOut')).isDisabled();
    assert.dom(subj('timeWindowButtonsNext')).isDisabled();

    state.start = '2025-10-30T14:00:00.000Z';
    state.end = '2025-10-31T14:00:00.000Z';
    await rerender();
    assert.dom(subj('timeWindowButtonsPrevious')).isNotDisabled();
    assert.dom(subj('timeWindowButtonsZoomOut')).isNotDisabled();
    assert.dom(subj('timeWindowButtonsNext')).isNotDisabled();

    state.disabled = true;
    await rerender();
    assert.dom(subj('timeWindowButtonsZoomOut')).isDisabled();
  });

  test('@showTimeWindowButtons config: zoom in, no arrows, zoom factor, compressed; hidden with @isAutoRefreshOnly', async function (assert) {
    const changes: TimeChange[] = [];
    const onTimeChange = (change: TimeChange) => changes.push(change);
    const config = { showZoomIn: true, showShiftArrows: false, zoomFactor: '25%' };
    const start = '2026-01-21T10:00:00.000Z';
    const end = '2026-01-21T11:00:00.000Z';

    await render(
      <template>
        <div data-p="a">
          <EuiSuperDatePicker @start={{start}} @end={{end}} @onTimeChange={{onTimeChange}} @showTimeWindowButtons={{config}} @compressed={{true}} />
        </div>
        <div data-p="c">
          <EuiSuperDatePicker @start={{start}} @end={{end}} @onTimeChange={{noop}} @showTimeWindowButtons={{config}} />
        </div>
        <div data-p="b">
          <EuiSuperDatePicker @onTimeChange={{noop}} @onRefreshChange={{noop}} @showTimeWindowButtons={{true}} @isAutoRefreshOnly={{true}} />
        </div>
      </template>
    );

    assert.dom(`[data-p="a"] ${subj('timeWindowButtonsPrevious')}`).doesNotExist();
    assert.dom(`[data-p="a"] ${subj('timeWindowButtonsNext')}`).doesNotExist();
    assert.dom(`[data-p="a"] ${subj('timeWindowButtonsZoomIn')}`).exists();
    assert.true(
      el(`[data-p="a"] ${subj('timeWindowButtons')}`).getBoundingClientRect().height <
        el(`[data-p="c"] ${subj('timeWindowButtons')}`).getBoundingClientRect().height,
      'compressed: small (s) buttons'
    );

    await click(`[data-p="a"] ${subj('timeWindowButtonsZoomIn')}`);
    assert.deepEqual(
      { start: changes[0]!.start, end: changes[0]!.end },
      { start: '2026-01-21T10:07:30.000Z', end: '2026-01-21T10:52:30.000Z' },
      '25% zoom in'
    );

    assert.dom(`[data-p="b"] ${subj('timeWindowButtons')}`).doesNotExist();
  });

  test('EuiTimeWindowButtons: hidden without buttons, invalid times and zero windows (upstream)', async function (assert) {
    const applied: unknown[] = [];
    const apply = (range: unknown) => applied.push(range);
    const same = '2026-01-19T11:11:11.000Z';

    await render(
      <template>
        <div data-p="none">
          <EuiTimeWindowButtons @start="now-15m" @end="now" @applyTime={{apply}} @showShiftArrows={{false}} @showZoomOut={{false}} @showZoomIn={{false}} />
        </div>
        <div data-p="invalid">
          <EuiTimeWindowButtons @start="not a date" @end="now" @applyTime={{apply}} />
        </div>
        <div data-p="zero">
          <EuiTimeWindowButtons @start={{same}} @end={{same}} @showZoomIn={{true}} @applyTime={{apply}} />
        </div>
      </template>
    );

    assert.dom(`[data-p="none"] ${subj('timeWindowButtons')}`).doesNotExist();

    await click(`[data-p="invalid"] ${subj('timeWindowButtonsPrevious')}`);
    await click(`[data-p="invalid"] ${subj('timeWindowButtonsZoomOut')}`);
    await click(`[data-p="invalid"] ${subj('timeWindowButtonsNext')}`);
    assert.deepEqual(applied, [], 'invalid times apply nothing');
    await hover(`[data-p="invalid"] ${subj('timeWindowButtonsZoomOut')}`, 'Cannot zoom out invalid time window');
    assert.true(document.body.textContent!.includes('Cannot zoom out invalid time window'));

    assert.dom(`[data-p="zero"] ${subj('timeWindowButtonsPrevious')}`).isDisabled();
    assert.dom(`[data-p="zero"] ${subj('timeWindowButtonsZoomOut')}`).isNotDisabled();
    assert.dom(`[data-p="zero"] ${subj('timeWindowButtonsZoomIn')}`).isDisabled();
    assert.dom(`[data-p="zero"] ${subj('timeWindowButtonsNext')}`).isDisabled();
    await hover(`[data-p="zero"] ${subj('timeWindowButtonsZoomIn')}`, 'Cannot zoom in any further');
    assert.true(document.body.textContent!.includes('Cannot zoom in any further'));
  });

  test('EuiTimeWindowButtons: previous/next tooltips describe the window', async function (assert) {
    await render(<template><EuiTimeWindowButtons @start="now-15m" @end="now" @applyTime={{noop}} /></template>);

    await hover(subj('timeWindowButtonsPrevious'), 'Previous 15 minutes');
    assert.true(document.body.textContent!.includes('Previous 15 minutes'));
  });

  test('useEuiTimeWindow: displayInterval (upstream)', function (assert) {
    const i18n = this.owner.lookup('service:eui-i18n') as EuiI18n;
    const interval = (start: string, end: string) => useEuiTimeWindow(i18n, start, end, noop);

    assert.strictEqual(interval('now-15m', 'now').displayInterval, '15 minutes', 'relative');
    assert.strictEqual(interval('2025-10-29T16:00:00.000Z', '2025-10-29T16:15:00.000Z').displayInterval, '15 minutes', 'absolute');
    // @ts-expect-error: an undefined start, as upstream tests
    assert.true(interval(undefined, '2025-10-29T16:15:00.000Z').isInvalid, 'undefined start');
    const invalid = interval('2025-10-29T16:00:00.000Z', 'not a date');
    assert.strictEqual(invalid.displayInterval, '');
    assert.true(invalid.isInvalid);
    assert.strictEqual(interval('now/d', 'now/d').displayInterval, '1 day', 'inclusive boundary: no tilde');
    assert.strictEqual(interval('2025-10-27T16:00:01.000Z', '2025-10-29T16:12:00.000Z').displayInterval, '~2 days', 'approximate');
    assert.strictEqual(interval('2026-01-19T11:11:11.000Z', '2026-01-19T11:11:11.000Z').displayInterval, 'Off', 'zero window');
  });

  test('useEuiTimeWindow: steps, inclusive boundaries and zero windows (upstream)', function (assert) {
    const i18n = this.owner.lookup('service:eui-i18n') as EuiI18n;
    const calls: { start: string; end: string }[] = [];
    const apply = (range: { start: string; end: string }) => calls.push({ start: range.start, end: range.end });
    const window = (start: string, end: string, zoomFactor?: number) => useEuiTimeWindow(i18n, start, end, apply, { zoomFactor });

    window('2025-10-30T10:00:00.000Z', '2025-10-30T11:00:00.000Z').stepForward();
    assert.deepEqual(calls.pop(), { start: '2025-10-30T11:00:00.000Z', end: '2025-10-30T12:00:00.000Z' });

    window('2025-10-30T00:00:00.000Z', '2025-10-30T23:59:59.999Z').stepForward();
    const next = calls.pop()!;
    assert.deepEqual(next, { start: '2025-10-31T00:00:00.000Z', end: '2025-10-31T23:59:59.999Z' });
    window(next.start, next.end).stepForward();
    assert.deepEqual(calls.pop(), { start: '2025-11-01T00:00:00.000Z', end: '2025-11-01T23:59:59.999Z' }, 'no 1ms drift');

    window('2025-10-30T10:00:00.000Z', '2025-10-30T11:00:00.000Z').stepBackward();
    assert.deepEqual(calls.pop(), { start: '2025-10-30T09:00:00.000Z', end: '2025-10-30T10:00:00.000Z' });

    window('2025-10-30T00:00:00.000Z', '2025-10-30T23:59:59.999Z').stepBackward();
    const previous = calls.pop()!;
    assert.deepEqual(previous, { start: '2025-10-29T00:00:00.000Z', end: '2025-10-29T23:59:59.999Z' });
    window(previous.start, previous.end).stepBackward();
    assert.deepEqual(calls.pop(), { start: '2025-10-28T00:00:00.000Z', end: '2025-10-28T23:59:59.999Z' });

    const hour = window('2025-10-30T10:00:00.000Z', '2025-10-30T11:00:00.000Z');
    hour.expandWindow();
    assert.deepEqual(calls.pop(), {
      start: moment('2025-10-30T10:00:00.000Z').subtract(ZOOM_FACTOR_DEFAULT / 2, 'hours').toISOString(),
      end: moment('2025-10-30T11:00:00.000Z').add(ZOOM_FACTOR_DEFAULT / 2, 'hours').toISOString()
    });

    window('2025-10-30T00:00:00.000Z', '2025-10-30T23:59:59.999Z').expandWindow();
    const delta = (moment('2025-10-30T23:59:59.999Z').diff(moment('2025-10-30T00:00:00.000Z')) + 1) * (ZOOM_FACTOR_DEFAULT / 2);
    assert.deepEqual(calls.pop(), {
      start: moment('2025-10-30T00:00:00.000Z').subtract(delta, 'ms').toISOString(),
      end: moment('2025-10-30T23:59:59.999Z').add(delta, 'ms').toISOString()
    }, 'expand inclusive');

    window('2025-10-30T10:00:00.000Z', '2025-10-30T11:00:00.000Z', 0.42).expandWindow();
    assert.deepEqual(calls.pop(), {
      start: moment('2025-10-30T10:00:00.000Z').subtract(0.21, 'hours').toISOString(),
      end: moment('2025-10-30T11:00:00.000Z').add(0.21, 'hours').toISOString()
    }, 'custom zoom factor');

    window('2026-01-21T10:00:00.000Z', '2026-01-21T11:00:00.000Z').shrinkWindow();
    assert.deepEqual(calls.pop(), {
      start: moment('2026-01-21T10:00:00.000Z').add(ZOOM_FACTOR_DEFAULT / 2, 'hours').toISOString(),
      end: moment('2026-01-21T11:00:00.000Z').subtract(ZOOM_FACTOR_DEFAULT / 2, 'hours').toISOString()
    });

    const zero = window('2026-01-19T11:11:11.000Z', '2026-01-19T11:11:11.000Z');
    zero.stepForward();
    zero.stepBackward();
    zero.shrinkWindow();
    assert.strictEqual(calls.length, 0, 'a zero window does not step or shrink');
    zero.expandWindow();
    assert.deepEqual(calls.pop(), {
      start: moment('2026-01-19T11:11:11.000Z').subtract(ZOOM_DELTA_FALLBACK_MS, 'ms').toISOString(),
      end: moment('2026-01-19T11:11:11.000Z').add(ZOOM_DELTA_FALLBACK_MS, 'ms').toISOString()
    }, 'a zero window expands by the fallback');

    assert.throws(() => window('now-1h', 'now', 'abc' as unknown as number), /valid number/);
  });

  // ---------------------------------------------------------------- time zone display

  test('@timeZoneDisplayProps shows the time zone in the absolute and relative tabs', async function (assert) {
    const props = { timeZone: 'UTC' };

    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @start="2025-01-15T12:00:00.000Z" @timeZoneDisplayProps={{props}} /></template>);
    await openStart();

    const display = el(subj('euiTimeZoneDisplay'));
    assert.dom(display).hasText('UTC').hasAttribute('aria-label', 'UTC');
    assert.dom('.euiIcon', display).exists('globe icon');
    assert.dom(subj('superDatePickerAbsoluteDateInput'), document.body).hasAttribute('aria-describedby', display.id);

    await chooseTab('Relative');
    assert.dom(subj('euiTimeZoneDisplay'), document.body).hasText('UTC');
  });

  test('@timeZoneDisplayProps: Browser, invalid and no time zone', async function (assert) {
    class State {
      @tracked props: { timeZone?: string } = { timeZone: 'Browser' };
    }
    const state = new State();

    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @timeZoneDisplayProps={{state.props}} /></template>);
    await openStart();

    const browser = new Intl.DateTimeFormat().resolvedOptions().timeZone;
    let isKnownZone = true;
    try {
      new Intl.DateTimeFormat(undefined, { timeZone: browser });
    } catch {
      isKnownZone = false; // e.g. "Etc/Unknown" in a headless sandbox
    }
    if (isKnownZone) {
      assert.true(el(subj('euiTimeZoneDisplay')).textContent!.includes(browser), 'browser zone name');
    } else {
      assert.dom(subj('euiTimeZoneDisplay'), document.body).doesNotExist('unknown browser zone: hidden, like upstream');
    }

    state.props = { timeZone: 'Foo/Bar' };
    await rerender();
    assert.dom(subj('euiTimeZoneDisplay'), document.body).doesNotExist('invalid zone');

    state.props = {};
    await rerender();
    assert.dom(subj('euiTimeZoneDisplay'), document.body).doesNotExist('no zone');
    await chooseTab('Absolute');
    assert.dom(subj('superDatePickerAbsoluteDateInput'), document.body).doesNotHaveAttribute('aria-describedby');
  });

  test('@timeZoneDisplayProps.customRender gets the name display, offset and zone name', async function (assert) {
    const Custom: TOC<{ Args: { nameDisplay: unknown; utcOffset?: string; timeZoneName?: string } }> = <template>
      {{! @glint-expect-error: the yielded component }}
      <@nameDisplay />
      <span data-test-subj="utc">{{@utcOffset}}</span>
      <span data-test-subj="name">{{@timeZoneName}}</span>
    </template>;
    const props = { timeZone: 'Europe/Helsinki', date: moment('2025-06-21T02:42:00Z'), customRender: Custom };

    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @timeZoneDisplayProps={{props}} /></template>);
    await openStart();

    assert.true(el(subj('euiTimeZoneDisplay')).textContent!.includes('Helsinki'));
    assert.dom(subj('utc'), document.body).hasText('UTC+3');
    assert.dom(subj('name'), document.body).hasText('Europe/Helsinki');
  });

  // ---------------------------------------------------------------- min / max dates

  test('@minDate: a start before it is invalid (upstream)', async function (assert) {
    const minDate = moment('2024-10-01T00:00:00');

    await render(
      <template>
        <div data-p="valid"><EuiSuperDatePicker @onTimeChange={{noop}} @start="2024-10-01T00:00:00.000" @end="now" @minDate={{minDate}} /></div>
        <div data-p="invalid"><EuiSuperDatePicker @onTimeChange={{noop}} @start="2024-09-30T00:00:00.000" @end="now" @minDate={{minDate}} /></div>
      </template>
    );

    assert.dom('[data-p="valid"] .euiDatePopoverButton--start').doesNotHaveClass('euiDatePopoverButton-isInvalid');
    assert.dom('[data-p="valid"] .euiFormControlLayoutIcons').doesNotExist('no warning icon');
    assert.dom('[data-p="invalid"] .euiDatePopoverButton--start').hasClass('euiDatePopoverButton-isInvalid');
    assert.dom('[data-p="invalid"] .euiSuperUpdateButton').isDisabled();
  });

  test('@maxDate: an end after it is invalid (upstream)', async function (assert) {
    const maxDate = moment('2024-11-01T00:00:00');

    await render(
      <template>
        <div data-p="valid"><EuiSuperDatePicker @onTimeChange={{noop}} @start="2024-10-01T00:00:00.000" @end="2024-10-31T00:00:00.000" @maxDate={{maxDate}} /></div>
        <div data-p="invalid"><EuiSuperDatePicker @onTimeChange={{noop}} @start="2024-10-01T00:00:00.000" @end="2024-11-02T00:00:00.000" @maxDate={{maxDate}} /></div>
      </template>
    );

    assert.dom('[data-p="valid"] .euiDatePopoverButton--end').doesNotHaveClass('euiDatePopoverButton-isInvalid');
    assert.dom('[data-p="invalid"] .euiDatePopoverButton--end').hasClass('euiDatePopoverButton-isInvalid');
  });

  test('@minDate/@maxDate disable the calendar days outside them; a range change reports isInvalid', async function (assert) {
    const changes: TimeChange[] = [];
    const onTimeChange = (change: TimeChange) => changes.push(change);
    const start = moment().startOf('month').add(10, 'days').hour(12);
    const minDate = start.clone().subtract(2, 'days');
    const maxDate = moment().add(1, 'month');
    const startIso = start.toISOString();

    await render(
      <template>
        <EuiSuperDatePicker
          @onTimeChange={{onTimeChange}}
          @start={{startIso}}
          @end="now+1d"
          @minDate={{minDate}}
          @maxDate={{maxDate}}
          @showUpdateButton={{false}}
        />
      </template>
    );
    await openStart();

    const days = [...document.querySelectorAll<HTMLElement>('.react-datepicker__day:not(.react-datepicker__day--outside-month)')];
    const day = (n: number) => days.find((d) => d.textContent!.trim() === String(n))!;
    const before = day(minDate.date() - 1);
    const first = day(minDate.date());

    assert.dom(before).hasClass('react-datepicker__day--disabled').hasAttribute('aria-disabled', 'true');
    assert.dom(first).doesNotHaveClass('react-datepicker__day--disabled').doesNotHaveAttribute('aria-disabled');
    assert.strictEqual(getComputedStyle(before).cursor, 'not-allowed');

    await click(before);
    assert.strictEqual(changes.length, 0, 'a disabled day is not selected');

    await click(first);
    assert.strictEqual(changes.length, 1);
    assert.false(changes[0]!.isInvalid);

    // the text input can still pick a date before minDate: the range turns invalid
    await fillIn(el(subj('superDatePickerAbsoluteDateInput')), minDate.clone().subtract(5, 'days').format('MMM D, YYYY @ HH:mm:ss.SSS'));
    assert.true(changes.at(-1)!.isInvalid, 'reported invalid');
  });

  // ---------------------------------------------------------------- relative units

  test('@canRoundRelativeUnits defaults to true and rounds relative units (upstream)', async function (assert) {
    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @start="now-300m" @end="now" /></template>);

    assert.dom(subj('superDatePickerstartDatePopoverButton')).hasText('~ 5 hours ago');
    await openStart();
    await chooseTab('Relative');
    assert.dom(subj('superDatePickerRelativeDateInputNumber'), document.body).hasValue('5');
    assert.dom(subj('superDatePickerRelativeDateInputUnitSelector'), document.body).hasValue('h');
  });

  test('@canRoundRelativeUnits={{false}} keeps the units (upstream)', async function (assert) {
    await render(
      <template><EuiSuperDatePicker @onTimeChange={{noop}} @start="now-300m" @end="now" @canRoundRelativeUnits={{false}} /></template>
    );

    assert.dom(subj('superDatePickerstartDatePopoverButton')).hasText('300 minutes ago');
    await openStart();
    await chooseTab('Relative');
    assert.dom(subj('superDatePickerRelativeDateInputNumber'), document.body).hasValue('300');
    assert.dom(subj('superDatePickerRelativeDateInputUnitSelector'), document.body).hasValue('m');

    await select(el(subj('superDatePickerRelativeDateInputUnitSelector')), 'd');
    assert.dom(subj('superDatePickerstartDatePopoverButton')).hasText('300 days ago');
  });

  // ---------------------------------------------------------------- focus

  test('@onFocus is called when the date buttons get focus (upstream)', async function (assert) {
    const focused: string[] = [];
    const onFocus = (event: FocusEvent) => focused.push((event.target as HTMLElement).dataset['testSubj']!);

    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} @onFocus={{onFocus}} /></template>);

    await focus(subj('superDatePickerstartDatePopoverButton'));
    await focus(subj('superDatePickerendDatePopoverButton'));
    assert.deepEqual(focused, ['superDatePickerstartDatePopoverButton', 'superDatePickerendDatePopoverButton']);
  });
});

module('Integration | Component | EuiDatePickerRange inline', function (hooks) {
  setupRenderingTest(hooks);

  test('@inline drops the frame and icon, lays out the blocks and adds a shadow', async function (assert) {
    class State {
      @tracked shadow = true;
    }
    const state = new State();

    await render(
      <template>
        <EuiDatePickerRange @inline={{true}} @shadow={{state.shadow}} @fullWidth={{true}} @compressed={{true}}>
          <:start as |className|><EuiFieldText @controlOnly={{true}} class={{className}} aria-label="Start" /></:start>
          <:end as |className|><EuiFieldText @controlOnly={{true}} class={{className}} aria-label="End" /></:end>
        </EuiDatePickerRange>
      </template>
    );

    const root = el('.euiDatePickerRange');
    const layout = el('.euiFormControlLayoutDelimited', root);
    const wrapper = el('.euiFormControlLayout__childrenWrapper', root);

    assert.dom('.euiFormControlLayoutIcons .euiIcon', root).doesNotExist('no calendar icon');
    assert.strictEqual(getComputedStyle(root).containerType, 'inline-size');
    assert.strictEqual(getComputedStyle(layout).borderTopStyle, 'none');
    assert.strictEqual(getComputedStyle(wrapper).display, 'grid');
    assert.notStrictEqual(getComputedStyle(layout).boxShadow, 'none', 'shadow');
    assert.strictEqual(
      getComputedStyle(layout).backgroundColor,
      rgb(lightContext.euiTheme.colors.emptyShade),
      'empty shade background'
    );
    assert.true(
      layout.getBoundingClientRect().width < root.getBoundingClientRect().width,
      'fit-content width, @fullWidth ignored'
    );

    state.shadow = false;
    await rerender();
    assert.strictEqual(getComputedStyle(layout).boxShadow, 'none', 'no shadow');
    assert.strictEqual(getComputedStyle(layout).backgroundColor, 'rgba(0, 0, 0, 0)', 'transparent');
  });

  test('without @inline nothing changes (icon, frame)', async function (assert) {
    await render(
      <template>
        <EuiDatePickerRange>
          <:start as |className|><EuiFieldText @controlOnly={{true}} class={{className}} aria-label="Start" /></:start>
          <:end as |className|><EuiFieldText @controlOnly={{true}} class={{className}} aria-label="End" /></:end>
        </EuiDatePickerRange>
      </template>
    );

    assert.dom('.euiDatePickerRange .euiFormControlLayoutIcons .euiIcon').exists();
    assert.notStrictEqual(getComputedStyle(el('.euiDatePickerRange')).containerType, 'inline-size');
  });
});
