import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, waitUntil } from '@ember/test-helpers';

import EuiPikaday from '#src/components/eui-pikaday.gts';

// pikaday renders its calendar into <body>
const calendar = () => document.querySelector('.pika-single:not(.is-hidden)') as HTMLElement | null;

/** Upstream drops the control's inset border inside a prepend/append group. */
function isInGroup(selector: string) {
  const input = document.querySelector<HTMLInputElement>(selector)!;

  return (
    input.closest('.euiFormControlLayout--group') !== null &&
    getComputedStyle(input).boxShadow === 'none'
  );
}

module('Integration | Component | eui-pikaday', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a text field with a calendar icon and the formatted value', async function (assert) {
    const value = new Date(2024, 4, 17);

    await render(<template><EuiPikaday @value={{value}} @format="DD.MM.YYYY" /></template>);

    assert.dom('input.euiFieldText').hasValue('17.05.2024');
    assert.dom('.euiFormControlLayout .euiFormControlLayoutCustomIcon').exists('calendar icon');
  });

  test('picking a day calls @onSelection with the date', async function (assert) {
    const selections: (Date | null)[] = [];
    const onSelection = (date: Date | null) => selections.push(date);
    const value = new Date(2024, 4, 17);

    await render(<template><EuiPikaday @value={{value}} @onSelection={{onSelection}} /></template>);

    await click('input.euiFieldText');
    await waitUntil(calendar);

    const day20 = calendar()!.querySelector('button.pika-button[data-pika-day="20"]') as HTMLElement;

    await click(day20);

    const picked = selections.at(-1)!;

    assert.strictEqual(picked.getFullYear(), 2024);
    assert.strictEqual(picked.getMonth(), 4);
    assert.strictEqual(picked.getDate(), 20);
  });

  test('@minDate / @maxDate disable days outside the range', async function (assert) {
    const value = new Date(2024, 4, 17);
    const minDate = new Date(2024, 4, 10);
    const maxDate = new Date(2024, 4, 25);

    await render(<template><EuiPikaday @value={{value}} @minDate={{minDate}} @maxDate={{maxDate}} /></template>);

    await click('input.euiFieldText');
    await waitUntil(calendar);

    assert.dom('td.is-disabled button[data-pika-day="5"]', calendar()!).exists();
    assert.dom('td:not(.is-disabled) button[data-pika-day="15"]', calendar()!).exists();
    assert.dom('td.is-disabled button[data-pika-day="28"]', calendar()!).exists();
  });

  test('field options: disabled, invalid, full width and compressed', async function (assert) {
    await render(
      <template><EuiPikaday @disabled={{true}} @isInvalid={{true}} @fullWidth={{true}} @compressed={{true}} /></template>
    );

    const input = (this.element as HTMLElement).querySelector('input')!;

    assert.dom(input).isDisabled();
    // Borealis form control: full width lifts the 400px max-width, compressed is 32px tall
    assert.strictEqual(getComputedStyle(input).maxWidth, '100%', 'full width');
    assert.strictEqual(input.offsetHeight, 32, 'compressed');
    assert.false(input.validity.valid);
  });

  test('prepend is only rendered when given', async function (assert) {
    await render(
      <template>
        <EuiPikaday class="plain" />
        <EuiPikaday class="with-prepend">
          <:prepend as |classes|><span class="pre {{classes}}">From</span></:prepend>
        </EuiPikaday>
      </template>
    );

    assert.false(isInGroup('input.plain'), 'plain input is not grouped');
    assert.dom('.pre').hasText('From');
    assert.true(isInGroup('input.with-prepend'), 'prepend groups the input');
  });

  test('append is only rendered when given', async function (assert) {
    await render(
      <template>
        <EuiPikaday class="with-append">
          <:append as |classes|><span class="post {{classes}}">UTC</span></:append>
        </EuiPikaday>
      </template>
    );

    assert.dom('.post').hasText('UTC');
    assert.true(isInGroup('input.with-append'), 'append groups the input');
  });
});
