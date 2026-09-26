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

module('Integration | Component | eui-super-date-picker', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders the quick select, start/end buttons and the update button', async function (assert) {
    const noop = () => {};

    await render(<template><EuiSuperDatePicker @start="now-15m" @end="now" @onTimeChange={{noop}} /></template>);

    assert.dom('.euiSuperDatePicker .euiQuickSelectPopover__anchor button').exists();
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

    assert.dom('.euiDatePopoverButton--start').hasClass('euiDatePopoverButton-isInvalid');
    assert.dom('.euiSuperUpdateButton').isDisabled();
  });

  test('@isDisabled and @showUpdateButton={{false}}', async function (assert) {
    const noop = () => {};

    await render(
      <template><EuiSuperDatePicker @start="now-15m" @end="now" @isDisabled={{true}} @showUpdateButton={{false}} @onTimeChange={{noop}} /></template>
    );

    assert.dom('.euiSuperUpdateButton').doesNotExist();
    assert.dom('.euiSuperDatePicker__flexWrapper').hasClass('euiSuperDatePicker__flexWrapper--noUpdateButton');
    assert.dom('.euiDatePopoverButton--start').isDisabled();
  });

  test('it follows changes to @start / @end', async function (assert) {
    const range = new Range();
    const noop = () => {};

    await render(<template><EuiSuperDatePicker @start={{range.start}} @end={{range.end}} @onTimeChange={{noop}} /></template>);

    assert.dom('.euiDatePopoverButton--start').hasAttribute('title', /minutes ago/);

    range.start = 'now-3h';
    await rerender();
    assert.dom('.euiDatePopoverButton--start').hasAttribute('title', /hours ago/);

    range.start = 'now';
    range.end = 'now-1h';
    await rerender();
    assert.dom('.euiDatePopoverButton--start').hasClass('euiDatePopoverButton-isInvalid');
    assert.dom('.euiSuperUpdateButton').isDisabled();

    range.end = 'now+1h';
    await rerender();
    assert.dom('.euiDatePopoverButton--start').doesNotHaveClass('euiDatePopoverButton-isInvalid');
    assert.dom('.euiSuperUpdateButton').isNotDisabled();
  });

  test('a selection is kept until the parent passes a new range', async function (assert) {
    const range = new Range();
    const noop = () => {};

    await render(<template><EuiSuperDatePicker @start={{range.start}} @end={{range.end}} @onTimeChange={{noop}} /></template>);

    const initialTitle = document.querySelector('.euiDatePopoverButton--start')!.getAttribute('title');

    await click('.euiQuickSelectPopover__anchor button');
    await waitUntil(() => document.querySelector('.euiQuickSelectPopover__sectionItem'));
    const thisWeek = [...document.querySelectorAll('.euiQuickSelectPopover__sectionItem .euiLink')].find(
      (el) => el.textContent!.trim() === 'This week'
    ) as HTMLElement;
    await click(thisWeek);

    // the parent ignored onTimeChange: the selection stays visible
    const selectedTitle = document.querySelector('.euiDatePopoverButton--start')!.getAttribute('title');
    assert.notStrictEqual(selectedTitle, initialTitle, 'shows the quick selection');

    await rerender();
    assert.dom('.euiDatePopoverButton--start').hasAttribute('title', selectedTitle!, 'survives re-renders');

    range.start = 'now-2h';
    await rerender();
    assert.dom('.euiDatePopoverButton--start').hasAttribute('title', /hours ago/, 'new arguments win');
  });
});
