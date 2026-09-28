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

    assert.dom('.euiDatePickerRange').hasClass('euiDatePickerRange--fullWidth');
    assert.dom('input:first-child').hasClass('euiDatePickerRange__start').hasClass('euiDatePicker');
    assert.dom('input:last-child').hasClass('euiDatePickerRange__end');
    assert.dom('.euiDatePickerRange__delimeter').hasText('→');
  });

  test('the default block replaces the layout', async function (assert) {
    await render(<template><EuiDatePickerRange @readOnly={{true}}><span class="custom">x</span></EuiDatePickerRange></template>);

    assert.dom('.euiDatePickerRange').hasClass('euiDatePickerRange--readOnly');
    assert.dom('.custom').exists();
    assert.dom('.euiDatePickerRange__delimeter').doesNotExist();
  });
});
