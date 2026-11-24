import { module, test } from 'qunit';

import {
  addDays,
  addMonths,
  addMonthsTo,
  addYears,
  compareDates,
  daysBetween,
  daysInMonth,
  endOfWeek,
  inMonth,
  isLeapYear,
  isRealDate,
  isoDateOf,
  maxDate,
  minDate,
  monthBounds,
  parseIsoDate,
  startOfWeek,
  utcMidnight,
  validIsoDate,
  weekdayOf,
  weeksOfMonth,
  withYearMonth
} from '#src/utils/date/calendar-date.ts';

import type { Weekday } from '#src/utils/date/calendar-date.ts';

module('Unit | utils | date | calendar-date', function () {
  test('validity: real dates only, no rollover, years 0001 to 9999', function (assert) {
    assert.true(isRealDate(2026, 11, 24));
    assert.false(isRealDate(2026, 2, 31), '31 February does not roll over');
    assert.false(isRealDate(2026, 13, 1), 'month 13');
    assert.false(isRealDate(2026, 0, 1), 'month 0');
    assert.false(isRealDate(2026, 4, 31), '31 April');
    assert.false(isRealDate(2026, 1, 0), 'day 0');
    assert.false(isRealDate(0, 1, 1), 'year 0');
    assert.false(isRealDate(10000, 1, 1), 'year 10000');
    assert.false(isRealDate(2026.5, 1, 1), 'not an integer');
    assert.true(isRealDate(1, 1, 1), 'year 0001');
    assert.true(isRealDate(9999, 12, 31), 'year 9999');
    assert.true(isRealDate(50, 6, 15), 'year 0050 is not 1950');

    assert.strictEqual(isoDateOf(2026, 11, 24), '2026-11-24');
    assert.strictEqual(isoDateOf(1, 1, 1), '0001-01-01', 'padded to four');
    assert.strictEqual(isoDateOf(2026, 2, 29), null);

    assert.deepEqual(parseIsoDate('2026-11-24'), {
      year: 2026,
      month: 11,
      day: 24
    });
    assert.deepEqual(parseIsoDate('0050-06-15'), {
      year: 50,
      month: 6,
      day: 15
    });
    for (const bad of [
      '2026-02-31',
      '2026-13-01',
      '0000-01-01',
      '2026-1-5',
      '26-11-24',
      '2026-11-24T00:00:00Z',
      ' 2026-11-24',
      'yesterday',
      ''
    ]) {
      assert.strictEqual(parseIsoDate(bad), null, `"${bad}" is not a date`);
    }
    for (const notAString of [null, undefined, 20261124, new Date(0), {}]) {
      assert.strictEqual(parseIsoDate(notAString), null, 'not a string');
    }
    assert.strictEqual(validIsoDate('2026-11-24'), '2026-11-24');
    assert.strictEqual(validIsoDate('2026-02-31'), null);
  });

  test('leap years and month lengths', function (assert) {
    assert.true(isLeapYear(2028));
    assert.true(isLeapYear(2000), 'divisible by 400');
    assert.false(isLeapYear(1900), 'divisible by 100');
    assert.false(isLeapYear(2026));
    assert.strictEqual(daysInMonth(2028, 2), 29);
    assert.strictEqual(daysInMonth(2026, 2), 28);
    assert.strictEqual(daysInMonth(1900, 2), 28);
    assert.strictEqual(daysInMonth(2026, 4), 30);
    assert.strictEqual(daysInMonth(2026, 12), 31);
    assert.true(isRealDate(2028, 2, 29));
    assert.false(isRealDate(2027, 2, 29), '29/02/2027');
  });

  test('day arithmetic goes through UTC: no DST, across months and years', function (assert) {
    assert.strictEqual(addDays('2026-11-24', 1), '2026-11-25');
    assert.strictEqual(addDays('2026-11-30', 1), '2026-12-01');
    assert.strictEqual(addDays('2026-12-31', 1), '2027-01-01');
    assert.strictEqual(addDays('2026-03-01', -1), '2026-02-28');
    assert.strictEqual(addDays('2028-03-01', -1), '2028-02-29');
    assert.strictEqual(
      addDays('2026-03-07', 1),
      '2026-03-08',
      'a DST day elsewhere is an ordinary day'
    );
    assert.strictEqual(addDays('2026-11-24', 365), '2027-11-24');
    assert.strictEqual(addDays('0001-01-01', -1), null, 'before 0001');
    assert.strictEqual(addDays('9999-12-31', 1), null, 'after 9999');
    assert.strictEqual(addDays('0099-12-31', 1), '0100-01-01');
    assert.strictEqual(daysBetween('2026-11-24', '2026-12-24'), 30);
    assert.strictEqual(daysBetween('2026-12-24', '2026-11-24'), -30);
    assert.strictEqual(daysBetween('2026-03-01', '2026-04-01'), 31);
    assert.throws(() => addDays('2026-02-31', 1), TypeError, 'invalid input');
  });

  test('months and years clamp the day', function (assert) {
    assert.strictEqual(addMonths('2026-01-31', 1), '2026-02-28', '9 #15');
    assert.strictEqual(addMonths('2028-01-31', 1), '2028-02-29', 'leap');
    assert.strictEqual(addMonths('2026-03-31', -1), '2026-02-28');
    assert.strictEqual(addMonths('2026-05-31', 1), '2026-06-30');
    assert.strictEqual(addMonths('2026-12-15', 1), '2027-01-15');
    assert.strictEqual(addMonths('2026-01-15', -1), '2025-12-15');
    assert.strictEqual(addMonths('2026-11-24', -23), '2024-12-24');
    assert.strictEqual(addMonths('2026-11-24', 26), '2029-01-24');
    assert.strictEqual(addYears('2028-02-29', 1), '2029-02-28', '9 #16');
    assert.strictEqual(addYears('2028-02-29', 4), '2032-02-29');
    assert.strictEqual(addYears('2026-11-24', -1), '2025-11-24');
    assert.strictEqual(addMonths('0001-01-15', -1), null, 'before 0001');
    assert.strictEqual(addYears('9999-06-01', 1), null, 'after 9999');
    assert.deepEqual(addMonthsTo(2026, 12, 1), { year: 2027, month: 1 });
    assert.deepEqual(addMonthsTo(2026, 1, -1), { year: 2025, month: 12 });
    assert.deepEqual(addMonthsTo(2026, 1, -13), { year: 2024, month: 12 });
    assert.strictEqual(withYearMonth('2026-03-31', 2026, 2), '2026-02-28');
    assert.strictEqual(withYearMonth('2026-03-31', 2028, 2), '2028-02-29');
    assert.strictEqual(withYearMonth('2026-03-31', 2026, 13), null);
  });

  test('comparison is string comparison', function (assert) {
    assert.strictEqual(compareDates('2026-11-24', '2026-11-25'), -1);
    assert.strictEqual(compareDates('2026-11-25', '2026-11-24'), 1);
    assert.strictEqual(compareDates('2026-11-24', '2026-11-24'), 0);
    assert.strictEqual(compareDates('0999-12-31', '1000-01-01'), -1);
    assert.strictEqual(minDate('2026-11-24', '2025-01-01'), '2025-01-01');
    assert.strictEqual(maxDate('2026-11-24', '2025-01-01'), '2026-11-24');
  });

  test('weekdays and weeks', function (assert) {
    assert.strictEqual(weekdayOf('2026-11-24'), 2, 'a Tuesday');
    assert.strictEqual(weekdayOf('2026-11-22'), 0, 'a Sunday');
    assert.strictEqual(
      weekdayOf('0001-01-01'),
      1,
      'proleptic Gregorian: Monday'
    );
    assert.strictEqual(weekdayOf('2000-02-29'), 2);
    assert.strictEqual(startOfWeek('2026-11-24', 1), '2026-11-23');
    assert.strictEqual(startOfWeek('2026-11-24', 0), '2026-11-22');
    assert.strictEqual(startOfWeek('2026-11-24', 6), '2026-11-21');
    assert.strictEqual(startOfWeek('2026-11-23', 1), '2026-11-23', 'itself');
    assert.strictEqual(endOfWeek('2026-11-24', 1), '2026-11-29');
    assert.strictEqual(endOfWeek('2026-11-24', 0), '2026-11-28');
    assert.strictEqual(endOfWeek('2026-11-28', 0), '2026-11-28', 'itself');
    assert.strictEqual(endOfWeek('2026-12-30', 1), '2027-01-03');
    assert.strictEqual(startOfWeek('0001-01-01', 0), null, 'before 0001');
  });

  test('the weeks of a month, for each first day of the week', function (assert) {
    // November 2026: the 1st is a Sunday, 30 days
    const sunday = weeksOfMonth(2026, 11, 0);
    assert.strictEqual(sunday.length, 5);
    assert.deepEqual(sunday[0], [
      '2026-11-01',
      '2026-11-02',
      '2026-11-03',
      '2026-11-04',
      '2026-11-05',
      '2026-11-06',
      '2026-11-07'
    ]);
    assert.strictEqual(sunday[4]![1], '2026-11-30');
    assert.strictEqual(sunday[4]![6], '2026-12-05', 'December fills the week');

    const monday = weeksOfMonth(2026, 11, 1);
    assert.strictEqual(monday.length, 6, 'the 1st alone in its week');
    assert.strictEqual(monday[0]![0], '2026-10-26');
    assert.strictEqual(monday[0]![6], '2026-11-01');
    assert.strictEqual(monday[5]![0], '2026-11-30');
    assert.strictEqual(monday[5]![6], '2026-12-06');

    // February 2026 from Sunday: the 1st is a Sunday, 28 days, exactly 4 weeks
    const february = weeksOfMonth(2026, 2, 0);
    assert.strictEqual(february.length, 4);
    assert.strictEqual(february[0]![0], '2026-02-01');
    assert.strictEqual(february[3]![6], '2026-02-28');

    for (let first = 0; first < 7; first++) {
      const weekday = first as Weekday;
      for (const [year, month] of [
        [2026, 11],
        [2028, 2],
        [2026, 2],
        [2026, 12]
      ] as const) {
        const weeks = weeksOfMonth(year, month, weekday);
        const days = weeks.flat();
        const inside = days.filter((day) => day && inMonth(day, year, month));
        assert.strictEqual(
          inside.length,
          daysInMonth(year, month),
          `${year}-${month} from ${first}: every day once`
        );
        assert.true(
          weeks.every((week) => weekdayOf(week[0]!) === weekday),
          `${year}-${month}: weeks start on ${first}`
        );
        assert.true(
          weeks.length >= 4 && weeks.length <= 6,
          `${year}-${month} from ${first}: ${weeks.length} weeks`
        );
        assert.true(
          inMonth(weeks[0]![6]!, year, month),
          'the first week is in the month'
        );
        assert.true(
          inMonth(weeks[weeks.length - 1]![0]!, year, month),
          'so is the last'
        );
      }
    }
  });

  test('the edges of the supported years', function (assert) {
    const first = weeksOfMonth(1, 1, 0);
    assert.strictEqual(
      first[0]![0],
      null,
      'Sunday 31 December 0000 is outside'
    );
    assert.strictEqual(first[0]![1], '0001-01-01');
    const last = weeksOfMonth(9999, 12, 1);
    assert.deepEqual(
      last[last.length - 1]!.slice(4),
      ['9999-12-31', null, null],
      '31 December 9999 is a Friday; the days after it are outside'
    );
    assert.throws(() => weeksOfMonth(10000, 1, 0), RangeError);
    assert.deepEqual(monthBounds(2028, 2), {
      first: '2028-02-01',
      last: '2028-02-29'
    });
    assert.strictEqual(
      new Date(utcMidnight(50, 1, 1)).getUTCFullYear(),
      50,
      'year 50, not 1950'
    );
  });
});
