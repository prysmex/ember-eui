import { module, test } from 'qunit';

import {
  choosesNative,
  nativeAttributes,
  parseNativeDateTime,
  parseNativeTime,
  readNative,
  unsupportedByNative
} from '#src/-private/native-date-input.ts';
import { dayLimits } from '#src/utils/date/calendar-nav.ts';

import type {
  NativeContext,
  NativeEnvironment
} from '#src/-private/native-date-input.ts';
import type { PickerMode } from '#src/utils/date/value.ts';

const desktop: NativeEnvironment = {
  browser: true,
  nativePlatform: false,
  coarsePointer: false
};
const phone: NativeEnvironment = { ...desktop, coarsePointer: true };
const capacitor: NativeEnvironment = { ...desktop, nativePlatform: true };
const server: NativeEnvironment = {
  browser: false,
  nativePlatform: true,
  coarsePointer: true
};

function context(
  mode: PickerMode,
  overrides: Partial<NativeContext> & {
    minTime?: string;
    maxTime?: string;
    excludeTimes?: string[];
  } = {}
): NativeContext {
  const zone = overrides.zone ?? 'utc';
  const minDate = overrides.minDate ?? null;
  const maxDate = overrides.maxDate ?? null;
  const timeLimits = {
    minTime: overrides.minTime,
    maxTime: overrides.maxTime,
    excludeTimes: overrides.excludeTimes
  };
  return {
    mode,
    zone,
    seconds: false,
    value: null,
    valueMs: null,
    minDate,
    maxDate,
    limits: dayLimits({ minDate, maxDate }, zone),
    instantRules: { minDate, maxDate, zone, ...timeLimits },
    timeLimits,
    ...overrides
  };
}

module('Unit | -private | native-date-input', function () {
  test('choosesNative: the order of DESIGN 6.2', function (assert) {
    const cases: [
      string,
      Parameters<typeof choosesNative>[0],
      NativeEnvironment,
      boolean
    ][] = [
      ['inline beats @native', { inline: true, native: true }, phone, false],
      [
        'a trigger beats @native',
        { trigger: true, native: true },
        phone,
        false
      ],
      ['@native true', { native: true }, desktop, true],
      ['@native false', { native: false }, capacitor, false],
      [
        '@native beats the config',
        { native: false, config: true },
        desktop,
        false
      ],
      ['the config true', { config: true }, desktop, true],
      ['the config false', { config: false }, phone, false],
      ["'auto' falls through", { native: 'auto', config: 'auto' }, phone, true],
      ['auto, desktop', {}, desktop, false],
      ['auto, coarse pointer', {}, phone, true],
      ['auto, Capacitor', {}, capacitor, true],
      ['auto, server rendering', {}, server, false],
      [
        'auto, an unsupported argument',
        { unsupported: true },
        capacitor,
        false
      ],
      [
        '@native true with an unsupported argument',
        { native: true, unsupported: true },
        desktop,
        true
      ],
      ['an unknown @native is auto', { native: 'yes' }, phone, true]
    ];
    for (const [name, options, environment, expected] of cases) {
      assert.strictEqual(choosesNative(options, environment), expected, name);
    }
  });

  test('unsupportedByNative names the given arguments the OS cannot honour', function (assert) {
    assert.deepEqual(
      unsupportedByNative({
        filterDate: () => true,
        excludeDates: [],
        includeDates: null,
        injectTimes: undefined,
        minDate: '2026-11-24'
      }),
      ['filterDate', 'excludeDates']
    );
    assert.deepEqual(unsupportedByNative({}), []);
  });

  test('parseNativeTime and parseNativeDateTime: what engines send', function (assert) {
    assert.deepEqual(parseNativeTime('09:30'), {
      hour: 9,
      minute: 30,
      second: 0,
      millisecond: 0
    });
    assert.deepEqual(parseNativeTime('09:30:15'), {
      hour: 9,
      minute: 30,
      second: 15,
      millisecond: 0
    });
    assert.deepEqual(parseNativeTime('09:30:15.5'), {
      hour: 9,
      minute: 30,
      second: 15,
      millisecond: 500
    });
    assert.strictEqual(parseNativeTime('24:00'), null);
    assert.strictEqual(parseNativeTime('9:30'), null);
    assert.deepEqual(parseNativeDateTime('2026-11-24T15:30'), {
      y: 2026,
      m: 11,
      d: 24,
      h: 15,
      mi: 30,
      s: 0,
      ms: 0
    });
    assert.strictEqual(parseNativeDateTime('2026-02-31T15:30'), null);
    assert.strictEqual(parseNativeDateTime('2026-11-24 15:30'), null);
  });

  test('nativeAttributes: type, value, min, max and step for each mode', function (assert) {
    assert.deepEqual(
      nativeAttributes(context('date', { value: '2026-11-24' })),
      {
        type: 'date',
        value: '2026-11-24',
        min: '0001-01-01',
        max: '9999-12-31',
        step: undefined
      }
    );
    assert.deepEqual(
      nativeAttributes(
        context('dateTime', {
          zone: 'America/Monterrey',
          valueMs: Date.UTC(2026, 10, 24, 21, 30, 45),
          minDate: '2026-11-02',
          maxDate: '2026-11-30T18:45:00.000Z'
        })
      ),
      {
        type: 'datetime-local',
        value: '2026-11-24T15:30',
        min: '2026-11-02T00:00',
        max: '2026-11-30T12:45',
        step: '60'
      }
    );
    assert.deepEqual(
      nativeAttributes(
        context('time', {
          value: '09:30:45',
          seconds: true,
          minTime: '06:00',
          maxTime: '22:00'
        })
      ),
      {
        type: 'time',
        value: '09:30:45',
        min: '06:00:00',
        max: '22:00:00',
        step: '1'
      }
    );
    assert.strictEqual(
      nativeAttributes(context('time', { minTime: 'soon' })).min,
      undefined,
      'an unreadable time limit is none'
    );
  });

  test('readNative: empty, half-filled, values and problems', function (assert) {
    const date = context('date', {
      value: '2026-11-24',
      minDate: '2026-11-02'
    });
    assert.deepEqual(readNative('', false, date), { kind: 'empty' });
    assert.deepEqual(readNative('', true, date), {
      kind: 'problem',
      problem: 'unreadable'
    });
    assert.deepEqual(readNative('2026-11-25', false, date), {
      kind: 'value',
      value: '2026-11-25',
      changes: true
    });
    assert.deepEqual(readNative('2026-11-24', false, date), {
      kind: 'value',
      value: '2026-11-24',
      changes: false
    });
    assert.deepEqual(readNative('2026-11-01', false, date), {
      kind: 'problem',
      problem: 'min'
    });
    assert.deepEqual(readNative('2026-13-01', false, date), {
      kind: 'problem',
      problem: 'unreadable'
    });

    const newYork = context('dateTime', { zone: 'America/New_York' });
    assert.deepEqual(
      readNative('2026-03-08T02:30', false, newYork),
      { kind: 'value', value: '2026-03-08T07:30:00.000Z', changes: true },
      'a gap resolves forward'
    );
    assert.deepEqual(
      readNative('2026-11-01T01:30', false, newYork),
      { kind: 'value', value: '2026-11-01T05:30:00.000Z', changes: true },
      'an overlap is the first'
    );
    const second = context('dateTime', {
      zone: 'America/New_York',
      valueMs: Date.parse('2026-11-01T06:30:00.000Z')
    });
    assert.false(
      (readNative('2026-11-01T01:30', false, second) as { changes: boolean })
        .changes,
      'a stored second occurrence survives'
    );

    const time = context('time', {
      value: '09:30',
      minTime: '06:00',
      excludeTimes: ['12:00']
    });
    assert.deepEqual(readNative('05:00', false, time), {
      kind: 'problem',
      problem: 'min'
    });
    assert.deepEqual(readNative('12:00', false, time), {
      kind: 'problem',
      problem: 'disabled'
    });
    assert.deepEqual(
      readNative('10:00:30', false, time),
      { kind: 'value', value: '10:00', changes: true },
      'seconds only with @seconds'
    );
  });
});
