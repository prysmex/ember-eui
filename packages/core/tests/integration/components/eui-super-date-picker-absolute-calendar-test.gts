import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  focus,
  render,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import moment from 'moment';

import EuiFieldText from '#src/components/eui-field-text.gts';
import EuiSuperDatePicker from '#src/components/eui-super-date-picker.gts';
import EuiDatePopoverButton from '#src/components/eui-super-date-picker/date-popover/eui-date-popover-button.gts';

import type { EuiDatePopoverButtonSignature } from '#src/components/eui-super-date-picker/date-popover/eui-date-popover-button.gts';
import type { Moment } from 'moment';

/** The type an app reads `@onChange`'s value as (as Prysmex does). */
type PopoverValue = Parameters<
  EuiDatePopoverButtonSignature['Args']['onChange']
>[0];

/*
 * Batch 7 (DESIGN 3): the Absolute tab moved onto `EuiDatePicker`'s
 * calendar and time list. One test per bug of the old calendar
 * (`datetime-picker.gts`, deleted), through the public component.
 */

interface TimeChange {
  start: string;
  end: string;
  isInvalid: boolean;
  isQuickSelection: boolean;
}

function el<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const cell = (date: string) => el(`.euiAbsoluteTab td[data-date="${date}"]`);
const dayButton = (date: string) =>
  el<HTMLButtonElement>(`.euiAbsoluteTab td[data-date="${date}"] > button`);
const shownDates = () =>
  [
    ...document.querySelectorAll<HTMLElement>('.euiAbsoluteTab td[data-date]')
  ].map((td) => td.dataset['date']!);
const selectedDates = () =>
  [
    ...document.querySelectorAll<HTMLElement>(
      '.euiAbsoluteTab td.react-datepicker__day--selected'
    )
  ].map((td) => td.dataset['date']!);
const focusedDate = () =>
  (document.activeElement as HTMLElement | null)?.closest<HTMLElement>(
    'td[data-date]'
  )?.dataset['date'];
const monthSelect = () =>
  el<HTMLSelectElement>('.euiAbsoluteTab select[aria-label="Month"]');
const yearSelect = () =>
  el<HTMLSelectElement>('.euiAbsoluteTab select[aria-label="Year"]');
const textInput = () =>
  el<HTMLInputElement>('[data-test-subj="superDatePickerAbsoluteDateInput"]');
/** The last item. */
const last = <T,>(items: T[]): T => items[items.length - 1]!;
/** A local wall time as the ISO string `@onTimeChange` reports. */
const iso = (local: string) => moment(local).toISOString();

async function openStart() {
  await click('.euiDatePopoverButton--start');
  await waitUntil(() => document.querySelector('.euiAbsoluteTab'));
}

class State {
  @tracked start: string;
  @tracked end = 'now';
  changes: TimeChange[] = [];

  constructor(start: string) {
    this.start = start;
  }

  onTimeChange = (change: TimeChange) => {
    this.changes.push(change);
    this.start = change.start;
    this.end = change.end;
  };
}

module(
  'Integration | Component | eui-super-date-picker | absolute calendar',
  function (hooks) {
    setupRenderingTest(hooks);

    test('January: a January day shown in December and in February is picked in January', async function (assert) {
      const state = new State('2024-12-10T10:30:00.000');
      await render(
        <template>
          <EuiSuperDatePicker
            @start={{state.start}}
            @end={{state.end}}
            @onTimeChange={{state.onTimeChange}}
            @showUpdateButton={{false}}
          />
        </template>
      );
      await openStart();
      assert.dom(monthSelect()).hasValue('11');
      assert
        .dom(cell('2025-01-02'))
        .hasClass('react-datepicker__day--outside-month');

      await click(cell('2025-01-02'));
      assert.strictEqual(
        last(state.changes).start,
        iso('2025-01-02T10:30:00.000'),
        'the 2nd of January, the time kept'
      );
      assert.dom(monthSelect()).hasValue('0', 'January is shown');
      assert.dom(yearSelect()).hasValue('2025');
      assert.deepEqual(selectedDates(), ['2025-01-02']);
      assert.dom(textInput()).hasValue('Jan 2, 2025 @ 10:30:00.000');

      // February's grid starts with the end of January (month 0)
      await fillIn(monthSelect(), '1');
      assert
        .dom(cell('2025-01-30'))
        .hasClass('react-datepicker__day--outside-month');
      await click(cell('2025-01-30'));
      assert.strictEqual(
        last(state.changes).start,
        iso('2025-01-30T10:30:00.000'),
        'the 30th of January, not the 2nd of March'
      );
      assert.dom(monthSelect()).hasValue('0');

      // and a day of January itself
      await click(cell('2025-01-15'));
      assert.strictEqual(
        last(state.changes).start,
        iso('2025-01-15T10:30:00.000')
      );
    });

    test('the year select changes the days shown; looking does not change the value', async function (assert) {
      const state = new State('2020-03-10T10:30:00.000');
      await render(
        <template>
          <EuiSuperDatePicker
            @start={{state.start}}
            @end={{state.end}}
            @onTimeChange={{state.onTimeChange}}
            @showUpdateButton={{false}}
          />
        </template>
      );
      await openStart();
      assert.true(shownDates().includes('2020-03-10'));

      await fillIn(yearSelect(), '2022');
      assert.dom(yearSelect()).hasValue('2022');
      assert.dom(monthSelect()).hasValue('2', 'still March');
      assert.true(shownDates().includes('2022-03-10'), 'March 2022 is shown');
      assert.false(shownDates().includes('2020-03-10'));
      assert.deepEqual(state.changes, [], 'no change by looking');
      assert.deepEqual(selectedDates(), [], 'nothing selected in 2022');

      await click(cell('2022-03-21'));
      assert.strictEqual(
        last(state.changes).start,
        iso('2022-03-21T10:30:00.000')
      );
    });

    test('locale: names and the first day of the week follow @locale; English and Sunday without one', async function (assert) {
      class LocaleState {
        @tracked locale: string | undefined = 'fr';
      }
      const state = new LocaleState();
      await render(
        <template>
          <EuiSuperDatePicker
            @start="2026-11-24T10:00:00.000"
            @end="now"
            @locale={{state.locale}}
            @onTimeChange={{noop}}
          />
        </template>
      );
      await openStart();
      const headers = () =>
        [
          ...document.querySelectorAll<HTMLElement>(
            '.euiAbsoluteTab .react-datepicker__day-name'
          )
        ].map((th) => th.getAttribute('abbr'));
      const firstColumn = () =>
        el<HTMLElement>('.euiAbsoluteTab .react-datepicker__week td[data-date]')
          .dataset['date']!;
      const monthText = () =>
        monthSelect().selectedOptions[0]!.textContent!.trim();

      assert.strictEqual(headers()[0], 'lundi', 'fr: Monday first');
      assert.strictEqual(headers().length, 7);
      assert.strictEqual(
        new Date(`${firstColumn()}T00:00:00Z`).getUTCDay(),
        1,
        'the first column is a Monday'
      );
      assert.strictEqual(monthText(), 'novembre');
      assert.strictEqual(
        dayButton('2026-11-24').getAttribute('aria-label'),
        new Intl.DateTimeFormat('fr', {
          weekday: 'long',
          day: 'numeric',
          month: 'long',
          year: 'numeric',
          timeZone: 'UTC'
        }).format(Date.UTC(2026, 10, 24)),
        'days are read out in French'
      );
      assert
        .dom(
          '.euiAbsoluteTab .react-datepicker__time-list-item--selected',
          document.body
        )
        .hasText('10:00', 'the time list stays 24-hour');

      // closing and opening again with no locale: English, Sunday
      await click('.euiDatePopoverButton--start');
      await waitUntil(() => !document.querySelector('.euiAbsoluteTab'));
      state.locale = undefined;
      await openStart();
      assert.strictEqual(headers()[0], 'Sunday');
      assert.strictEqual(new Date(`${firstColumn()}T00:00:00Z`).getUTCDay(), 0);
      assert.strictEqual(monthText(), 'November');
    });

    test('keys: arrows, PageDown and Shift+PageUp move the focused day; a pick by key and a time by key', async function (assert) {
      const state = new State('2026-11-24T10:30:00.000');
      await render(
        <template>
          <EuiSuperDatePicker
            @start={{state.start}}
            @end={{state.end}}
            @onTimeChange={{state.onTimeChange}}
            @showUpdateButton={{false}}
          />
        </template>
      );
      await openStart();
      assert.dom(dayButton('2026-11-24')).hasAttribute('tabindex', '0');
      assert.dom(dayButton('2026-11-23')).hasAttribute('tabindex', '-1');
      await focus(dayButton('2026-11-24'));

      await triggerKeyEvent(document.activeElement!, 'keydown', 'ArrowRight');
      assert.strictEqual(focusedDate(), '2026-11-25');
      await triggerKeyEvent(document.activeElement!, 'keydown', 'ArrowDown');
      assert.strictEqual(
        focusedDate(),
        '2026-12-02',
        'a week on, into December'
      );
      assert.dom(monthSelect()).hasValue('11');
      await triggerKeyEvent(document.activeElement!, 'keydown', 'PageDown');
      assert.strictEqual(focusedDate(), '2027-01-02', 'a month on');
      await triggerKeyEvent(document.activeElement!, 'keydown', 'PageUp', {
        shiftKey: true
      });
      assert.strictEqual(focusedDate(), '2026-01-02', 'a year back');
      assert.deepEqual(state.changes, [], 'moving does not change the value');

      // Enter on the focused button activates it natively: a click
      (document.activeElement as HTMLButtonElement).click();
      await waitUntil(() => state.changes.length === 1);
      assert.strictEqual(
        state.changes[0]!.start,
        iso('2026-01-02T10:30:00.000')
      );
      assert.strictEqual(focusedDate(), '2026-01-02', 'focus stays on the day');

      // the time list: a listbox with arrows and Enter
      const list = el('.euiAbsoluteTab .react-datepicker__time-list');
      assert
        .dom(list)
        .hasAttribute('role', 'listbox')
        .hasAttribute('tabindex', '0');
      await focus(list);
      await triggerKeyEvent(list, 'keydown', 'ArrowDown');
      await triggerKeyEvent(list, 'keydown', 'Enter');
      assert.strictEqual(
        last(state.changes).start,
        iso('2026-01-02T11:00:00.000'),
        'the entry after 10:30, seconds zero'
      );
    });

    test('no mutation: navigating does not move the value; @minDate and @maxDate are only read', async function (assert) {
      const minDate = moment('2026-10-05T15:00:00.000');
      const maxDate = moment('2027-02-20T08:00:00.000').locale('en');
      const before = (m: Moment) => ({
        value: m.valueOf(),
        text: m.format(),
        locale: m.locale()
      });
      const minBefore = before(minDate);
      const maxBefore = before(maxDate);
      const state = new State('2026-11-24T10:30:00.000');
      await render(
        <template>
          <EuiSuperDatePicker
            @start={{state.start}}
            @end={{state.end}}
            @minDate={{minDate}}
            @maxDate={{maxDate}}
            @locale="fr"
            @onTimeChange={{state.onTimeChange}}
            @showUpdateButton={{false}}
          />
        </template>
      );
      await openStart();
      const text = textInput().value;

      await click(el('.euiAbsoluteTab .react-datepicker__navigation--next'));
      assert.dom(monthSelect()).hasValue('11');
      assert.deepEqual(
        selectedDates(),
        [],
        'the 24th of December is not selected'
      );
      await click(
        el('.euiAbsoluteTab .react-datepicker__navigation--previous')
      );
      await click(
        el('.euiAbsoluteTab .react-datepicker__navigation--previous')
      );
      assert.dom(monthSelect()).hasValue('9');
      assert
        .dom(cell('2026-10-04'))
        .hasClass('react-datepicker__day--disabled');
      assert
        .dom(cell('2026-10-05'))
        .doesNotHaveClass('react-datepicker__day--disabled');
      await click(el('.euiAbsoluteTab .react-datepicker__navigation--next'));
      assert.deepEqual(selectedDates(), ['2026-11-24'], 'back: still the 24th');
      assert.deepEqual(state.changes, []);
      assert.dom(textInput()).hasValue(text, 'the text is unchanged');

      await click(cell('2026-11-12'));
      assert.strictEqual(
        last(state.changes).start,
        iso('2026-11-12T10:30:00.000')
      );
      assert.deepEqual(before(minDate), minBefore, '@minDate unchanged');
      assert.deepEqual(before(maxDate), maxBefore, '@maxDate unchanged');
    });

    test('the calendar follows typed text, and keeps the last valid value while the text cannot be read', async function (assert) {
      const state = new State('2026-11-24T10:30:00.000');
      await render(
        <template>
          <EuiSuperDatePicker
            @start={{state.start}}
            @end={{state.end}}
            @onTimeChange={{state.onTimeChange}}
            @showUpdateButton={{false}}
          />
        </template>
      );
      await openStart();
      await fillIn(textInput(), 'Feb 3, 2025 @ 14:00:00.000');
      assert.strictEqual(
        last(state.changes).start,
        iso('2025-02-03T14:00:00.000')
      );
      assert.dom(monthSelect()).hasValue('1', 'February is shown');
      assert.dom(yearSelect()).hasValue('2025');
      assert.deepEqual(selectedDates(), ['2025-02-03']);
      assert
        .dom(
          '.euiAbsoluteTab .react-datepicker__time-list-item--selected',
          document.body
        )
        .hasText('14:00');

      await fillIn(textInput(), 'Feb 3, 20');
      assert.dom(textInput()).hasAttribute('aria-invalid', 'true');
      assert.dom(monthSelect()).hasValue('1', 'the month stays');
      assert.deepEqual(
        selectedDates(),
        ['2025-02-03'],
        'the value stays shown'
      );

      // a pick replaces the unreadable text
      await click(cell('2025-02-03'));
      assert.dom(textInput()).hasValue('Feb 3, 2025 @ 14:00:00.000');
      assert.dom(textInput()).doesNotHaveAttribute('aria-invalid');
    });

    test('a picked time keeps the day; a picked day keeps the time', async function (assert) {
      const state = new State('2026-11-24T10:30:15.250');
      await render(
        <template>
          <EuiSuperDatePicker
            @start={{state.start}}
            @end={{state.end}}
            @onTimeChange={{state.onTimeChange}}
            @showUpdateButton={{false}}
          />
        </template>
      );
      await openStart();
      await click(cell('2026-11-20'));
      assert.strictEqual(
        last(state.changes).start,
        iso('2026-11-20T10:30:15.250'),
        'the whole time of day is kept'
      );
      await click(
        el(
          '.euiAbsoluteTab .react-datepicker__time-list-item[data-time="14:30"]'
        )
      );
      assert.strictEqual(
        last(state.changes).start,
        iso('2026-11-20T14:30:00.000')
      );
      assert
        .dom(
          '.euiAbsoluteTab .react-datepicker__time-list-item--selected',
          document.body
        )
        .hasText('14:30');
    });
    test('EuiDatePopoverButton on its own, with a <:button> block that opens on focusin (as an app uses it)', async function (assert) {
      class ButtonState {
        @tracked value: string = iso('2026-11-24T10:30:00.000');
        changes: PopoverValue[] = [];
        update = (value: PopoverValue) => {
          this.changes.push(value);
          this.value = value;
        };
      }
      const state = new ButtonState();
      await render(
        <template>
          <EuiDatePopoverButton
            @position="start"
            @value={{state.value}}
            @roundUp={{false}}
            @dateFormat="MMM D, YYYY @ HH:mm:ss.SSS"
            @timeFormat="HH:mm"
            @locale="en"
            @utcOffset={{-360}}
            @onChange={{state.update}}
          >
            <:button as |api|>
              <EuiFieldText
                @value={{api.formattedValue}}
                readonly
                data-test-subj="appDateField"
                {{on "focusin" api.open}}
              />
            </:button>
          </EuiDatePopoverButton>
        </template>
      );
      const field = () =>
        el<HTMLInputElement>('[data-test-subj="appDateField"]');
      assert.dom(field()).hasValue('Nov 24, 2026 @ 10:30:00.000');

      await focus(field());
      await waitUntil(() => document.querySelector('.euiAbsoluteTab'));
      assert
        .dom('[data-test-subj="superDatePickerAbsoluteTab"]', document.body)
        .hasAria(
          'selected',
          'true',
          'an absolute value opens the Absolute tab'
        );
      assert.deepEqual(selectedDates(), ['2026-11-24']);

      await click(cell('2026-11-12'));
      assert.deepEqual(state.changes, [iso('2026-11-12T10:30:00.000')]);
      assert.strictEqual(typeof state.changes[0], 'string');
      assert.dom(field()).hasValue('Nov 12, 2026 @ 10:30:00.000');
      assert.dom(textInput()).hasValue('Nov 12, 2026 @ 10:30:00.000');

      await click(
        el(
          '.euiAbsoluteTab .react-datepicker__time-list-item[data-time="14:30"]'
        )
      );
      assert.strictEqual(last(state.changes), iso('2026-11-12T14:30:00.000'));
      assert.dom(field()).hasValue('Nov 12, 2026 @ 14:30:00.000');
      assert
        .dom(
          '.euiAbsoluteTab .react-datepicker__time-list-item--selected',
          document.body
        )
        .hasText('14:30', 'the time list stays 24-hour');
      assert
        .dom('.euiAbsoluteTab', document.body)
        .exists('the popover stays open');

      // a January day from December's grid, through the app's field
      await fillIn(monthSelect(), '11');
      await click(cell('2027-01-01'));
      assert.strictEqual(last(state.changes), iso('2027-01-01T14:30:00.000'));
      assert.dom(field()).hasValue('Jan 1, 2027 @ 14:30:00.000');
    });
  }
);

const noop = () => {};
