/**
 * The time list (DESIGN 5.2): intervals, injected, excluded, limits, a gap
 * day and an overlap day; the rules for a chosen time.
 */
import { module, test } from 'qunit';

import {
  changesValue,
  instantAt,
  instantProblem,
  timeInterval,
  timeList,
  timeProblem
} from '#src/utils/date/times.ts';
import { wallAt, wallOf } from '#src/utils/date/zone.ts';

const NEW_YORK = 'America/New_York';
const iso = (ms: number | null) =>
  ms === null ? null : new Date(ms).toISOString();
const values = (entries: { value: string }[]) =>
  entries.map((entry) => entry.value);

module('Unit | utils | date | times', function () {
  test('wall times every 30 minutes from midnight by default', function (assert) {
    const list = timeList();
    assert.strictEqual(list.length, 48);
    assert.strictEqual(list[0]!.value, '00:00');
    assert.strictEqual(list[1]!.value, '00:30');
    assert.strictEqual(list[47]!.value, '23:30');
    assert.true(
      list.every(
        (entry) =>
          entry.instant === null && entry.problem === null && !entry.injected
      ),
      'time only: no instants'
    );
  });

  test('intervals; an invalid interval is 30 (9 #52)', function (assert) {
    assert.strictEqual(timeList({ interval: 15 }).length, 96);
    assert.strictEqual(timeList({ interval: 60 }).length, 24);
    assert.deepEqual(values(timeList({ interval: 600 })), [
      '00:00',
      '10:00',
      '20:00'
    ]);
    assert.deepEqual(values(timeList({ interval: 2000 })), ['00:00']);
    assert.deepEqual(timeInterval(15), { interval: 15, valid: true });
    assert.deepEqual(
      timeInterval(undefined),
      { interval: 30, valid: true },
      'not given: the default'
    );
    for (const bad of [0, -15, 7.5, Number.NaN, Infinity, '15']) {
      assert.deepEqual(
        timeInterval(bad),
        { interval: 30, valid: false },
        String(bad)
      );
    }
    assert.strictEqual(timeList({ interval: 0 }).length, 48, 'treated as 30');
  });

  test('injected, excluded and seconds', function (assert) {
    const list = timeList({
      interval: 60,
      injectTimes: ['09:45', '10:00', 'bad', '25:00'],
      excludeTimes: ['12:00', '09:45']
    });
    assert.strictEqual(
      list.length,
      25,
      'one added; one already on the interval; bad ones ignored'
    );
    const injected = list.find((entry) => entry.value === '09:45')!;
    assert.true(injected.injected);
    assert.strictEqual(
      injected.problem,
      'disabled',
      'an injected time can be excluded too'
    );
    assert.false(
      list.find((entry) => entry.value === '10:00')!.injected,
      'on the interval: not marked'
    );
    assert.strictEqual(
      list.find((entry) => entry.value === '12:00')!.problem,
      'disabled'
    );
    assert.deepEqual(
      values(list.slice(9, 12)),
      ['09:00', '09:45', '10:00'],
      'sorted'
    );
    assert.strictEqual(
      timeList({ seconds: true })[3]!.value,
      '01:30:00',
      'values carry seconds'
    );
  });

  test('@minTime and @maxTime', function (assert) {
    const list = timeList({ minTime: '06:00', maxTime: '22:00' });
    assert.strictEqual(list.find((e) => e.value === '05:30')!.problem, 'min');
    assert.strictEqual(
      list.find((e) => e.value === '06:00')!.problem,
      null,
      'inclusive'
    );
    assert.strictEqual(
      list.find((e) => e.value === '22:00')!.problem,
      null,
      'inclusive'
    );
    assert.strictEqual(list.find((e) => e.value === '22:30')!.problem, 'max');
    const t = (hour: number, minute: number, second = 0) => ({
      hour,
      minute,
      second
    });
    assert.strictEqual(
      timeProblem(t(22, 0, 1), { maxTime: '22:00' }),
      'max',
      'seconds count'
    );
    assert.strictEqual(timeProblem(t(22, 0, 1), { maxTime: '22:00:30' }), null);
    assert.strictEqual(
      timeProblem(t(12, 0, 30), { excludeTimes: ['12:00'] }),
      'disabled',
      'excluded by hour and minute'
    );
    assert.strictEqual(
      timeProblem(t(12, 0), { minTime: 'noon' }),
      null,
      'an unreadable limit is no limit'
    );
  });

  test('a gap day leaves out the times that do not exist (9 #19)', function (assert) {
    const list = timeList({ day: '2026-03-08', zone: NEW_YORK });
    assert.strictEqual(list.length, 46, '02:00 and 02:30 do not exist');
    assert.notOk(list.some((entry) => entry.value.startsWith('02:')));
    assert.strictEqual(
      iso(list.find((e) => e.value === '01:30')!.instant),
      '2026-03-08T06:30:00.000Z',
      'EST'
    );
    assert.strictEqual(
      iso(list.find((e) => e.value === '03:00')!.instant),
      '2026-03-08T07:00:00.000Z',
      'EDT'
    );
    const beirut = timeList({ day: '2026-03-29', zone: 'Asia/Beirut' });
    assert.strictEqual(
      beirut[0]!.value,
      '01:00',
      'midnight does not exist in Beirut that day'
    );
  });

  test('an overlap day lists each wall time once, at its first instant (9 #20)', function (assert) {
    const list = timeList({ day: '2026-11-01', zone: NEW_YORK });
    assert.strictEqual(list.length, 48);
    assert.strictEqual(list.filter((e) => e.value === '01:30').length, 1);
    assert.strictEqual(
      iso(list.find((e) => e.value === '01:30')!.instant),
      '2026-11-01T05:30:00.000Z',
      'the first 01:30 (EDT)'
    );
    assert.strictEqual(
      iso(list.find((e) => e.value === '02:00')!.instant),
      '2026-11-01T07:00:00.000Z',
      'EST'
    );
  });

  test('instant limits disable times by their instant', function (assert) {
    const list = timeList({
      day: '2026-11-24',
      zone: 'America/Mexico_City',
      minDate: '2026-11-24T15:00:00.000Z',
      maxDate: '2026-11-24'
    });
    assert.strictEqual(
      list.find((e) => e.value === '08:30')!.problem,
      'min',
      '14:30Z'
    );
    assert.strictEqual(
      list.find((e) => e.value === '09:00')!.problem,
      null,
      '15:00Z, inclusive'
    );
    assert.strictEqual(
      list.find((e) => e.value === '23:30')!.problem,
      null,
      'a date maximum allows its whole day'
    );
    const later = timeList({
      day: '2026-11-25',
      zone: 'America/Mexico_City',
      maxDate: '2026-11-24'
    });
    assert.true(
      later.every((e) => e.problem === 'max'),
      'the next day is past the date maximum'
    );
    const times = timeList({
      day: '2026-11-24',
      zone: 'utc',
      minTime: '10:00',
      minDate: '2026-11-24T08:00Z'
    });
    assert.strictEqual(
      times.find((e) => e.value === '09:00')!.problem,
      'min',
      '@minTime still applies'
    );
  });

  test('an instant against every rule (typed or native input)', function (assert) {
    const zone = 'America/Mexico_City';
    const at = (text: string) => Date.parse(text);
    const rules = {
      zone,
      minDate: '2026-11-02',
      maxDate: '2026-11-30T18:00:00.000Z',
      excludeDates: ['2026-11-11'],
      minTime: '08:00',
      maxTime: '20:00',
      excludeTimes: ['12:00']
    };
    assert.strictEqual(instantProblem(at('2026-11-24T15:30:00Z'), rules), null);
    assert.strictEqual(
      instantProblem(at('2026-11-02T05:59:00Z'), rules),
      'min',
      '1 November locally'
    );
    assert.strictEqual(
      instantProblem(at('2026-11-30T18:30:00Z'), rules),
      'max',
      'after the instant maximum'
    );
    assert.strictEqual(
      instantProblem(at('2026-11-11T15:00:00Z'), rules),
      'disabled',
      'an excluded day'
    );
    assert.strictEqual(
      instantProblem(at('2026-11-24T13:30:00Z'), rules),
      'min',
      '07:30 is before @minTime'
    );
    assert.strictEqual(
      instantProblem(at('2026-11-25T02:30:00Z'), rules),
      'max',
      '20:30 is after @maxTime'
    );
    assert.strictEqual(
      instantProblem(at('2026-11-24T18:00:00Z'), rules),
      'disabled',
      '12:00 is excluded'
    );
    assert.strictEqual(
      instantProblem(at('2026-11-24T15:30:00Z'), {
        zone,
        filterDate: (day) => day !== '2026-11-24'
      }),
      'disabled',
      '@filterDate on the zone day'
    );
  });

  test('choosing a time zeroes seconds; choosing a day keeps them (9 #27, #28)', function (assert) {
    const t = { hour: 9, minute: 30, second: 45 };
    assert.strictEqual(
      iso(instantAt('2026-11-24', t, 'utc')),
      '2026-11-24T09:30:00.000Z'
    );
    assert.strictEqual(
      iso(instantAt('2026-11-24', t, 'utc', true)),
      '2026-11-24T09:30:45.000Z',
      'with @seconds'
    );
    assert.strictEqual(
      iso(
        instantAt('2026-03-08', { hour: 2, minute: 30, second: 0 }, NEW_YORK)
      ),
      '2026-03-08T07:30:00.000Z',
      'a gap time resolves forward (03:30 EDT)'
    );
  });

  test('only a different wall clock changes the value (9 #21)', function (assert) {
    const second = Date.parse('2026-11-01T06:30:00.000Z');
    const shown = wallAt(second, NEW_YORK);
    assert.false(
      changesValue(second, shown, NEW_YORK),
      'the second 01:30 survives re-choosing 01:30'
    );
    assert.true(changesValue(second, wallOf('2026-11-01', 2, 0), NEW_YORK));
    assert.true(changesValue(null, shown, NEW_YORK), 'no value: any choice');
  });
});
