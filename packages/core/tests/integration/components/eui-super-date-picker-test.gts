import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, waitUntil } from '@ember/test-helpers';

import EuiSuperDatePicker from '#src/components/eui-super-date-picker.gts';

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

  // Bug: the range is only validated when the user edits it, not for the
  // @start / @end the picker is rendered with
  test.todo('an inverted range is invalid and disables the update button', async function (assert) {
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
});
