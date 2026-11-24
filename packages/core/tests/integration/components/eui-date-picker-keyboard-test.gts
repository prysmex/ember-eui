import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  focus,
  render,
  triggerKeyEvent
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiDatePicker from '#src/components/eui-date-picker.gts';
import EuiDatePickerCalendar from '#src/components/eui-date-picker/calendar.gts';
import { utcMidnight } from '#src/utils/date/calendar-date.ts';

function el<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const cell = (date: string) => el(`td[data-date="${date}"]`);
const day = (date: string) =>
  el<HTMLButtonElement>(`td[data-date="${date}"] > button`);
const heading = () => el('.react-datepicker h2').textContent!.trim();
/** The date of the focused day button. */
const focusedDate = () =>
  (document.activeElement as HTMLElement | null)?.closest<HTMLElement>(
    'td[data-date]'
  )?.dataset['date'];
const tabStops = () =>
  [
    ...document.querySelectorAll<HTMLElement>(
      'td[data-date] > button[tabindex="0"]'
    )
  ].map((b) => b.parentElement!.dataset['date']);

/** Press a key on the focused day; returns whether the picker took it (preventDefault). */
async function press(
  key: string,
  options: { shiftKey?: boolean; ctrlKey?: boolean } = {}
) {
  const target = document.activeElement as HTMLElement;
  let prevented: boolean | undefined;
  const listener = (event: Event) => (prevented = event.defaultPrevented);
  // after the grid's own handler (bubble phase, on the document)
  document.addEventListener('keydown', listener);
  await triggerKeyEvent(target, 'keydown', key, options);
  document.removeEventListener('keydown', listener);
  return prevented;
}

class State {
  @tracked value: string | null = null;
  changes: (string | null)[] = [];
  onChange = (value: string | null) => {
    this.changes.push(value);
    this.value = value;
  };
}

module(
  'Integration | Component | eui-date-picker | keyboard and aria',
  function (hooks) {
    setupRenderingTest(hooks);

    test('roles and names: the WAI-ARIA grid, columns, cells, buttons, the live month name', async function (assert) {
      await render(
        <template>
          <EuiDatePicker
            @inline={{true}}
            @value="2026-11-24"
            @minDate="2026-11-05"
            @locale="en-US"
            @firstDayOfWeek={{0}}
          />
        </template>
      );
      const grid = el('table.react-datepicker__month');
      assert.dom(grid).hasAttribute('role', 'grid');
      const name = el(`#${grid.getAttribute('aria-labelledby')}`);
      assert.strictEqual(name.tagName, 'H2');
      assert
        .dom(name)
        .hasText('November 2026')
        .hasAttribute('aria-live', 'polite');
      assert.dom(name).hasClass('euiScreenReaderOnly', 'visually hidden');
      assert.dom('thead', grid).hasAttribute('role', 'rowgroup');
      assert.dom('tbody', grid).hasAttribute('role', 'rowgroup');
      assert.dom('tr', grid).hasAttribute('role', 'row');

      const headers = [...grid.querySelectorAll('th')];
      assert.strictEqual(headers.length, 7);
      assert
        .dom(headers[2])
        .hasAttribute('role', 'columnheader')
        .hasAttribute('scope', 'col')
        .hasAttribute('abbr', 'Tuesday');
      assert.dom('[aria-hidden="true"]', headers[2]).hasText('Tue');
      assert.dom('.euiScreenReaderOnly', headers[2]).hasText('Tuesday');

      assert
        .dom(cell('2026-11-24'))
        .hasAttribute('role', 'gridcell')
        .hasAttribute('aria-selected', 'true');
      assert.dom(cell('2026-11-23')).doesNotHaveAttribute('aria-selected');
      assert
        .dom(day('2026-11-24'))
        .hasAttribute('type', 'button')
        .hasAttribute('aria-label', 'Tuesday, November 24, 2026')
        .hasText('24');
      assert
        .dom(day('2026-11-04'))
        .hasAttribute(
          'aria-disabled',
          'true',
          'disabled days stay focusable, marked'
        );
      assert.dom(day('2026-11-04')).isNotDisabled();
      assert.deepEqual(
        tabStops(),
        ['2026-11-24'],
        'one tab stop: the selected day'
      );
    });

    test('the tab stop: selected, else today, else the first enabled day', async function (assert) {
      const now = () => utcMidnight(2026, 11, 20) + 12 * 3_600_000;
      await render(
        <template>
          <div data-p="today"><EuiDatePickerCalendar
              @locale="en-US"
              @firstDayOfWeek={{0}}
              @timeZone="utc"
              @now={{now}}
            /></div>
        </template>
      );
      assert
        .dom('[data-p="today"] td[data-date="2026-11-20"]')
        .hasClass('react-datepicker__day--today');
      assert.deepEqual(tabStops(), ['2026-11-20']);

      await render(
        <template>
          <EuiDatePickerCalendar
            @locale="en-US"
            @firstDayOfWeek={{0}}
            @timeZone="utc"
            @now={{now}}
            @openToDate="2026-12-01"
            @minDate="2026-12-03"
          />
        </template>
      );
      assert.deepEqual(
        tabStops(),
        ['2026-12-03'],
        'the open-to day is disabled: the first enabled day'
      );
    });

    test('every key of DESIGN 7.2 moves the focused day', async function (assert) {
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
      await focus(day('2026-11-24'));

      assert.true(await press('ArrowRight'), 'ArrowRight is taken');
      assert.strictEqual(focusedDate(), '2026-11-25');
      await press('ArrowLeft');
      await press('ArrowLeft');
      assert.strictEqual(focusedDate(), '2026-11-23');
      await press('ArrowDown');
      assert.strictEqual(focusedDate(), '2026-11-30');
      await press('ArrowUp');
      assert.strictEqual(focusedDate(), '2026-11-23');
      await press('Home');
      assert.strictEqual(
        focusedDate(),
        '2026-11-22',
        'Home: first day of the week (Sunday)'
      );
      await press('End');
      assert.strictEqual(
        focusedDate(),
        '2026-11-28',
        'End: last day of the week'
      );
      assert.deepEqual(
        tabStops(),
        ['2026-11-28'],
        'the tab stop follows the focus'
      );

      await press('PageDown');
      assert.strictEqual(focusedDate(), '2026-12-28');
      assert.strictEqual(heading(), 'December 2026', 'the month follows');
      await press('PageUp');
      await press('PageUp');
      assert.strictEqual(focusedDate(), '2026-10-28');
      await press('PageDown', { shiftKey: true });
      assert.strictEqual(focusedDate(), '2027-10-28', 'Shift+PageDown: a year');
      await press('PageUp', { shiftKey: true });
      assert.strictEqual(focusedDate(), '2026-10-28');
      assert.dom('select[aria-label="Year"]').hasValue('2026');

      await press('ArrowDown');
      await press('ArrowDown');
      await press('ArrowDown');
      await press('ArrowDown');
      assert.strictEqual(
        focusedDate(),
        '2026-11-25',
        'arrows cross into the next month'
      );
      assert.strictEqual(heading(), 'November 2026');
      assert.deepEqual(
        state.changes,
        [],
        'moving never changes the value (@adjustDateOnChange false)'
      );
    });

    test('Home and End follow @firstDayOfWeek', async function (assert) {
      await render(
        <template>
          <EuiDatePicker
            @inline={{true}}
            @value="2026-11-24"
            @locale="en-GB"
            @firstDayOfWeek={{1}}
          />
        </template>
      );
      await focus(day('2026-11-24'));
      await press('Home');
      assert.strictEqual(focusedDate(), '2026-11-23', 'Monday');
      await press('End');
      assert.strictEqual(focusedDate(), '2026-11-29', 'Sunday');
    });

    test('PageDown clamps the day; Shift+PageDown from 29 February (9 #15, #16)', async function (assert) {
      const state = new State();
      state.value = '2026-01-31';
      await render(
        <template>
          <EuiDatePicker
            @inline={{true}}
            @value={{state.value}}
            @locale="en-US"
            @firstDayOfWeek={{0}}
          />
        </template>
      );
      await focus(day('2026-01-31'));
      await press('PageDown');
      assert.strictEqual(focusedDate(), '2026-02-28');

      state.value = '2028-02-29';
      await render(
        <template>
          <EuiDatePicker
            @inline={{true}}
            @value={{state.value}}
            @locale="en-US"
            @firstDayOfWeek={{0}}
          />
        </template>
      );
      await focus(day('2028-02-29'));
      await press('PageDown', { shiftKey: true });
      assert.strictEqual(focusedDate(), '2029-02-28');
    });

    test('moving past @minDate or @maxDate stops at the limit (9 #17)', async function (assert) {
      await render(
        <template>
          <EuiDatePicker
            @inline={{true}}
            @value="2026-11-24"
            @minDate="2026-11-20"
            @maxDate="2026-12-10"
            @locale="en-US"
            @firstDayOfWeek={{0}}
          />
        </template>
      );
      await focus(day('2026-11-24'));
      await press('PageDown');
      assert.strictEqual(focusedDate(), '2026-12-10', 'stops on the maximum');
      assert.dom('.react-datepicker__navigation--next').isDisabled();
      await press('ArrowRight');
      assert.strictEqual(focusedDate(), '2026-12-10');
      await press('PageUp', { shiftKey: true });
      assert.strictEqual(focusedDate(), '2026-11-20', 'stops on the minimum');
    });

    test('a disabled day can be focused, not selected (9 #14); Enter and Space are left to the button', async function (assert) {
      const state = new State();
      state.value = '2026-11-24';
      const noWeekends = (date: string) =>
        ![0, 6].includes(new Date(`${date}T00:00:00Z`).getUTCDay());
      await render(
        <template>
          <EuiDatePicker
            @inline={{true}}
            @value={{state.value}}
            @onChange={{state.onChange}}
            @filterDate={{noWeekends}}
            @locale="en-US"
            @firstDayOfWeek={{0}}
          />
        </template>
      );
      await focus(day('2026-11-27'));
      await press('ArrowRight');
      assert.strictEqual(focusedDate(), '2026-11-28', 'onto a Saturday');
      assert.dom(day('2026-11-28')).hasAttribute('aria-disabled', 'true');
      assert.false(
        await press('Enter'),
        'Enter is not prevented: the button activates natively'
      );
      assert.false(await press(' '), 'nor Space');
      // the native activation of the button (a click with detail 0)
      day('2026-11-28').click();
      assert.deepEqual(state.changes, [], 'refused');

      await press('ArrowLeft');
      day('2026-11-27').click();
      assert.deepEqual(
        state.changes,
        ['2026-11-27'],
        'an enabled day is selected'
      );
      await new Promise((resolve) => setTimeout(resolve, 0));
      assert.strictEqual(
        focusedDate(),
        '2026-11-27',
        'focus stays on the selected day'
      );
    });

    test('selecting a day of the next month by keyboard keeps focus on it', async function (assert) {
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
      await focus(day('2026-11-24'));
      await press('ArrowDown');
      await press('ArrowDown');
      assert.strictEqual(focusedDate(), '2026-12-08');
      await click(day('2026-12-08'));
      assert.deepEqual(state.changes, ['2026-12-08']);
      assert.strictEqual(focusedDate(), '2026-12-08');
      assert.deepEqual(tabStops(), ['2026-12-08']);
    });

    test('RTL: ArrowLeft goes to the next day (9 #35)', async function (assert) {
      await render(
        <template>
          <div dir="rtl">
            <EuiDatePicker
              @inline={{true}}
              @value="2026-11-24"
              @locale="ar"
              @firstDayOfWeek={{6}}
            />
          </div>
        </template>
      );
      await focus(day('2026-11-24'));
      await press('ArrowLeft');
      assert.strictEqual(focusedDate(), '2026-11-25');
      await press('ArrowRight');
      await press('ArrowRight');
      assert.strictEqual(focusedDate(), '2026-11-23');
      const cells = [
        ...document.querySelectorAll<HTMLElement>(
          '.react-datepicker__week:first-child td'
        )
      ];
      assert.true(
        cells[0]!.getBoundingClientRect().left >
          cells[1]!.getBoundingClientRect().left,
        'the week mirrors: the first day is on the right'
      );
    });

    test('keys it does not handle are left alone: Tab, Escape, modified arrows', async function (assert) {
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
      await focus(day('2026-11-24'));
      assert.false(await press('Tab'));
      assert.false(await press('Escape'));
      assert.false(await press('ArrowRight', { ctrlKey: true }));
      assert.strictEqual(focusedDate(), '2026-11-24');
    });

    test('a disabled or read-only calendar takes no keys', async function (assert) {
      await render(
        <template>
          <EuiDatePicker
            @inline={{true}}
            @value="2026-11-24"
            @readOnly={{true}}
            @locale="en-US"
            @firstDayOfWeek={{0}}
          />
        </template>
      );
      const grid = el('table');
      await triggerKeyEvent(grid, 'keydown', 'ArrowRight');
      assert.deepEqual(tabStops(), ['2026-11-24']);
    });

    test('the month name is announced: the live heading follows navigation', async function (assert) {
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
      const live = el('h2[aria-live="polite"]');
      await click('.react-datepicker__navigation--next');
      assert.dom(live).hasText('December 2026', 'the same element, new text');
      await fillIn('select[aria-label="Year"]', '2030');
      assert.dom(live).hasText('December 2030');
    });

    test('"today" is read again when the month changes (9 #26)', async function (assert) {
      let now = utcMidnight(2026, 11, 30) + 23 * 3_600_000;
      const clock = () => now;
      await render(
        <template>
          <EuiDatePickerCalendar
            @locale="en-US"
            @firstDayOfWeek={{0}}
            @timeZone="utc"
            @now={{clock}}
          />
        </template>
      );
      assert.dom(cell('2026-11-30')).hasClass('react-datepicker__day--today');
      now += 2 * 3_600_000; // past midnight: 1 December
      await click('.react-datepicker__navigation--next');
      assert
        .dom(cell('2026-12-01'))
        .hasClass(
          'react-datepicker__day--today',
          'the new day after the month change'
        );
      assert.dom('.react-datepicker__day--today').exists({ count: 1 });
    });

    test('the calendar alone: @onSelect gets the day and the event; nothing for the selected day', async function (assert) {
      const picked: [string, string][] = [];
      const onSelect = (date: string, event: Event) =>
        picked.push([date, event.type]);
      await render(
        <template>
          <EuiDatePickerCalendar
            @selected="2026-11-24"
            @onSelect={{onSelect}}
            @locale="en-US"
            @firstDayOfWeek={{0}}
          />
        </template>
      );
      await click(cell('2026-11-24'));
      await click(cell('2026-11-02'));
      assert.deepEqual(picked, [['2026-11-02', 'click']]);
    });
  }
);
