/**
 * Upstream's `date_picker.test.tsx` (EUI v123.1.0), translated. Where the
 * Ember picker differs on purpose (DESIGN 4, 18), the test says how.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, focus, render, rerender } from '@ember/test-helpers';
import { registerWarnHandler } from '@ember/debug';
import { tracked } from '@glimmer/tracking';

import moment from 'moment';

import EuiDatePicker from '#src/components/eui-date-picker.gts';

let silenced = false;
registerWarnHandler((message, options, next) => {
  if (
    silenced &&
    String(options?.id ?? '').startsWith('ember-eui.eui-date-picker')
  ) {
    return;
  }
  next(message, options);
});

function el<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const input = () => el<HTMLInputElement>('input.euiDatePicker');

module(
  'Integration | Component | eui-date-picker | upstream',
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.afterEach(function () {
      silenced = false;
    });

    test('renders', async function (assert) {
      await render(
        <template>
          <EuiDatePicker
            aria-label="aria-label"
            class="testClass1 testClass2"
            data-test-subj="test subject string"
          />
        </template>
      );
      assert.dom('.euiDatePicker > .euiFormControlLayout').exists();
      assert
        .dom(input())
        .hasClass('testClass1')
        .hasClass('testClass2')
        .hasAttribute('aria-label', 'aria-label')
        .hasAttribute('data-test-subj', 'test subject string');
    });

    test('handles invalid `selected` dates (an invalid moment is no value, DESIGN 18)', async function (assert) {
      silenced = true;
      const selected = moment('invalid', 'YYYY-MM-DD', true);
      await render(<template><EuiDatePicker @value={{selected}} /></template>);
      // upstream shows "Invalid date" (moment's text); here the value is empty
      assert.dom(input()).hasValue('');
      assert.false(input().validity.valid, 'toBeInvalid');
      await focus(input());
      assert
        .dom('[data-popover-panel] .react-datepicker__month', document.body)
        .exists('the calendar loads in a popover');
      assert
        .dom(
          '[data-popover-panel] .react-datepicker__day--selected',
          document.body
        )
        .doesNotExist('no date is selected');
    });

    test('onClear', async function (assert) {
      class State {
        @tracked selected: moment.Moment | null = moment();
        @tracked disabled = false;
      }
      const state = new State();
      const onClear = () => {};
      silenced = true;
      await render(
        <template>
          <EuiDatePicker
            @onClear={{onClear}}
            @value={{state.selected}}
            @disabled={{state.disabled}}
          />
        </template>
      );
      assert
        .dom('[aria-label="Clear input"]')
        .exists('renders the clear button');
      state.disabled = true;
      await rerender();
      assert
        .dom('[aria-label="Clear input"]')
        .doesNotExist('not if the input is disabled');
      state.disabled = false;
      state.selected = null;
      await rerender();
      assert
        .dom('[aria-label="Clear input"]')
        .doesNotExist('not if no date is selected');
    });

    test('compressed', async function (assert) {
      await render(<template><EuiDatePicker @compressed={{true}} /></template>);
      assert.true(el('#ember-testing').innerHTML.includes('-compressed'));
    });

    test('data-test-subj (on the input: `...attributes`)', async function (assert) {
      await render(
        <template><EuiDatePicker data-test-subj="date-picker-test" /></template>
      );
      // upstream puts it on the wrapper and `date-picker-test-input` on the
      // input; Ember gives the attributes to the input itself
      assert.dom('[data-test-subj="date-picker-test"]').exists();
      assert.strictEqual(el('[data-test-subj="date-picker-test"]'), input());
    });

    test('data-test-subj with clear button (the button is found by its label)', async function (assert) {
      const selected = '2026-11-24';
      const onClear = () => {};
      await render(
        <template>
          <EuiDatePicker
            data-test-subj="date-picker-test"
            @value={{selected}}
            @onClear={{onClear}}
          />
        </template>
      );
      // upstream: `date-picker-test-clear`; attributes cannot be read here
      assert
        .dom('.euiFormControlLayoutClearButton')
        .hasAttribute('aria-label', 'Clear input');
    });

    test('append/prepend', async function (assert) {
      await render(
        <template>
          <div data-p="default"><EuiDatePicker>
              <:prepend>world</:prepend>
              <:append>hello</:append>
            </EuiDatePicker></div>
          <div data-p="controlOnly"><EuiDatePicker @controlOnly={{true}}>
              <:prepend>world</:prepend>
              <:append>hello</:append>
            </EuiDatePicker></div>
          <div data-p="inline"><EuiDatePicker @inline={{true}}>
              <:prepend>world</:prepend>
              <:append>hello</:append>
            </EuiDatePicker></div>
        </template>
      );
      assert
        .dom('[data-p="default"] .euiFormControlLayout__append')
        .hasText('hello');
      assert
        .dom('[data-p="default"] .euiFormControlLayout__prepend')
        .hasText('world');
      assert
        .dom('[data-p="controlOnly"] .euiFormControlLayout__append')
        .doesNotExist('does not render if controlOnly');
      assert
        .dom('[data-p="controlOnly"] .euiFormControlLayout__prepend')
        .doesNotExist();
      assert
        .dom('[data-p="inline"] .euiFormControlLayout__append')
        .doesNotExist('does not render if inline');
      assert
        .dom('[data-p="inline"] .euiFormControlLayout__prepend')
        .doesNotExist();
    });

    module('minDate/maxDate', function () {
      test('does not fire onChange when month navigation via dropdown produces an out-of-bounds date', async function (assert) {
        const changes: unknown[] = [];
        const onChange = (value: string | null) => changes.push(value);
        const selected = '2025-05-15';
        const maxDate = '2025-05-31';
        await render(
          <template>
            <EuiDatePicker
              @inline={{true}}
              @value={{selected}}
              @maxDate={{maxDate}}
              @onChange={{onChange}}
            />
          </template>
        );
        const month = el<HTMLSelectElement>('select[aria-label="Month"]');
        // August is past maxDate: the option is disabled, and choosing it anyway emits nothing
        assert.dom('option[value="7"]', month).isDisabled();
        month.value = '7';
        month.dispatchEvent(new Event('change', { bubbles: true }));
        await rerender();
        assert.deepEqual(changes, []);
      });

      test('does not fire onChange when year navigation via dropdown produces an out-of-bounds date', async function (assert) {
        const changes: unknown[] = [];
        const onChange = (value: string | null) => changes.push(value);
        const selected = moment('2025-02-15');
        const minDate = moment('2024-06-01');
        silenced = true;
        await render(
          <template>
            <EuiDatePicker
              @inline={{true}}
              @value={{selected}}
              @minDate={{minDate}}
              @onChange={{onChange}}
            />
          </template>
        );
        const year = el<HTMLSelectElement>('select[aria-label="Year"]');
        year.value = '2024';
        year.dispatchEvent(new Event('change', { bubbles: true }));
        await rerender();
        assert.deepEqual(changes, []);
        assert
          .dom('td[data-date="2024-06-01"]')
          .exists('the calendar shows 2024, clamped to minDate');
      });
    });

    test('popoverPlacement (upstream skips it in Jest; here the popover opens)', async function (assert) {
      await render(
        <template><EuiDatePicker @popoverPlacement="upRight" /></template>
      );
      await click(input());
      assert.dom('[data-popover-panel]', document.body).exists();
    });

    module('localization', function () {
      test('accepts the locale prop', async function (assert) {
        const selected = '2019-07-01';
        await render(
          <template>
            <EuiDatePicker @inline={{true}} @value={{selected}} @locale="ko" />
          </template>
        );
        assert
          .dom('select[aria-label="Month"] option[value="6"]')
          .hasText('7월', 'Korean month names');
        assert.dom('td[data-date="2019-07-01"] > button').hasAttribute(
          'aria-label',
          new Intl.DateTimeFormat('ko', {
            dateStyle: 'full',
            timeZone: 'UTC'
          }).format(Date.UTC(2019, 6, 1))
        );
      });

      test("inherits the locale from the document (upstream: EuiContext's i18n locale)", async function (assert) {
        const previous = document.documentElement.lang;
        document.documentElement.lang = 'fr';
        try {
          await render(
            <template>
              <EuiDatePicker @inline={{true}} @value="2019-07-01" />
            </template>
          );
          assert
            .dom('select[aria-label="Month"] option[value="6"]')
            .hasText('juillet');
        } finally {
          document.documentElement.lang = previous;
        }
      });
    });
  }
);
