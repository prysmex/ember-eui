import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiSuperDatePicker from '#src/components/eui-super-date-picker.gts';

class Range {
  @tracked start = 'now-15m';
  @tracked end = 'now';
}

type TimeChange = { start: string; end: string; isQuickSelection: boolean; isInvalid: boolean };

const showDatesButton = '[data-test-subj="superDatePickerShowDatesButton"]';

/** Upstream: clicking the pretty duration shows the start/end buttons. */
async function showDates() {
  await click(showDatesButton);
  await waitUntil(() => document.querySelector('.euiDatePopoverContent'));
}

module('Integration | Component | eui-super-date-picker', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders the quick select, start/end buttons and the update button', async function (assert) {
    const noop = () => {};

    await render(<template><EuiSuperDatePicker @start="now-15m" @end="now" @onTimeChange={{noop}} /></template>);

    assert.dom('.euiSuperDatePicker .euiQuickSelectPopover__anchor button').exists();
    // upstream: a relative range shows as its pretty duration until clicked
    assert.dom(showDatesButton).hasText('Last 15 minutes');
    await showDates();
    assert.dom('.euiDatePopoverButton--start').hasAttribute('title', /minutes ago/);
    assert.dom('.euiDatePopoverButton--end').hasAttribute('title', 'now');
    assert.dom('.euiSuperUpdateButton').exists();
  });

  test('a commonly used range applies a quick selection', async function (assert) {
    const changes: TimeChange[] = [];
    const onTimeChange = (change: TimeChange) => changes.push(change);

    await render(<template><EuiSuperDatePicker @start="now-15m" @end="now" @onTimeChange={{onTimeChange}} /></template>);

    await click('.euiQuickSelectPopover__anchor button');
    await waitUntil(() => document.querySelector('.euiQuickSelectPopover__sectionItem'));

    const today = [...document.querySelectorAll('.euiQuickSelectPopover__sectionItem .euiLink')].find(
      (el) => el.textContent!.trim() === 'Today'
    ) as HTMLElement;

    await click(today);

    assert.strictEqual(changes.length, 1);
    assert.deepEqual(
      { start: changes[0]!.start, end: changes[0]!.end, isQuickSelection: changes[0]!.isQuickSelection },
      { start: 'now/d', end: 'now/d', isQuickSelection: true }
    );
  });

  test('the update button calls @onRefresh when nothing changed', async function (assert) {
    const refreshes: unknown[] = [];
    const onRefresh = (props: unknown) => refreshes.push(props);
    const noop = () => {};

    await render(
      <template><EuiSuperDatePicker @start="now-15m" @end="now" @onTimeChange={{noop}} @onRefresh={{onRefresh}} /></template>
    );

    await click('.euiSuperUpdateButton');
    assert.strictEqual(refreshes.length, 1);
    assert.deepEqual((refreshes[0] as { start: string; end: string }).start, 'now-15m');
  });

  test('an inverted range is invalid and disables the update button', async function (assert) {
    const noop = () => {};

    await render(<template><EuiSuperDatePicker @start="now" @end="now-15m" @onTimeChange={{noop}} /></template>);

    await showDates();
    assert.dom('.euiDatePopoverButton--start').hasClass('euiDatePopoverButton-isInvalid');
    assert.dom('.euiSuperUpdateButton').isDisabled();
  });

  test('@isDisabled and @showUpdateButton={{false}}', async function (assert) {
    const noop = () => {};

    await render(
      <template><EuiSuperDatePicker @start="now-15m" @end="now" @isDisabled={{true}} @showUpdateButton={{false}} @onTimeChange={{noop}} /></template>
    );

    assert.dom('.euiSuperUpdateButton').doesNotExist();
    // the legacy `__flexWrapper--noUpdateButton` modifier became upstream's narrower restricted width (30 × base)
    assert.strictEqual(getComputedStyle(document.querySelector('.euiSuperDatePicker')!).width, '480px');
    // upstream: the pretty duration button is disabled
    assert.dom(showDatesButton).isDisabled();
  });

  test('it follows changes to @start / @end', async function (assert) {
    const range = new Range();
    const noop = () => {};

    await render(<template><EuiSuperDatePicker @start={{range.start}} @end={{range.end}} @onTimeChange={{noop}} /></template>);

    // upstream: new relative ranges show as their pretty duration
    assert.dom(showDatesButton).hasText('Last 15 minutes');

    range.start = 'now-3h';
    await rerender();
    assert.dom(showDatesButton).hasText('Last 3 hours');

    range.start = 'now';
    range.end = 'now-1h';
    await rerender();
    assert.dom('.euiFormControlLayout').hasClass('euiFormControlLayout--group');
    assert.dom('.euiFormControlLayoutIcons .euiIcon').exists('invalid warning icon');
    assert.dom(showDatesButton).hasText('Last 1 hour');
    assert.dom('.euiSuperUpdateButton').isDisabled();

    range.end = 'now+1h';
    await rerender();
    assert.dom(showDatesButton).hasText('Next 1 hour');
    assert.dom('.euiSuperUpdateButton').isNotDisabled();
  });

  test('a selection is kept until the parent passes a new range', async function (assert) {
    const range = new Range();
    const noop = () => {};

    await render(<template><EuiSuperDatePicker @start={{range.start}} @end={{range.end}} @onTimeChange={{noop}} /></template>);

    assert.dom(showDatesButton).hasText('Last 15 minutes');

    await click('.euiQuickSelectPopover__anchor button');
    await waitUntil(() => document.querySelector('.euiQuickSelectPopover__sectionItem'));
    const thisWeek = [...document.querySelectorAll('.euiQuickSelectPopover__sectionItem .euiLink')].find(
      (el) => el.textContent!.trim() === 'This week'
    ) as HTMLElement;
    await click(thisWeek);

    // the parent ignored onTimeChange: the selection stays visible
    assert.dom(showDatesButton).hasText('This week', 'shows the quick selection');

    await rerender();
    assert.dom(showDatesButton).hasText('This week', 'survives re-renders');

    range.start = 'now-2h';
    await rerender();
    assert.dom(showDatesButton).hasText('Last 2 hours', 'new arguments win');
  });

  test('with @onRefreshChange the quick select shows the refresh interval', async function (assert) {
    const changes: { refreshInterval: number; isPaused: boolean }[] = [];
    const noop = () => {};
    const onRefreshChange = (change: { refreshInterval: number; isPaused: boolean }) => changes.push(change);

    await render(
      <template>
        <EuiSuperDatePicker @onTimeChange={{noop}} @onRefreshChange={{onRefreshChange}} @refreshInterval={{120000}} />
      </template>
    );

    await click('.euiQuickSelectPopover__anchor button');
    await waitUntil(() => document.querySelector('[data-test-subj="superDatePickerRefreshIntervalInput"]'));

    assert.dom('[data-test-subj="superDatePickerRefreshIntervalInput"]', document.body).hasValue('2');
    assert.dom('[data-test-subj="superDatePickerRefreshIntervalUnitsSelect"]', document.body).hasValue('m');

    await click(document.querySelector('[data-test-subj="superDatePickerToggleRefreshButton"]') as Element);
    // Upstream always reports the units with the interval.
    assert.deepEqual(changes, [{ refreshInterval: 120000, isPaused: false, intervalUnits: 'm' }]);
  });

  test('it calls @onRefresh every @refreshInterval while not paused', async function (assert) {
    class State {
      @tracked isPaused = false;
    }
    const state = new State();
    let refreshes = 0;
    const noop = () => {};
    const onRefresh = () => {
      refreshes++;
    };

    await render(
      <template>
        <EuiSuperDatePicker @onTimeChange={{noop}} @onRefresh={{onRefresh}} @isPaused={{state.isPaused}} @refreshInterval={{20}} />
      </template>
    );

    await waitUntil(() => refreshes >= 2, { timeout: 2000 });
    assert.true(refreshes >= 2, 'refreshes repeatedly');

    state.isPaused = true;
    await rerender();

    const count = refreshes;

    await new Promise((resolve) => setTimeout(resolve, 80));
    assert.strictEqual(refreshes, count, 'stops while paused');
  });
});
