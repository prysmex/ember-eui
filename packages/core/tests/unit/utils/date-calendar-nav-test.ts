/**
 * The calendar's rules (DESIGN 7.1 to 7.3): every key of 7.2, the limits,
 * disabled days, RTL, month navigation, the year list, the tab stop.
 */
import { module, test } from 'qunit';

import {
  clampDate,
  dayLimits,
  dayProblem,
  focusInMonth,
  isDayDisabled,
  isUnreadableLimit,
  limitDay,
  limitInstant,
  limitsConflict,
  monthNavigation,
  nextFocusedDate,
  openingDate,
  tabStopDate,
  yearRange
} from '#src/utils/date/calendar-nav.ts';

import type { NavigationOptions } from '#src/utils/date/calendar-nav.ts';

const MONDAY: NavigationOptions = { firstDayOfWeek: 1 };
const NO_LIMITS = { min: null, max: null };
const iso = (ms: number | null) =>
  ms === null ? null : new Date(ms).toISOString();

function key(
  focused: string,
  name: string,
  options: Partial<NavigationOptions> = {}
) {
  return nextFocusedDate(focused, name, { ...MONDAY, ...options });
}

module('Unit | utils | date | calendar-nav', function () {
  test('every key of 7.2 (Tuesday 24 November 2026, weeks from Monday)', function (assert) {
    const day = '2026-11-24';
    assert.strictEqual(key(day, 'ArrowLeft'), '2026-11-23');
    assert.strictEqual(key(day, 'ArrowRight'), '2026-11-25');
    assert.strictEqual(key(day, 'ArrowUp'), '2026-11-17');
    assert.strictEqual(key(day, 'ArrowDown'), '2026-12-01');
    assert.strictEqual(
      key(day, 'Home'),
      '2026-11-23',
      'the first day of the week'
    );
    assert.strictEqual(
      key(day, 'End'),
      '2026-11-29',
      'the last day of the week'
    );
    assert.strictEqual(
      key(day, 'Home', { firstDayOfWeek: 0 }),
      '2026-11-22',
      'from Sunday'
    );
    assert.strictEqual(key(day, 'End', { firstDayOfWeek: 0 }), '2026-11-28');
    assert.strictEqual(key(day, 'PageUp'), '2026-10-24');
    assert.strictEqual(key(day, 'PageDown'), '2026-12-24');
    assert.strictEqual(
      key(day, 'PageUp', { shiftKey: true }),
      '2025-11-24',
      'a year'
    );
    assert.strictEqual(key(day, 'PageDown', { shiftKey: true }), '2027-11-24');
    for (const other of ['Enter', ' ', 'Escape', 'Tab', 'a', 'Shift']) {
      assert.strictEqual(
        key(day, other),
        null,
        `"${other}" does not move focus`
      );
    }
  });

  test('months and years clamp the day (9 #15, #16)', function (assert) {
    assert.strictEqual(key('2026-01-31', 'PageDown'), '2026-02-28');
    assert.strictEqual(key('2028-01-31', 'PageDown'), '2028-02-29');
    assert.strictEqual(key('2026-03-31', 'PageUp'), '2026-02-28');
    assert.strictEqual(
      key('2028-02-29', 'PageDown', { shiftKey: true }),
      '2029-02-28'
    );
    assert.strictEqual(
      key('2028-02-29', 'PageUp', { shiftKey: true }),
      '2027-02-28'
    );
    assert.strictEqual(key('2026-12-31', 'ArrowRight'), '2027-01-01');
  });

  test('RTL swaps ArrowLeft and ArrowRight only (9 #35)', function (assert) {
    const day = '2026-11-24';
    assert.strictEqual(
      key(day, 'ArrowLeft', { rtl: true }),
      '2026-11-25',
      'left is the next day'
    );
    assert.strictEqual(key(day, 'ArrowRight', { rtl: true }), '2026-11-23');
    assert.strictEqual(key(day, 'ArrowUp', { rtl: true }), '2026-11-17');
    assert.strictEqual(key(day, 'Home', { rtl: true }), '2026-11-23');
  });

  test('moving past a limit stops at it; onto a disabled day is allowed (9 #14, #17)', function (assert) {
    const limits = dayLimits({
      minDate: '2026-11-10',
      maxDate: '2026-12-05',
      excludeDates: ['2026-11-25']
    });
    const options = { limits };
    assert.strictEqual(
      key('2026-11-24', 'PageDown', options),
      '2026-12-05',
      'stops on @maxDate'
    );
    assert.strictEqual(
      key('2026-11-24', 'PageUp', options),
      '2026-11-10',
      'stops on @minDate'
    );
    assert.strictEqual(key('2026-12-01', 'ArrowDown', options), '2026-12-05');
    assert.strictEqual(
      key('2026-11-12', 'Home', { ...options, firstDayOfWeek: 0 }),
      '2026-11-10'
    );
    assert.strictEqual(
      key('2026-11-24', 'ArrowRight', options),
      '2026-11-25',
      'onto an excluded day'
    );
    assert.true(isDayDisabled('2026-11-25', limits), 'which is disabled');
    assert.false(
      monthNavigation(2026, 12, limits).next,
      'the next-month button is disabled'
    );
  });

  test('the edges of the supported years', function (assert) {
    assert.strictEqual(key('0001-01-01', 'ArrowLeft'), '0001-01-01');
    assert.strictEqual(key('0001-01-03', 'ArrowUp'), '0001-01-01');
    assert.strictEqual(key('9999-12-31', 'ArrowRight'), '9999-12-31');
    assert.strictEqual(
      key('9999-12-30', 'End'),
      '9999-12-31',
      'the week runs into 10000'
    );
    assert.strictEqual(
      key('9999-06-15', 'PageDown', { shiftKey: true }),
      '9999-12-31'
    );
    assert.deepEqual(monthNavigation(1, 1, NO_LIMITS), {
      previous: false,
      next: true
    });
    assert.deepEqual(monthNavigation(9999, 12, NO_LIMITS), {
      previous: true,
      next: false
    });
  });

  test('disabled days: min, max, excluded, included, filtered (9 #11, #12, #13)', function (assert) {
    const limits = dayLimits({
      minDate: '2026-11-02',
      maxDate: '2026-11-27',
      excludeDates: ['2026-11-11', 'not a date'],
      filterDate: (date) => !date.endsWith('-13')
    });
    assert.strictEqual(dayProblem('2026-11-01', limits), 'min');
    assert.strictEqual(
      dayProblem('2026-11-02', limits),
      null,
      'min is inclusive'
    );
    assert.strictEqual(
      dayProblem('2026-11-27', limits),
      null,
      'max is inclusive'
    );
    assert.strictEqual(dayProblem('2026-11-28', limits), 'max');
    assert.strictEqual(
      dayProblem('2026-11-11', limits),
      'disabled',
      'excluded'
    );
    assert.strictEqual(
      dayProblem('2026-11-13', limits),
      'disabled',
      'filtered'
    );
    assert.strictEqual(dayProblem('2026-11-24', limits), null);

    const only = dayLimits({ includeDates: ['2026-11-24', '2026-11-26'] });
    assert.strictEqual(dayProblem('2026-11-24', only), null);
    assert.strictEqual(
      dayProblem('2026-11-25', only),
      'disabled',
      'not included'
    );
    assert.false(isDayDisabled('2026-11-26', only));

    const none = dayLimits();
    assert.strictEqual(dayProblem('0001-01-01', none), null);
    assert.false(limitsConflict(none));
  });

  test('@minDate after @maxDate disables every day (9 #18)', function (assert) {
    const limits = dayLimits({ minDate: '2026-12-01', maxDate: '2026-11-01' });
    assert.true(limitsConflict(limits));
    for (const day of [
      '2026-10-15',
      '2026-11-01',
      '2026-11-15',
      '2026-12-01',
      '2026-12-15'
    ]) {
      assert.true(isDayDisabled(day, limits), day);
    }
    assert.strictEqual(
      clampDate('2026-11-15', limits),
      '2026-12-01',
      'min wins the clamp'
    );
  });

  test('instant limits count by their day in the zone (DESIGN 5.2)', function (assert) {
    // 02:00Z on 25 November is still 24 November in Mexico City (UTC-6)
    const zone = 'America/Mexico_City';
    const max = '2026-11-25T02:00:00.000Z';
    assert.strictEqual(limitDay(max, zone), '2026-11-24');
    assert.strictEqual(limitDay(max, 'utc'), '2026-11-25');
    assert.strictEqual(
      limitDay('2026-11-24', zone),
      '2026-11-24',
      'a date is itself'
    );
    assert.strictEqual(limitDay('soon', zone), null, 'unreadable: no limit');
    assert.strictEqual(limitDay(undefined), null);
    const limits = dayLimits(
      { minDate: '2026-11-20T12:00:00Z', maxDate: max },
      zone
    );
    assert.strictEqual(
      dayProblem('2026-11-20', limits),
      null,
      'a day with an allowed hour is enabled'
    );
    assert.strictEqual(dayProblem('2026-11-19', limits), 'min');
    assert.strictEqual(
      dayProblem('2026-11-25', limits),
      'max',
      'no wall hour of 25 November is allowed'
    );

    assert.strictEqual(
      iso(limitInstant('2026-11-24', zone, 'min')),
      '2026-11-24T06:00:00.000Z'
    );
    assert.strictEqual(
      iso(limitInstant('2026-11-24', zone, 'max')),
      '2026-11-25T05:59:59.999Z'
    );
    assert.strictEqual(iso(limitInstant(max, zone, 'max')), max);
    assert.strictEqual(limitInstant('9999-12-31', 'utc', 'max'), Infinity);
    assert.strictEqual(limitInstant(null, 'utc', 'min'), null);
    assert.true(isUnreadableLimit('next week'));
    assert.true(isUnreadableLimit('2026-02-31'));
    assert.false(isUnreadableLimit('2026-11-24'));
    assert.false(isUnreadableLimit(max));
    assert.false(isUnreadableLimit(undefined));
    assert.false(isUnreadableLimit(''));
  });

  test('month navigation is disabled when the whole month is outside', function (assert) {
    const limits = dayLimits({ minDate: '2026-10-31', maxDate: '2026-12-01' });
    assert.deepEqual(
      monthNavigation(2026, 11, limits),
      { previous: true, next: true },
      'one day each side'
    );
    assert.deepEqual(monthNavigation(2026, 10, limits), {
      previous: false,
      next: true
    });
    assert.deepEqual(monthNavigation(2026, 12, limits), {
      previous: true,
      next: false
    });
    assert.deepEqual(monthNavigation(2026, 1, NO_LIMITS), {
      previous: true,
      next: true
    });
  });

  test('the year list (DESIGN 7.3)', function (assert) {
    assert.deepEqual(yearRange(2026, NO_LIMITS), { from: 1926, to: 2046 });
    assert.deepEqual(
      yearRange(
        2026,
        dayLimits({ minDate: '2020-05-01', maxDate: '2030-01-01' })
      ),
      { from: 2020, to: 2030 }
    );
    assert.deepEqual(yearRange(2026, dayLimits({ minDate: '2020-05-01' })), {
      from: 2020,
      to: 2046
    });
    assert.deepEqual(
      yearRange(50, NO_LIMITS),
      { from: 1, to: 70 },
      'not before 0001'
    );
    assert.deepEqual(yearRange(9990, NO_LIMITS), { from: 9890, to: 9999 });
    assert.deepEqual(
      yearRange(2035, dayLimits({ maxDate: '2030-01-01' })),
      { from: 1935, to: 2035 },
      'the shown year is always in'
    );
  });

  test('the select moves the focus into the new month, clamped (9 #31)', function (assert) {
    assert.strictEqual(
      focusInMonth('2026-03-31', 2026, 2, NO_LIMITS),
      '2026-02-28'
    );
    assert.strictEqual(
      focusInMonth('2026-11-24', 2030, 11, NO_LIMITS),
      '2030-11-24'
    );
    const limits = dayLimits({ minDate: '2025-06-10', maxDate: '2027-02-15' });
    assert.strictEqual(
      focusInMonth('2026-11-24', 2027, 2, limits),
      '2027-02-15',
      'clamped to @maxDate'
    );
    assert.strictEqual(
      focusInMonth('2026-11-05', 2025, 6, limits),
      '2025-06-10',
      'clamped to @minDate'
    );
  });

  test('the tab stop: focused, else selected, else today, else the first enabled day (DESIGN 7.1)', function (assert) {
    const base = { year: 2026, month: 11 };
    assert.strictEqual(
      tabStopDate({
        ...base,
        focused: '2026-11-10',
        selected: '2026-11-20',
        today: '2026-11-24'
      }),
      '2026-11-10'
    );
    assert.strictEqual(
      tabStopDate({ ...base, selected: '2026-11-20', today: '2026-11-24' }),
      '2026-11-20'
    );
    assert.strictEqual(
      tabStopDate({ ...base, selected: '2026-12-20', today: '2026-11-24' }),
      '2026-11-24',
      'the selected day is in another month'
    );
    assert.strictEqual(
      tabStopDate({ ...base, selected: 'bad', today: '2026-10-24' }),
      '2026-11-01'
    );
    const limits = dayLimits({
      minDate: '2026-11-05',
      filterDate: (date) => date !== '2026-11-05'
    });
    assert.strictEqual(
      tabStopDate({ ...base, limits }),
      '2026-11-06',
      'the first enabled day'
    );
    const closed = dayLimits({ maxDate: '2026-10-01' });
    assert.strictEqual(
      tabStopDate({ ...base, limits: closed }),
      '2026-11-01',
      'none enabled: the 1st'
    );
  });

  test('the calendar opens on the value, else @openToDate, else today (9 #1)', function (assert) {
    assert.strictEqual(
      openingDate('2026-03-04', '2027-01-01', '2026-11-24'),
      '2026-03-04'
    );
    assert.strictEqual(
      openingDate(null, '2027-01-01', '2026-11-24'),
      '2027-01-01'
    );
    assert.strictEqual(
      openingDate('2026-02-31', undefined, '2026-11-24'),
      '2026-11-24',
      'an invalid value'
    );
    assert.strictEqual(
      openingDate('yesterday', 'never', '2026-11-24'),
      '2026-11-24'
    );
  });
});
