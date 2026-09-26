import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiFlatpickr from '#src/components/eui-flatpickr.gjs';

// flatpickr renders its calendar into <body>
const calendar = () => document.querySelector('.flatpickr-calendar.open') as HTMLElement | null;

class State {
  @tracked date: Date[] | Date | null = new Date(2024, 4, 17);
  changes: Date[][] = [];
  onChange = (dates: Date[]) => {
    this.changes.push(dates);
    this.date = dates;
  };
  clear = (value: null) => (this.date = value);
}

module('Integration | Component | eui-flatpickr', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a text field with a calendar icon and the formatted date', async function (assert) {
    const state = new State();

    await render(
      <template><EuiFlatpickr @date={{state.date}} @onChange={{state.onChange}} @dateFormat="Y-m-d" /></template>
    );

    assert.dom('input.euiFieldText').hasValue('2024-05-17');
    assert.dom('.euiFormControlLayout .euiFormControlLayoutCustomIcon').exists('calendar icon');
  });

  test('picking a day calls @onChange with the selected dates', async function (assert) {
    const state = new State();

    await render(
      <template><EuiFlatpickr @date={{state.date}} @onChange={{state.onChange}} @dateFormat="Y-m-d" /></template>
    );

    await click('input.euiFieldText');
    await waitUntil(calendar);

    const day = [...calendar()!.querySelectorAll('.flatpickr-day:not(.prevMonthDay):not(.nextMonthDay)')].find(
      (el) => el.textContent!.trim() === '20'
    ) as HTMLElement;

    await click(day);

    const picked = state.changes.at(-1)![0]!;

    assert.strictEqual(picked.getFullYear(), 2024);
    assert.strictEqual(picked.getMonth(), 4);
    assert.strictEqual(picked.getDate(), 20);
    assert.dom('input.euiFieldText').hasValue('2024-05-20');
  });

  test('updating @date updates the field', async function (assert) {
    const state = new State();

    await render(
      <template><EuiFlatpickr @date={{state.date}} @onChange={{state.onChange}} @dateFormat="Y-m-d" /></template>
    );

    state.date = new Date(2023, 0, 2);
    await rerender();

    assert.dom('input.euiFieldText').hasValue('2023-01-02');
  });

  test('the clear button calls @clear(null)', async function (assert) {
    const state = new State();

    await render(
      <template><EuiFlatpickr @date={{state.date}} @onChange={{state.onChange}} @clear={{state.clear}} @dateFormat="Y-m-d" /></template>
    );

    await click('.euiFormControlLayoutClearButton');
    assert.strictEqual(state.date, null);
  });

  test('disabled, invalid, full width and compressed', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiFlatpickr @date={{state.date}} @onChange={{state.onChange}} @disabled={{true}} @isInvalid={{true}} @fullWidth={{true}} @compressed={{true}} />
      </template>
    );

    const input = (this.element as HTMLElement).querySelector('input')!;

    assert.dom(input).isDisabled().hasClass('euiFieldText--fullWidth').hasClass('euiFieldText--compressed');
    assert.false(input.validity.valid);
    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();
  });

  test('prepend and append', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiFlatpickr @date={{state.date}} @onChange={{state.onChange}} class="plain" />
        <EuiFlatpickr @date={{state.date}} @onChange={{state.onChange}} class="grouped">
          <:prepend as |classes|><span class="pre {{classes}}">From</span></:prepend>
        </EuiFlatpickr>
      </template>
    );

    assert.dom('input.plain').doesNotHaveClass('euiFieldText--inGroup');
    assert.dom('input.grouped').hasClass('euiFieldText--inGroup');
    assert.dom('.pre').hasText('From');
  });

  test('a string @locale loads that flatpickr locale', async function (assert) {
    const state = new State();

    await render(
      <template><EuiFlatpickr @date={{state.date}} @onChange={{state.onChange}} @dateFormat="Y-m-d" @locale="es" /></template>
    );

    await click('input.euiFieldText');
    await waitUntil(calendar);

    const weekdays = calendar()!.querySelector('.flatpickr-weekdays')!.textContent!;

    assert.true(weekdays.includes('Lun'), `Spanish weekdays (${weekdays.trim().replace(/\s+/g, ' ')})`);
  });
});
