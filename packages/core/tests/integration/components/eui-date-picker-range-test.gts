import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiDatePickerRange from '#src/components/eui-date-picker-range.gts';

module('Integration | Component | eui-date-picker-range', function (hooks) {
  setupRenderingTest(hooks);

  test('it lays out the start and end inputs with an arrow', async function (assert) {
    await render(
      <template>
        <EuiDatePickerRange @fullWidth={{true}}>
          <:start as |className|><input class={{className}} aria-label="Start date" type="date" /></:start>
          <:end as |className|><input class={{className}} aria-label="End date" type="date" /></:end>
        </EuiDatePickerRange>
      </template>
    );

    // --fullWidth was a legacy modifier: the delimited layout now takes the full width
    assert.strictEqual(getComputedStyle(document.querySelector('.euiDatePickerRange .euiFormControlLayout')!).maxWidth, '100%');
    assert.dom('input[aria-label="Start date"]').hasClass('euiDatePickerRange__start').hasClass('euiDatePicker').hasClass('euiFormControlLayoutDelimited__input');
    assert.dom('input[aria-label="End date"]').hasClass('euiDatePickerRange__end');
    // upstream delimiter class (was the misspelled legacy `__delimeter`)
    assert.dom('.euiFormControlLayoutDelimited__delimiter').hasText('→');
  });

  test('the default block replaces the layout', async function (assert) {
    await render(<template><EuiDatePickerRange @readOnly={{true}}><span class="custom">x</span></EuiDatePickerRange></template>);

    // the default block replaces the delimited layout that @readOnly styles
    assert.dom('.euiDatePickerRange .custom').exists();
    assert.dom('.euiFormControlLayoutDelimited').doesNotExist();
    assert.dom('.euiFormControlLayoutDelimited__delimiter').doesNotExist();
  });
});
