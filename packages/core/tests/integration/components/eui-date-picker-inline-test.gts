import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, rerender } from '@ember/test-helpers';
import { registerWarnHandler } from '@ember/debug';
import { array } from '@ember/helper';
import { tracked } from '@glimmer/tracking';

import EuiDatePicker from '#src/components/eui-date-picker.gts';
import { todayIn } from '#src/utils/date/zone.ts';

/** Development warnings of the picker, captured while a test asks for them. */
let warnings: string[] | null = null;
registerWarnHandler((message, options, next) => {
  if (
    warnings &&
    String(options?.id ?? '').startsWith('ember-eui.eui-date-picker')
  ) {
    warnings.push(message);
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

/** The cell of a day (`td[data-date]`). */
const cell = (date: string) => el(`td[data-date="${date}"]`);
/** The button of a day. */
const day = (date: string) =>
  el<HTMLButtonElement>(`td[data-date="${date}"] > button`);
const enabledDays = () =>
  [
    ...document.querySelectorAll<HTMLElement>(
      'td[data-date]:not(.react-datepicker__day--disabled)'
    )
  ].map((td) => td.dataset['date']);
const heading = () => el('.react-datepicker h2').textContent!.trim();

class State {
  @tracked value: string | null = null;
  changes: (string | null)[] = [];
  onChange = (value: string | null) => {
    this.changes.push(value);
    this.value = value;
  };
}

module('Integration | Component | eui-date-picker | inline', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(function () {
    warnings = null;
  });

  test('renders upstream inline markup: wrapper, frame, calendar, header, grid', async function (assert) {
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value="2026-11-24"
          @locale="en-US"
          @firstDayOfWeek={{0}}
          data-test-subj="picker"
          class="custom"
        />
      </template>
    );
    assert
      .dom('.euiDatePicker > .euiFormControlLayout')
      .exists('wrapper, then the form control layout');
    assert
      .dom('.euiFormControlLayout__childrenWrapper > .react-datepicker')
      .exists('the calendar is the control');
    const calendar = el('.react-datepicker');
    assert
      .dom(calendar)
      .hasAttribute(
        'data-test-subj',
        'picker',
        '...attributes reach the calendar'
      );
    assert.dom(calendar).hasClass('custom');
    assert
      .dom(calendar)
      .hasAttribute('role', 'group')
      .hasAttribute('aria-label', 'Choose date');
    assert.dom(calendar).doesNotHaveClass('react-datepicker--non-interactive');

    assert
      .dom('.react-datepicker__navigation--previous', calendar)
      .hasAttribute('aria-label', 'Previous month');
    assert
      .dom('.react-datepicker__navigation--next', calendar)
      .hasAttribute('aria-label', 'Next month');
    assert
      .dom(
        '.react-datepicker__month-container .react-datepicker__header__dropdown'
      )
      .exists();
    assert
      .dom('select[aria-label="Month"]', calendar)
      .hasValue('10', 'months count from 0, as the Absolute tab');
    assert.dom('select[aria-label="Year"]', calendar).hasValue('2026');

    assert
      .dom('.react-datepicker__week', calendar)
      .exists({ count: 5 }, 'November 2026 from Sunday: 5 weeks');
    assert.deepEqual(
      [
        ...calendar.querySelectorAll(
          '.react-datepicker__day-name [aria-hidden]'
        )
      ].map((th) => th.textContent),
      ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    );
    assert
      .dom(cell('2026-11-24'))
      .hasClass('react-datepicker__day--selected')
      .hasText('24');
    assert
      .dom('.react-datepicker__day--selected', calendar)
      .exists({ count: 1 });
    assert
      .dom(cell('2026-11-01'))
      .hasClass('react-datepicker__day--sun')
      .hasClass('react-datepicker__day--weekend');
    assert
      .dom(cell('2026-11-02'))
      .hasClass('react-datepicker__day--mon')
      .doesNotHaveClass('react-datepicker__day--weekend');
    assert
      .dom(cell('2026-12-05'))
      .hasClass('react-datepicker__day--outside-month');
    assert
      .dom(cell('2026-11-30'))
      .doesNotHaveClass('react-datepicker__day--outside-month');
  });

  test('picking a day emits YYYY-MM-DD; the selected day emits nothing; an outside day moves the month', async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value={{state.value}}
          @onChange={{state.onChange}}
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    await click(cell('2026-11-10'));
    assert.deepEqual(state.changes, ['2026-11-10']);
    assert.dom(cell('2026-11-10')).hasClass('react-datepicker__day--selected');
    assert
      .dom(cell('2026-11-24'))
      .doesNotHaveClass('react-datepicker__day--selected');

    await click(cell('2026-11-10'));
    assert.deepEqual(
      state.changes,
      ['2026-11-10'],
      'the selected day again: no change'
    );

    await click(day('2026-12-02'));
    assert.deepEqual(
      state.changes,
      ['2026-11-10', '2026-12-02'],
      'a click on the button counts too'
    );
    assert.strictEqual(
      heading(),
      'December 2026',
      'the calendar follows the value to December'
    );
    assert.dom(cell('2026-12-02')).hasClass('react-datepicker__day--selected');
    assert
      .dom(day('2026-12-02'))
      .isFocused('the picked day keeps focus while its month changes');
  });

  test('the selected day is the same in every zone: date mode never converts (9 #3)', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value={{state.value}}
          @onChange={{state.onChange}}
          @openToDate="2026-11-01"
          @timeZone="Pacific/Kiritimati"
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    await click(cell('2026-11-24'));
    assert.deepEqual(state.changes, ['2026-11-24']);
  });

  test('min and max: disabled days, navigation, month options, year range (9 #13, #17)', async function (assert) {
    const state = new State();
    state.value = '2026-03-15';
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value={{state.value}}
          @onChange={{state.onChange}}
          @minDate="2026-03-10"
          @maxDate="2027-02-20"
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert.dom(cell('2026-03-09')).hasClass('react-datepicker__day--disabled');
    assert.dom(day('2026-03-09')).hasAttribute('aria-disabled', 'true');
    assert
      .dom(cell('2026-03-10'))
      .doesNotHaveClass('react-datepicker__day--disabled');
    assert.dom(day('2026-03-10')).doesNotHaveAttribute('aria-disabled');
    await click(cell('2026-03-09'));
    assert.deepEqual(state.changes, [], 'a disabled day: nothing');
    assert
      .dom('.react-datepicker__navigation--previous')
      .isDisabled('February is before the minimum');
    assert.dom('.react-datepicker__navigation--next').isNotDisabled();

    const months = [
      ...document.querySelectorAll<HTMLOptionElement>(
        'select[aria-label="Month"] option'
      )
    ];
    assert.deepEqual(
      months.filter((o) => o.disabled).map((o) => o.value),
      ['0', '1'],
      'January and February 2026 cannot be shown'
    );
    const years = [
      ...document.querySelectorAll<HTMLOptionElement>(
        'select[aria-label="Year"] option'
      )
    ];
    assert.deepEqual(
      years.map((o) => o.value),
      ['2026', '2027'],
      'the year list runs from the minimum to the maximum'
    );

    await fillIn('select[aria-label="Year"]', '2027');
    assert.strictEqual(
      heading(),
      'February 2027',
      'March 2027 is past the maximum: the focus clamps to it (9 #31)'
    );
    assert.dom(day('2027-02-20')).hasAttribute('tabindex', '0');
    assert.dom('.react-datepicker__navigation--next').isDisabled();
    assert.dom(cell('2027-02-21')).hasClass('react-datepicker__day--disabled');
    assert.deepEqual(
      state.changes,
      [],
      'changing the shown month never changes the value'
    );
  });

  test('without limits the year list is 100 years back and 20 forward', async function (assert) {
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value="2026-11-24"
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    const years = [
      ...document.querySelectorAll<HTMLOptionElement>(
        'select[aria-label="Year"] option'
      )
    ];
    assert.strictEqual(years[0]!.value, '1926');
    assert.strictEqual(years.at(-1)!.value, '2046');
  });

  test('excluded, included and filtered days are disabled (9 #12)', async function (assert) {
    const isWorkday = (date: string) => {
      const weekday = new Date(`${date}T00:00:00Z`).getUTCDay();
      return weekday !== 0 && weekday !== 6;
    };
    const seen: unknown[] = [];
    const spy = (date: string) => {
      seen.push(date);
      return isWorkday(date);
    };
    await render(
      <template>
        <div data-p="exclude">
          <EuiDatePicker
            @inline={{true}}
            @value="2026-11-24"
            @excludeDates={{array "2026-11-25" "2026-11-26" "not a date"}}
            @locale="en-US"
            @firstDayOfWeek={{0}}
          />
        </div>
      </template>
    );
    assert.dom(cell('2026-11-25')).hasClass('react-datepicker__day--disabled');
    assert.dom(cell('2026-11-26')).hasClass('react-datepicker__day--disabled');
    assert
      .dom(cell('2026-11-27'))
      .doesNotHaveClass('react-datepicker__day--disabled');

    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value="2026-11-24"
          @includeDates={{array "2026-11-03" "2026-11-24"}}
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert.deepEqual(
      enabledDays(),
      ['2026-11-03', '2026-11-24'],
      'only the included days'
    );

    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value="2026-11-24"
          @filterDate={{spy}}
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert
      .dom(cell('2026-11-28'))
      .hasClass('react-datepicker__day--disabled', 'Saturday refused');
    assert
      .dom(cell('2026-11-27'))
      .doesNotHaveClass('react-datepicker__day--disabled');
    assert.true(
      seen.every(
        (date) => typeof date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(date)
      ),
      'called with YYYY-MM-DD'
    );
  });

  test('@dayClassName adds classes per day, called with YYYY-MM-DD (upstream "Custom classes")', async function (assert) {
    const highlight = (date: string) =>
      date.endsWith('-13') ? 'is-friday-13 extra' : undefined;
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value="2026-11-24"
          @dayClassName={{highlight}}
          @calendarClass="my-calendar"
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert
      .dom(cell('2026-11-13'))
      .hasClass('is-friday-13')
      .hasClass('extra')
      .hasClass('react-datepicker__day');
    assert.dom('.is-friday-13').exists({ count: 1 });
    assert
      .dom('.react-datepicker')
      .hasClass('my-calendar', '@calendarClass on the calendar');
  });

  test('@openToDate opens on its month when there is no value; the value wins (upstream "Open to a specific date")', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value={{state.value}}
          @openToDate="2018-09-12"
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert.strictEqual(heading(), 'September 2018');
    assert.dom('.react-datepicker__day--selected').doesNotExist();
    assert
      .dom(day('2018-09-12'))
      .hasAttribute(
        'tabindex',
        '0',
        'the open-to day holds the tab stop, as upstream preSelection'
      );
    state.value = '2020-02-29';
    await rerender();
    assert.strictEqual(heading(), 'February 2020');
  });

  test('without a value it opens on today, marked, clamped into the limits', async function (assert) {
    const today = todayIn('local', Date.now());
    await render(
      <template>
        <EuiDatePicker @inline={{true}} @locale="en-US" @firstDayOfWeek={{0}} />
      </template>
    );
    assert.dom(cell(today)).hasClass('react-datepicker__day--today');
    assert
      .dom(day(today))
      .hasAttribute('aria-current', 'date')
      .hasAttribute('tabindex', '0');
    assert.dom('.react-datepicker__day--today').exists({ count: 1 });

    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @minDate="9000-05-10"
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert.strictEqual(
      heading(),
      'May 9000',
      'today is before the minimum: the minimum month'
    );
    assert.dom(day('9000-05-10')).hasAttribute('tabindex', '0');
  });

  test('"today" is the day in @timeZone (9 #25)', async function (assert) {
    // 14 hours apart: at most one of the two can be the local day
    const kiritimati = todayIn('Pacific/Kiritimati', Date.now());
    const pagoPago = todayIn('Pacific/Pago_Pago', Date.now());
    assert.notStrictEqual(
      kiritimati,
      pagoPago,
      'the zones are on different days'
    );
    await render(
      <template>
        <div data-p="east"><EuiDatePicker
            @inline={{true}}
            @timeZone="Pacific/Kiritimati"
            @locale="en-US"
            @firstDayOfWeek={{0}}
          /></div>
        <div data-p="west"><EuiDatePicker
            @inline={{true}}
            @timeZone="Pacific/Pago_Pago"
            @locale="en-US"
            @firstDayOfWeek={{0}}
          /></div>
      </template>
    );
    assert
      .dom(`[data-p="east"] td[data-date="${kiritimati}"]`)
      .hasClass('react-datepicker__day--today');
    assert
      .dom(`[data-p="west"] td[data-date="${pagoPago}"]`)
      .hasClass('react-datepicker__day--today');
    assert
      .dom('[data-p="east"] .react-datepicker__day--today')
      .exists({ count: 1 });
  });

  test('locale: names, labels and the first day of the week (9 #32, #33)', async function (assert) {
    await render(
      <template>
        <div data-p="es"><EuiDatePicker
            @inline={{true}}
            @value="2026-11-24"
            @locale="es-MX"
            @firstDayOfWeek={{1}}
          /></div>
        <div data-p="us"><EuiDatePicker
            @inline={{true}}
            @value="2026-11-24"
            @locale="en-US"
          /></div>
      </template>
    );
    const es = el('[data-p="es"]');
    assert.strictEqual(el('h2', es).textContent!.trim(), 'noviembre de 2026');
    assert.strictEqual(
      el<HTMLSelectElement>(
        'select[aria-label="Month"]',
        es
      ).selectedOptions[0]!.textContent!.trim(),
      'noviembre'
    );
    assert
      .dom('td[data-date="2026-11-24"] > button', es)
      .hasAttribute('aria-label', 'martes, 24 de noviembre de 2026');
    assert.strictEqual(
      el('.react-datepicker__day-name', es).getAttribute('abbr'),
      'lunes',
      '@firstDayOfWeek 1: Monday first'
    );
    assert.strictEqual(
      el('.react-datepicker__week td', es).dataset['date'],
      '2026-10-26'
    );

    const us = el('[data-p="us"]');
    assert
      .dom('td[data-date="2026-11-24"] > button', us)
      .hasAttribute('aria-label', 'Tuesday, November 24, 2026');
    assert.strictEqual(
      el('.react-datepicker__day-name', us).getAttribute('abbr'),
      'Sunday',
      'en-US: Sunday first'
    );
  });

  test('an unreadable @value: invalid, nothing selected, opens on today, a development warning (9 #1, #2)', async function (assert) {
    warnings = [];
    const today = todayIn('local', Date.now());
    const asDate = new Date();
    await render(
      <template>
        <div data-p="text"><EuiDatePicker
            @inline={{true}}
            @value="2026-02-31"
            @locale="en-US"
            @firstDayOfWeek={{0}}
          /></div>
      </template>
    );
    assert
      .dom('[data-p="text"] .react-datepicker__day--selected')
      .doesNotExist();
    assert
      .dom(`[data-p="text"] td[data-date="${today}"]`)
      .exists('opens on today');
    assert
      .dom(
        '[data-p="text"] .euiFormControlLayoutIcons [data-icon-type="warning"]'
      )
      .exists('the invalid icon');
    assert.true(
      warnings.some((w) => w.includes('"2026-02-31" is not a YYYY-MM-DD date')),
      warnings.join(' | ')
    );

    warnings = [];
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value={{asDate}}
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert.true(
      warnings.some((w) =>
        w.includes('must be a YYYY-MM-DD string, not a Date or a moment')
      ),
      warnings.join(' | ')
    );
  });

  test('an unknown @timeZone is invalid with a warning, and still renders (9 #24)', async function (assert) {
    warnings = [];
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value="2026-11-24"
          @timeZone="Mars/Olympus"
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert.dom(cell('2026-11-24')).hasClass('react-datepicker__day--selected');
    assert.true(
      warnings.some((w) => w.includes('"Mars/Olympus" is not a time zone')),
      warnings.join(' | ')
    );
  });

  test('@minDate after @maxDate disables every day, with a warning (9 #18); unreadable limits warn', async function (assert) {
    warnings = [];
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value="2026-11-24"
          @minDate="2026-12-01"
          @maxDate="2026-11-01"
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert.deepEqual(enabledDays(), []);
    assert.true(
      warnings.some((w) => w.includes('@minDate is after @maxDate')),
      warnings.join(' | ')
    );

    warnings = [];
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value="2026-11-24"
          @minDate="yesterday"
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert.true(
      warnings.some((w) =>
        w.includes('@minDate "yesterday" is not a YYYY-MM-DD date')
      ),
      warnings.join(' | ')
    );
    assert.strictEqual(
      enabledDays().length,
      35,
      'the unreadable limit is ignored'
    );
  });

  test('@disabled: non-interactive, dimmed, nothing focusable or clickable (9 #39, #41)', async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @disabled={{true}}
          @value={{state.value}}
          @onChange={{state.onChange}}
          @onClear={{state.onChange}}
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    const calendar = el('.react-datepicker');
    assert
      .dom(calendar)
      .hasClass('react-datepicker--non-interactive')
      .hasClass('euiDatePickerCalendar--disabled');
    const focusable = [
      ...calendar.querySelectorAll<HTMLElement>('button, select, [tabindex]')
    ].filter((e) => !(e as HTMLButtonElement).disabled && e.tabIndex >= 0);
    assert.deepEqual(focusable, [], 'nothing focusable');
    assert.dom('select[aria-label="Month"]').isDisabled();
    assert.dom('.react-datepicker__navigation--next').isDisabled();
    day('2026-11-10').click();
    assert.deepEqual(state.changes, []);
    assert
      .dom('.euiFormControlLayoutClearButton')
      .doesNotExist('no clear button');
  });

  test('@readOnly: non-interactive, not dimmed, no clear button (9 #40)', async function (assert) {
    const noop = () => {};
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @readOnly={{true}}
          @value="2026-11-24"
          @onClear={{noop}}
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert
      .dom('.react-datepicker')
      .hasClass('react-datepicker--non-interactive')
      .doesNotHaveClass('euiDatePickerCalendar--disabled');
    assert.dom(day('2026-11-10')).isDisabled();
    assert.dom('select[aria-label="Year"]').isDisabled();
    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();
  });

  test('@onClear shows the clear button below while there is a value; @isLoading the spinner', async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    let cleared = 0;
    const onClear = () => {
      cleared++;
      state.value = null;
    };
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value={{state.value}}
          @onClear={{onClear}}
          @isLoading={{true}}
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    const icons = el(
      '.euiFormControlLayout__childrenWrapper > .react-datepicker + .euiFormControlLayoutIcons'
    );
    assert.strictEqual(
      getComputedStyle(icons).position,
      'static',
      'static icons, after the calendar'
    );
    assert.dom('.euiFormControlLayoutClearButton', icons).exists();
    assert.true(
      el('.euiFormControlLayoutClearButton').getBoundingClientRect().top >=
        el('.react-datepicker').getBoundingClientRect().bottom - 1,
      'below the calendar (upstream: the children wrapper is a column)'
    );
    assert
      .dom('.euiFormControlLayoutIcons .euiBorealisLoadingSpinner')
      .exists();
    await click('.euiFormControlLayoutClearButton');
    assert.strictEqual(cleared, 1);
    assert
      .dom('.euiFormControlLayoutClearButton')
      .doesNotExist('no value, no clear button');
    assert.dom('.react-datepicker__day--selected').doesNotExist();
  });

  test('the calendar follows @value changed from outside, also after navigating (9 #29)', async function (assert) {
    const state = new State();
    state.value = '2026-11-24';
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value={{state.value}}
          @onChange={{state.onChange}}
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    await click('.react-datepicker__navigation--next');
    await click('.react-datepicker__navigation--next');
    assert.strictEqual(heading(), 'January 2027');
    state.value = '2025-06-15';
    await rerender();
    assert.strictEqual(heading(), 'June 2025');
    assert.dom(cell('2025-06-15')).hasClass('react-datepicker__day--selected');
    assert.dom(day('2025-06-15')).hasAttribute('tabindex', '0');
  });

  test('without @onChange nothing throws and the value stays (9 #30)', async function (assert) {
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value="2026-11-24"
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    await click(cell('2026-11-10'));
    assert.dom(cell('2026-11-24')).hasClass('react-datepicker__day--selected');
    assert
      .dom(day('2026-11-10'))
      .hasAttribute('tabindex', '0', 'the tab stop moved to the clicked day');
  });

  test('the selects and the navigation buttons change the month, not the value nor the focus', async function (assert) {
    const state = new State();
    state.value = '2026-01-31';
    await render(
      <template>
        <EuiDatePicker
          @inline={{true}}
          @value={{state.value}}
          @onChange={{state.onChange}}
          @locale="en-US"
          @firstDayOfWeek={{0}}
        />
      </template>
    );
    assert.strictEqual(
      document.activeElement,
      document.body,
      'rendering takes no focus'
    );
    assert.dom('select[aria-label="Month"]').hasValue('0', 'January is 0');

    const month = el<HTMLSelectElement>('select[aria-label="Month"]');
    month.focus();
    await fillIn(month, '1');
    assert.strictEqual(heading(), 'February 2026');
    assert
      .dom(day('2026-02-28'))
      .hasAttribute('tabindex', '0', '31 January in February: the 28th');
    assert.dom(month).isFocused('the select keeps focus');

    await fillIn('select[aria-label="Year"]', '2028');
    assert.strictEqual(heading(), 'February 2028');
    assert.dom(day('2028-02-28')).hasAttribute('tabindex', '0');

    const next = el<HTMLButtonElement>('.react-datepicker__navigation--next');
    next.focus();
    await click(next);
    assert.strictEqual(heading(), 'March 2028');
    assert.dom(next).isFocused('the button keeps focus');
    await click('.react-datepicker__navigation--previous');
    await click('.react-datepicker__navigation--previous');
    assert.strictEqual(heading(), 'January 2028');
    assert.deepEqual(state.changes, []);
  });

  test('@shadow: raised frame by default, flat with @shadow={{false}}', async function (assert) {
    await render(
      <template>
        <div data-p="shadow"><EuiDatePicker
            @inline={{true}}
            @value="2026-11-24"
            @locale="en-US"
            @firstDayOfWeek={{0}}
          /></div>
        <div data-p="flat"><EuiDatePicker
            @inline={{true}}
            @shadow={{false}}
            @value="2026-11-24"
            @locale="en-US"
            @firstDayOfWeek={{0}}
          /></div>
      </template>
    );
    const shadow = getComputedStyle(
      el('[data-p="shadow"] .euiFormControlLayout')
    );
    const flat = getComputedStyle(el('[data-p="flat"] .euiFormControlLayout'));
    assert.notStrictEqual(shadow.boxShadow, 'none', 'shadow');
    assert.strictEqual(
      flat.backgroundColor,
      'rgba(0, 0, 0, 0)',
      'no shadow: transparent'
    );
  });
});
