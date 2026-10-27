import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, waitUntil } from '@ember/test-helpers';
import Component from '@glimmer/component';

import EuiSuperDatePicker from '#src/components/eui-super-date-picker.gts';

const noop = () => {};

// e.g. the current user's locale, unknown until loaded
class Picker extends Component<{
  Args: { locale: string | null | undefined };
}> {
  get locale(): string | null | undefined {
    return this.args.locale;
  }

  <template>
    <EuiSuperDatePicker
      @start="now-15m"
      @end="now"
      @locale={{this.locale}}
      @onTimeChange={{noop}}
    />
  </template>
}

module(
  'Integration | Component | eui-super-date-picker | null @locale',
  function (hooks) {
    setupRenderingTest(hooks);

    test('a null @locale formats in English, like an undefined one', async function (assert) {
      await render(<template><Picker @locale={{null}} /></template>);

      assert.dom('.euiDatePopoverButton--start').hasText(/minutes ago/);

      // the relative and absolute tabs format with the locale too
      await click('.euiDatePopoverButton--start');
      await waitUntil(() =>
        document.querySelector('[data-test-subj="superDatePickerAbsoluteTab"]')
      );
      assert.dom('[role="tabpanel"]', document.body).exists();

      await click('[data-test-subj="superDatePickerAbsoluteTab"]');
      assert.dom('[role="tabpanel"]', document.body).exists();
    });

    test('a string @locale is used', async function (assert) {
      await render(<template><Picker @locale="en" /></template>);

      assert.dom('.euiDatePopoverButton--start').hasText(/minutes ago/);
    });
  }
);
