/**
 * Typed input (DESIGN 5.3): every accepted and refused form. "This year"
 * is injected, so nothing reads the clock.
 */
import { module, test } from 'qunit';

import {
  compareTimes,
  instantString,
  parseDateText,
  parseDateTimeText,
  parseInstant,
  parseTimeText,
  parseTimeValue,
  parseWallText,
  resolveTwoDigitYear,
  timeValueOf,
  validInstant
} from '#src/utils/date/parse.ts';

import type { DateOrder } from '#src/utils/date/parse.ts';

const YEAR = 2026;
const NEW_YORK_ZONE = 'America/New_York';

function date(text: string, order: DateOrder = 'dmy', year = YEAR) {
  return parseDateText(text, { order, year });
}

function dateTime(
  text: string,
  zone = 'utc',
  extra: { order?: DateOrder; seconds?: boolean } = {}
): string | null {
  const ms = parseDateTimeText(text, {
    order: extra.order ?? 'dmy',
    year: YEAR,
    zone,
    seconds: extra.seconds
  });
  return ms === null ? null : instantString(ms);
}

module('Unit | utils | date | parse', function () {
  test('ISO and year-first dates, in any order', function (assert) {
    for (const order of ['dmy', 'mdy', 'ymd'] as const) {
      assert.strictEqual(date('2026-11-24', order), '2026-11-24', order);
      assert.strictEqual(date('2026/11/24', order), '2026-11-24', order);
      assert.strictEqual(
        date('2026-1-5', order),
        '2026-01-05',
        'zeros optional'
      );
    }
    assert.strictEqual(date('  2026-11-24 '), '2026-11-24', 'trimmed');
    assert.strictEqual(date('2026-11/24'), null, 'two separators');
    assert.strictEqual(date('2026.11.24'), null, 'dots need ymd');
    assert.strictEqual(date('2026.11.24', 'ymd'), '2026-11-24');
    assert.strictEqual(
      date('2026-11-24T10:00'),
      null,
      'no time part in a date'
    );
    assert.strictEqual(date('0001-01-01'), '0001-01-01');
    assert.strictEqual(date('0000-01-01'), null, 'year 0');
  });

  test('the field order decides D/M against M/D, never a guess (9 #4, #5)', function (assert) {
    assert.strictEqual(date('3/4/2026', 'dmy'), '2026-04-03');
    assert.strictEqual(date('3/4/2026', 'mdy'), '2026-03-04');
    assert.strictEqual(date('24/11/2026', 'dmy'), '2026-11-24');
    assert.strictEqual(date('24/11/2026', 'mdy'), null, 'month 24');
    assert.strictEqual(date('11/24/2026', 'mdy'), '2026-11-24');
    assert.strictEqual(date('24.11.2026'), '2026-11-24', 'dots');
    assert.strictEqual(date('24-11-2026'), '2026-11-24', 'dashes');
    assert.strictEqual(date('03/04/2026'), '2026-04-03', 'leading zeros');
    assert.strictEqual(date('24/11-2026'), null, 'mixed separators');
    assert.strictEqual(date('24 11 2026'), null, 'spaces');
    assert.strictEqual(date('24/11/2026', 'ymd'), null, 'ymd reads year first');
    assert.strictEqual(
      date('26/11/24', 'ymd'),
      '2026-11-24',
      'ymd, two-digit year'
    );
    assert.strictEqual(date('26.1.5', 'ymd'), '2026-01-05');
  });

  test('impossible, partial and odd dates are unreadable (9 #6, #8, #51)', function (assert) {
    for (const text of [
      '13/13/2026',
      '31/02/2026',
      '29/02/2027',
      '0/1/2026',
      '1/0/2026',
      '24/11',
      '24/11/',
      '24/11/2',
      '24/11/202',
      '24/11/099',
      '24/11/10000',
      '24/11/20261',
      '124/11/2026',
      'yesterday',
      '5 March 2026',
      '',
      '   '
    ]) {
      assert.strictEqual(date(text), null, `"${text}"`);
    }
    assert.strictEqual(date('29/02/2028'), '2028-02-29', 'a leap day');
  });

  test('two-digit years: this year minus 50 to plus 49 (9 #7)', function (assert) {
    assert.strictEqual(date('24/11/26'), '2026-11-24');
    assert.strictEqual(date('24/11/76'), '1976-11-24', 'this year minus 50');
    assert.strictEqual(date('24/11/75'), '2075-11-24', 'this year plus 49');
    assert.strictEqual(date('1/1/00'), '2000-01-01');
    assert.strictEqual(date('1/1/99'), '1999-01-01');
    assert.strictEqual(date('11/24/26', 'mdy'), '2026-11-24');
    assert.strictEqual(
      date('24/11/76', 'dmy', 2027),
      '2076-11-24',
      'the window moves with the year'
    );
    assert.strictEqual(resolveTwoDigitYear(76, 2026), 1976);
    assert.strictEqual(resolveTwoDigitYear(75, 2026), 2075);
    assert.strictEqual(resolveTwoDigitYear(50, 2000), 1950);
    assert.strictEqual(resolveTwoDigitYear(49, 2000), 2049);
    assert.strictEqual(resolveTwoDigitYear(0, 2050), 2000);
    for (let yy = 0; yy < 100; yy++) {
      const year = resolveTwoDigitYear(yy, 2026);
      assert.true(
        year >= 1976 && year <= 2075 && year % 100 === yy,
        `${yy} → ${year}`
      );
    }
  });

  test('times: forms, meridiems, refusals', function (assert) {
    const t = (hour: number, minute: number, second = 0) => ({
      hour,
      minute,
      second
    });
    assert.deepEqual(parseTimeText('15:30'), t(15, 30));
    assert.deepEqual(parseTimeText('9:05'), t(9, 5));
    assert.deepEqual(parseTimeText('09:05'), t(9, 5));
    assert.deepEqual(parseTimeText('15:30:45'), t(15, 30, 45));
    assert.deepEqual(parseTimeText('15.30'), t(15, 30));
    assert.deepEqual(parseTimeText('0:00'), t(0, 0));
    assert.deepEqual(parseTimeText('23:59:59'), t(23, 59, 59));
    assert.deepEqual(parseTimeText('3:30 pm'), t(15, 30));
    assert.deepEqual(parseTimeText('3:30PM'), t(15, 30));
    assert.deepEqual(parseTimeText('3:30 p.m.'), t(15, 30));
    assert.deepEqual(parseTimeText('3:30 a.m.'), t(3, 30));
    assert.deepEqual(parseTimeText('3:30 p'), t(15, 30));
    assert.deepEqual(parseTimeText('3:30a'), t(3, 30));
    assert.deepEqual(parseTimeText('3 pm'), t(15, 0));
    assert.deepEqual(parseTimeText('12 am'), t(0, 0), 'midnight');
    assert.deepEqual(parseTimeText('12:15 pm'), t(12, 15), 'noon');
    assert.deepEqual(parseTimeText('12:15 am'), t(0, 15));
    assert.deepEqual(parseTimeText(' 7:45:10 pm '), t(19, 45, 10));
    for (const text of [
      '15',
      '24:00',
      '23:60',
      '23:59:60',
      '13:00 pm',
      '0:30 am',
      '0 am',
      '3:5',
      '3:',
      ':30',
      '3:30 xm',
      '330',
      'noon',
      ''
    ]) {
      assert.strictEqual(parseTimeText(text), null, `"${text}"`);
    }
  });

  test('date and time: a date, a space or ", ", a time; a date alone is midnight', function (assert) {
    const at = '2026-11-24T15:30:00.000Z';
    assert.strictEqual(dateTime('24/11/2026 15:30'), at);
    assert.strictEqual(dateTime('24/11/2026, 15:30'), at);
    assert.strictEqual(dateTime(' 24/11/2026,  3:30 pm '), at);
    assert.strictEqual(dateTime('24/11/26 15:30'), at, 'a two-digit year');
    assert.strictEqual(
      dateTime('11/24/2026 3 pm', 'utc', { order: 'mdy' }),
      '2026-11-24T15:00:00.000Z'
    );
    assert.strictEqual(dateTime('2026-11-24 15:30'), at, 'ISO, a space');
    assert.strictEqual(
      dateTime('2026-11-24T15:30'),
      at,
      'ISO without a designator: a wall clock'
    );
    assert.strictEqual(
      dateTime('24/11/2026'),
      '2026-11-24T00:00:00.000Z',
      'midnight'
    );
    assert.strictEqual(dateTime('2026-11-24'), '2026-11-24T00:00:00.000Z');
    assert.strictEqual(
      dateTime('24/11/2026 09:30', 'America/Mexico_City'),
      at,
      'in the field zone'
    );
    assert.strictEqual(
      dateTime('24/11/2026', 'America/Mexico_City'),
      '2026-11-24T06:00:00.000Z'
    );
    for (const text of [
      '24/11/2026,15:30',
      '24/11/2026 15',
      '24/11/2026 25:00',
      '24/11 15:30',
      '15:30',
      '24/11/2026 15:30 extra',
      '2026-11-24T24:00'
    ]) {
      assert.strictEqual(dateTime(text), null, `"${text}"`);
    }
  });

  test('typed seconds: kept only with seconds; an instant is kept whole', function (assert) {
    assert.strictEqual(
      dateTime('24/11/2026 15:30:45'),
      '2026-11-24T15:30:00.000Z'
    );
    assert.strictEqual(
      dateTime('24/11/2026 15:30:45', 'utc', { seconds: true }),
      '2026-11-24T15:30:45.000Z'
    );
    assert.strictEqual(
      dateTime('2026-11-24T15:30:45.123Z'),
      '2026-11-24T15:30:45.123Z',
      'an ISO instant is that instant'
    );
  });

  test('an ISO string with Z or an offset is that instant, whatever the zone', function (assert) {
    const at = '2026-11-24T15:30:00.000Z';
    assert.strictEqual(
      dateTime('2026-11-24T15:30:00Z', 'America/Mexico_City'),
      at
    );
    assert.strictEqual(dateTime('2026-11-24T17:30+02:00', NEW_YORK_ZONE), at);
    assert.strictEqual(
      dateTime('2026-11-24T21:00+0530'),
      at,
      'without a colon'
    );
    assert.strictEqual(dateTime('2026-11-24T12:30-03'), at, 'hours only');
    assert.strictEqual(dateTime('2026-11-24t15:30z'), at, 'lower case');
  });

  test('DST: a typed gap time resolves forward, an overlap to the first (9 #19, #20)', function (assert) {
    assert.strictEqual(
      dateTime('08/03/2026 02:30', NEW_YORK_ZONE),
      '2026-03-08T07:30:00.000Z',
      '03:30 EDT'
    );
    assert.strictEqual(
      dateTime('01/11/2026 01:30', NEW_YORK_ZONE),
      '2026-11-01T05:30:00.000Z',
      'the first 01:30 (EDT)'
    );
  });

  test('stored instants: @value in date-and-time mode', function (assert) {
    const at = Date.UTC(2026, 10, 24, 15, 30);
    assert.strictEqual(parseInstant('2026-11-24T15:30:00.000Z'), at);
    assert.strictEqual(parseInstant('2026-11-24T15:30:00Z'), at);
    assert.strictEqual(parseInstant('2026-11-24T15:30Z'), at);
    assert.strictEqual(
      parseInstant('2026-11-24T17:30:00.000+02:00'),
      at,
      'input with an offset'
    );
    assert.strictEqual(
      validInstant('2026-11-24T17:30:00+02:00'),
      '2026-11-24T15:30:00.000Z',
      'output is always Z'
    );
    assert.strictEqual(
      parseInstant('2026-11-24T15:30:00.123456Z'),
      at + 123,
      'extra digits dropped'
    );
    assert.strictEqual(
      parseInstant('0001-01-01T00:00:00.000Z'),
      Date.parse('0001-01-01T00:00:00.000Z')
    );
    for (const value of [
      '2026-11-24T15:30:00',
      '2026-11-24',
      '2026-02-31T00:00:00Z',
      '2026-11-24T24:00:00Z',
      '2026-11-24T15:30:00+24:00',
      '2026-11-24T15:30:00+02:60',
      '0000-01-01T00:00:00Z',
      'yesterday',
      '',
      null,
      undefined,
      1764000000000,
      new Date(0)
    ]) {
      assert.strictEqual(parseInstant(value), null, String(value));
    }
    assert.strictEqual(validInstant('nope'), null);
  });

  test('stored times: @value in time mode', function (assert) {
    assert.deepEqual(parseTimeValue('09:30'), {
      hour: 9,
      minute: 30,
      second: 0
    });
    assert.deepEqual(parseTimeValue('23:59:59'), {
      hour: 23,
      minute: 59,
      second: 59
    });
    for (const value of [
      '9:30',
      '24:00',
      '09:60',
      '09:30:60',
      '09:30 am',
      '0930',
      '',
      null,
      930
    ]) {
      assert.strictEqual(parseTimeValue(value), null, String(value));
    }
    assert.strictEqual(timeValueOf({ hour: 9, minute: 5, second: 7 }), '09:05');
    assert.strictEqual(
      timeValueOf({ hour: 9, minute: 5, second: 7 }, true),
      '09:05:07'
    );
    assert.strictEqual(
      compareTimes(
        { hour: 9, minute: 5, second: 0 },
        { hour: 9, minute: 5, second: 1 }
      ),
      -1
    );
    assert.strictEqual(
      compareTimes(
        { hour: 10, minute: 0, second: 0 },
        { hour: 9, minute: 59, second: 59 }
      ),
      1
    );
    assert.strictEqual(
      compareTimes(
        { hour: 9, minute: 5, second: 0 },
        { hour: 9, minute: 5, second: 0 }
      ),
      0
    );
  });

  test('wall clocks without a zone', function (assert) {
    assert.deepEqual(
      parseWallText('24/11/2026 3:30:15 pm', { order: 'dmy', year: YEAR }),
      {
        y: 2026,
        m: 11,
        d: 24,
        h: 15,
        mi: 30,
        s: 15,
        ms: 0
      }
    );
    assert.strictEqual(
      parseWallText('2026-11-24T15:30Z', { order: 'dmy', year: YEAR }),
      null,
      'with a designator it is an instant, not a wall clock'
    );
  });
});
