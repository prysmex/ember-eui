/**
 * The `dateTime` type (V03-DESIGN.md 10.3, DT1-DT4). Only 'utc' and named
 * zones, never 'local', so nothing depends on the machine's zone.
 */
import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  dateTimeFieldType,
  dateTimeLocalValue,
  defaultMessages,
  summarize,
  validTimeZone
} from '#src/core/index.ts';

import type { DateTimeField } from '#src/core/index.ts';

const type = dateTimeFieldType;
const context = { record: undefined, messages: defaultMessages };

function field(extra: Partial<DateTimeField> = {}): DateTimeField {
  return { id: 'at', type: 'dateTime', timeZone: 'utc', ...extra };
}

function parse(text: string, extra: Partial<DateTimeField> = {}): unknown {
  const result = type.parse(text, field(extra), { ...context, source: 'edit' });
  return 'value' in result ? result.value : result;
}

function format(value: string, extra: Partial<DateTimeField> = {}): string {
  return type.format(value, field(extra), context);
}

const MEXICO = { timeZone: 'America/Mexico_City' };
const NEW_YORK = { timeZone: 'America/New_York' };

module('Unit | Sheet | dateTime (V03 10.3)', function () {
  test('DT1 parse: ISO with Z, with an offset, without (the field zone), D/M/YYYY H:mm, am/pm, a date alone; errors', function (assert) {
    const at = '2026-11-19T15:30:00.000Z';
    assert.strictEqual(parse('2026-11-19T15:30:00Z'), at, 'Z');
    assert.strictEqual(
      parse('2026-11-19T15:30Z', MEXICO),
      at,
      'Z wins over the zone'
    );
    assert.strictEqual(parse('2026-11-19T09:30:00-06:00'), at, 'an offset');
    assert.strictEqual(
      parse('2026-11-19T21:00+0530'),
      at,
      'an offset without a colon'
    );
    assert.strictEqual(
      parse('2026-11-19T15:30:45.123Z'),
      '2026-11-19T15:30:45.123Z',
      'an instant keeps its seconds and ms'
    );
    assert.strictEqual(
      parse('2026-11-19T15:30'),
      at,
      'without: a wall clock in utc'
    );
    assert.strictEqual(
      parse('2026-11-19 09:30', MEXICO),
      at,
      'in Mexico City (UTC-6)'
    );
    assert.strictEqual(parse('19/11/2026 15:30'), at, 'D/M/YYYY H:mm');
    assert.strictEqual(parse('19-11-2026 15:30'), at, 'with -');
    assert.strictEqual(parse('19.11.2026 15.30'), at, 'with .');
    assert.strictEqual(parse(' 19/11/2026, 15:30 '), at, 'a comma, spaces');
    assert.strictEqual(parse('19/11/2026 9:30', MEXICO), at, 'one-digit hour');
    assert.strictEqual(
      parse('11/19/2026 15:30', { dateOrder: 'mdy' }),
      at,
      'month first'
    );
    assert.strictEqual(parse('19/11/2026 3:30 pm'), at, 'pm');
    assert.strictEqual(parse('19/11/2026 3:30PM'), at, 'PM, no space');
    assert.strictEqual(
      parse('19/11/2026 3 pm'),
      '2026-11-19T15:00:00.000Z',
      'pm without minutes'
    );
    assert.strictEqual(
      parse('19/11/2026 12:05 am'),
      '2026-11-19T00:05:00.000Z',
      '12 am'
    );
    assert.strictEqual(
      parse('19/11/2026 12:05 pm'),
      '2026-11-19T12:05:00.000Z',
      '12 pm'
    );
    assert.strictEqual(
      parse('19/11/2026'),
      '2026-11-19T00:00:00.000Z',
      'a date alone: midnight'
    );
    assert.strictEqual(
      parse('2026-11-19', MEXICO),
      '2026-11-19T06:00:00.000Z',
      'midnight in the zone'
    );
    assert.strictEqual(
      parse('19/11/2026 15:30:45'),
      at,
      'typed seconds dropped without `seconds`'
    );
    assert.strictEqual(
      parse('19/11/2026 15:30:45', { seconds: true }),
      '2026-11-19T15:30:45.000Z',
      'kept with it'
    );
    assert.strictEqual(parse(''), null, 'empty');
    for (const text of [
      '32/11/2026 10:00',
      '29/02/2026 10:00',
      '19/11/2026 25:00',
      '19/11/2026 10:60',
      '19/11/2026 13:00 pm',
      '19/11/2026 15',
      '2026-02-30T10:00Z',
      '2026-11-19T10:00+25:00',
      'tomorrow at 3'
    ]) {
      assert.deepEqual(
        type.parse(text, field(), { ...context, source: 'paste' }),
        { error: `"${text}" is not a date and time` },
        text
      );
    }
  });

  test('DT2 format in utc, in America/Mexico_City, 12-hour, seconds; parse(copyText(v)) is v', function (assert) {
    const at = '2026-11-19T15:30:45.000Z';
    assert.strictEqual(format(at), '19/11/2026 15:30');
    assert.strictEqual(format(at, MEXICO), '19/11/2026 09:30');
    assert.strictEqual(format(at, { dateOrder: 'mdy' }), '11/19/2026 15:30');
    assert.strictEqual(format(at, { hour12: true }), '19/11/2026 3:30 pm');
    assert.strictEqual(
      format('2026-11-19T00:05:00.000Z', { hour12: true }),
      '19/11/2026 12:05 am'
    );
    assert.strictEqual(format(at, { seconds: true }), '19/11/2026 15:30:45');
    assert.strictEqual(
      format('2026-11-19T03:00:00.000Z', MEXICO),
      '18/11/2026 21:00',
      'the day changes with the zone'
    );
    assert.strictEqual(format(''), '');
    assert.strictEqual(format('not a time'), 'not a time', 'shown as it is');
    for (const value of [
      at,
      '2026-11-19T15:30:45.123Z',
      '1999-01-01T00:00:00.000Z'
    ]) {
      for (const extra of [{}, MEXICO, { hour12: true }, { seconds: true }]) {
        const copied = type.copyText!(value, field(extra), context);
        assert.strictEqual(copied, value, 'copy is the stored ISO string');
        assert.strictEqual(parse(copied, extra), value, `round trip ${value}`);
      }
    }
    // the format itself reads back to the same minute
    assert.strictEqual(
      parse(format(at, MEXICO), MEXICO),
      '2026-11-19T15:30:00.000Z'
    );
    assert.strictEqual(
      parse(format(at, { hour12: true }), { hour12: true }),
      '2026-11-19T15:30:00.000Z'
    );
    assert.strictEqual(
      dateTimeLocalValue(at, field(MEXICO)),
      '2026-11-19T09:30',
      'the picker’s value is the zone’s wall clock'
    );
    assert.strictEqual(
      dateTimeLocalValue(at, field({ seconds: true })),
      '2026-11-19T15:30:45'
    );
    assert.strictEqual(dateTimeLocalValue(null, field()), '');
  });

  test('DT3 a wall clock in a DST gap and in a DST overlap, in America/New_York', function (assert) {
    // 2026-03-08: 02:00 EST → 03:00 EDT; 02:30 does not exist
    assert.strictEqual(
      parse('08/03/2026 02:30', NEW_YORK),
      '2026-03-08T07:30:00.000Z',
      'the gap resolves forward: 03:30 EDT'
    );
    assert.strictEqual(
      format('2026-03-08T07:30:00.000Z', NEW_YORK),
      '08/03/2026 03:30'
    );
    assert.strictEqual(
      parse('08/03/2026 01:59', NEW_YORK),
      '2026-03-08T06:59:00.000Z',
      'just before the gap: EST'
    );
    assert.strictEqual(
      parse('08/03/2026 03:00', NEW_YORK),
      '2026-03-08T07:00:00.000Z',
      'just after: EDT'
    );
    assert.strictEqual(
      parse('07/03/2026 23:00', NEW_YORK),
      '2026-03-08T04:00:00.000Z',
      'the evening before: EST'
    );
    // 2026-11-01: 02:00 EDT → 01:00 EST; 01:30 happens twice
    assert.strictEqual(
      parse('01/11/2026 01:30', NEW_YORK),
      '2026-11-01T05:30:00.000Z',
      'the overlap resolves to the first: 01:30 EDT'
    );
    assert.strictEqual(
      format('2026-11-01T06:30:00.000Z', NEW_YORK),
      '01/11/2026 01:30',
      'the second 01:30 (EST) shows the same'
    );
    assert.strictEqual(
      parse('01/11/2026 03:00', NEW_YORK),
      '2026-11-01T08:00:00.000Z',
      'after the overlap: EST'
    );
  });

  test('DT4 compare, series (one value, a weekly step), validate with min/max and an unknown zone', function (assert) {
    const a = '2026-11-19T15:30:00.000Z';
    const b = '2026-11-20T08:00:00.000Z';
    const compare = type.compare!;
    assert.true(compare(a, b, field()) < 0);
    assert.true(compare(b, a, field()) > 0);
    assert.strictEqual(compare(a, a, field()), 0);
    assert.true(compare(null, a, field()) < 0, 'empty first');
    assert.strictEqual(compare(null, undefined, field()), 0);

    const series = type.series!;
    assert.deepEqual(
      series([a], 2, field(), 1),
      ['2026-11-20T15:30:00.000Z', '2026-11-21T15:30:00.000Z'],
      'one value: by a day'
    );
    assert.deepEqual(
      series([a], 1, field(), -1),
      ['2026-11-18T15:30:00.000Z'],
      'upwards'
    );
    assert.deepEqual(
      series(['2026-10-31T14:00:00.000Z'], 1, field(NEW_YORK), 1),
      ['2026-11-01T15:00:00.000Z'],
      'a calendar day in the zone: 10:00 stays 10:00 across the DST change'
    );
    const week = '2026-11-26T15:30:00.000Z';
    assert.deepEqual(
      series([a, week], 2, field(), 1),
      ['2026-12-03T15:30:00.000Z', '2026-12-10T15:30:00.000Z'],
      'a weekly step'
    );
    assert.deepEqual(
      series([a, week], 1, field(), -1),
      ['2026-11-12T15:30:00.000Z'],
      'the step upwards'
    );
    assert.strictEqual(
      series([a, week, '2026-11-27T00:00:00.000Z'], 1, field(), 1),
      undefined,
      'no constant step: copies'
    );
    assert.strictEqual(series(['x'], 1, field(), 1), undefined);

    const validate = (value: string, extra: Partial<DateTimeField> = {}) =>
      type.validate!(value, field(extra), context);
    const limits = {
      min: '2026-11-01T00:00:00.000Z',
      max: '2026-11-30T23:59:00.000Z'
    };
    assert.deepEqual(validate(a, limits), [], 'inside');
    assert.deepEqual(
      validate('2026-10-31T23:59:00.000Z', limits),
      ['Must be 01/11/2026 00:00 or more'],
      'below min'
    );
    assert.deepEqual(
      validate('2026-12-01T00:00:00.000Z', limits),
      ['Must be 30/11/2026 23:59 or less'],
      'above max'
    );
    assert.deepEqual(validate(limits.min, limits), [], 'min is inclusive');
    assert.deepEqual(validate('abc'), ['"abc" is not a date and time']);
    assert.deepEqual(
      validate(a, { timeZone: 'Mars/Olympus_Mons' }),
      ['Unknown time zone "Mars/Olympus_Mons"'],
      'an unknown zone: an error on every value'
    );
    assert.strictEqual(
      format(a, { timeZone: 'Mars/Olympus_Mons' }),
      '19/11/2026 15:30',
      'and no throw: shown in UTC'
    );
    assert.false(validTimeZone('Mars/Olympus_Mons'));
    assert.true(validTimeZone('America/Mexico_City'));
    assert.true(validTimeZone('utc'));

    // summarize's min and max work through compare
    const records = [{ at: b }, { at: a }, { at: null }];
    const ctx = { types: builtInFieldTypes, messages: defaultMessages };
    assert.strictEqual(summarize(ctx, records, field(), 'min'), format(a));
    assert.strictEqual(summarize(ctx, records, field(), 'max'), format(b));
  });
});
