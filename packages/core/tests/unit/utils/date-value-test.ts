/**
 * `Date` and moment values on the way in (DESIGN 18). A real moment is
 * used here, in the tests only; the module recognises it by shape.
 */
import { module, test } from 'qunit';
import moment from 'moment';

import {
  instantOfObject,
  isDateInstance,
  isDateObject,
  isInvalidDateObject,
  isMomentLike,
  toDateValue
} from '#src/utils/date/value.ts';

module('Unit | utils | date | value', function () {
  test('a moment is recognised by shape, without importing the library', function (assert) {
    assert.true(isMomentLike(moment()));
    assert.true(isMomentLike(moment.utc()));
    assert.true(
      isMomentLike(moment('nope', 'YYYY-MM-DD', true)),
      'invalid too'
    );
    assert.true(isMomentLike({ _isAMomentObject: true }), 'the flag alone');
    assert.true(
      isMomentLike({
        isValid: () => true,
        toISOString: () => '',
        format: () => '',
        utcOffset: () => 0
      }),
      'the four functions'
    );
    for (const value of [
      null,
      undefined,
      '2026-11-24',
      42,
      new Date(),
      { isValid: () => true },
      { _isAMomentObject: 'yes' }
    ]) {
      assert.false(isMomentLike(value), JSON.stringify(value) ?? 'undefined');
    }
  });

  test('Date instances, also by tag', function (assert) {
    assert.true(isDateInstance(new Date()));
    assert.true(isDateInstance(new Date(NaN)));
    const foreign = Object.create(Date.prototype) as Date;
    assert.true(isDateInstance(foreign), 'prototype');
    assert.false(isDateInstance('2026-11-24'));
    assert.false(isDateInstance(moment()));
    assert.true(isDateObject(new Date()) && isDateObject(moment()));
    assert.false(isDateObject('2026-11-24'));
  });

  test('instants: valid, invalid (NaN), not an object (null)', function (assert) {
    const ms = Date.UTC(2026, 10, 24, 15, 30);
    assert.strictEqual(instantOfObject(new Date(ms)), ms);
    assert.strictEqual(instantOfObject(moment(ms)), ms);
    assert.strictEqual(instantOfObject(moment.utc(ms)), ms);
    assert.true(Number.isNaN(instantOfObject(new Date(NaN))));
    assert.true(Number.isNaN(instantOfObject(moment.invalid())));
    assert.true(
      Number.isNaN(instantOfObject({ _isAMomentObject: true })),
      'a broken moment-like object is invalid, it does not throw'
    );
    assert.strictEqual(instantOfObject('2026-11-24'), null);
    assert.strictEqual(instantOfObject(null), null);
  });

  test('date mode reads the day in the picker zone', function (assert) {
    const ms = Date.UTC(2026, 10, 24, 3, 0); // 03:00Z
    assert.strictEqual(toDateValue(new Date(ms), 'utc'), '2026-11-24');
    assert.strictEqual(
      toDateValue(new Date(ms), 'America/Monterrey'),
      '2026-11-23',
      '21:00 the day before in UTC-6'
    );
    assert.strictEqual(toDateValue(moment.utc(ms), 'Asia/Tokyo'), '2026-11-24');
    assert.strictEqual(
      toDateValue(moment.utc(ms).utcOffset(-360), 'utc'),
      '2026-11-24',
      "a moment's own offset does not decide the day: the zone does"
    );
    assert.strictEqual(
      toDateValue(moment('2026-11-24'), 'local'),
      '2026-11-24',
      'a local-midnight moment is its day in the local zone'
    );
    assert.strictEqual(
      toDateValue(new Date(2026, 10, 24), 'local'),
      '2026-11-24',
      'and a local Date'
    );
  });

  test('invalid objects read as null; strings and others pass through', function (assert) {
    assert.strictEqual(toDateValue(new Date(NaN), 'utc'), null);
    assert.strictEqual(toDateValue(moment.invalid(), 'utc'), null);
    assert.true(isInvalidDateObject(new Date(NaN)));
    assert.true(isInvalidDateObject(moment('x', 'YYYY', true)));
    assert.false(isInvalidDateObject(new Date()));
    assert.false(isInvalidDateObject('2026-02-31'));
    assert.strictEqual(toDateValue('2026-02-31', 'utc'), '2026-02-31');
    assert.strictEqual(toDateValue(null, 'utc'), null);
    assert.strictEqual(toDateValue(undefined, 'utc'), undefined);
  });

  test('the objects are never mutated', function (assert) {
    const m = moment.utc('2026-11-24T15:30:00Z');
    const before = m.toISOString();
    const d = new Date(Date.UTC(2026, 10, 24));
    toDateValue(m, 'America/New_York');
    toDateValue(d, 'Asia/Tokyo');
    instantOfObject(m);
    assert.strictEqual(m.toISOString(), before);
    assert.strictEqual(m.utcOffset(), 0);
    assert.strictEqual(d.getTime(), Date.UTC(2026, 10, 24));
  });

  test('date-and-time mode reads the instant (DESIGN 18)', function (assert) {
    const ms = Date.UTC(2026, 10, 24, 15, 30, 45, 123);
    assert.strictEqual(
      toDateValue(new Date(ms), 'America/New_York', 'dateTime'),
      '2026-11-24T15:30:45.123Z',
      'a Date: its instant, whatever the zone'
    );
    assert.strictEqual(
      toDateValue(moment.utc(ms).utcOffset(330), 'utc', 'dateTime'),
      '2026-11-24T15:30:45.123Z',
      'a moment with an offset: the same instant, always as Z'
    );
    assert.strictEqual(toDateValue(new Date(NaN), 'utc', 'dateTime'), null);
    assert.strictEqual(toDateValue(moment.invalid(), 'utc', 'dateTime'), null);
    assert.strictEqual(
      toDateValue('2026-11-24T15:30:00.000Z', 'utc', 'dateTime'),
      '2026-11-24T15:30:00.000Z',
      'strings pass through'
    );
  });

  test('time-only mode reads the wall-clock time in the zone (DESIGN 18)', function (assert) {
    const ms = Date.UTC(2026, 10, 24, 15, 30, 45);
    assert.strictEqual(toDateValue(new Date(ms), 'utc', 'time'), '15:30');
    assert.strictEqual(
      toDateValue(new Date(ms), 'utc', 'time', true),
      '15:30:45',
      'with seconds'
    );
    assert.strictEqual(
      toDateValue(moment.utc(ms), 'America/New_York', 'time'),
      '10:30',
      'the wall clock in the zone'
    );
    assert.strictEqual(
      toDateValue(moment.utc(ms), '+05:30', 'time'),
      '21:00',
      'a fixed offset'
    );
    assert.strictEqual(
      toDateValue(new Date(2026, 10, 24, 9, 5), 'local', 'time'),
      '09:05',
      'a local Date'
    );
    assert.strictEqual(toDateValue(moment.invalid(), 'utc', 'time'), null);
    assert.strictEqual(toDateValue('09:30', 'utc', 'time'), '09:30');
  });
});
