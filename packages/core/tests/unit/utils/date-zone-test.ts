/**
 * Zones (DESIGN 5.2). Zones are named explicitly; only the 'local' group
 * depends on the machine's zone, and it asserts round trips only.
 */
import { module, test } from 'qunit';

import {
  dayAt,
  instantOf,
  normalizeTimeZone,
  offsetMinutes,
  realWall,
  sameWall,
  startOfDayIn,
  todayIn,
  validTimeZone,
  wallAt,
  wallExists,
  wallMs,
  wallOf,
  withDay
} from '#src/utils/date/zone.ts';

import type { Wall } from '#src/utils/date/zone.ts';

interface Vectors {
  toInstant: { zone: string; wall: string; instant: string; note: string }[];
  toWall: { zone: string; instant: string; wall: string; note: string }[];
  zones: { zone: string; valid: boolean }[];
  unknownZoneReadsAsUtc: { zone: string; wall: string; instant: string };
}

// the vectors the sheet's suite runs too (`date-zone-vectors.json`)
const files = import.meta.glob('./date-zone-vectors.json', {
  import: 'default',
  eager: true
}) as Record<string, Vectors>;
const vectors = Object.values(files)[0]!;

function wallFromText(text: string): Wall {
  const [date, time] = text.split('T') as [string, string];
  const [h, mi, s] = time.split(':').map(Number) as [number, number, number];
  return wallOf(date, h, mi, s);
}

function wallText(wall: Wall): string {
  const p = (n: number, w = 2) => String(n).padStart(w, '0');
  return `${p(wall.y, 4)}-${p(wall.m)}-${p(wall.d)}T${p(wall.h)}:${p(wall.mi)}:${p(wall.s)}`;
}

const iso = (ms: number) => new Date(ms).toISOString();
const ms = (text: string) => Date.parse(text);

const NEW_YORK = 'America/New_York';

module('Unit | utils | date | zone', function () {
  test('the shared vectors: wall clock to instant', function (assert) {
    assert.strictEqual(
      Object.keys(files).length,
      1,
      'the vector file is found'
    );
    assert.true(
      vectors.toInstant.length >= 30,
      `${vectors.toInstant.length} vectors`
    );
    for (const vector of vectors.toInstant) {
      const zone = normalizeTimeZone(vector.zone);
      assert.strictEqual(
        iso(instantOf(wallFromText(vector.wall), zone)),
        vector.instant,
        `${vector.zone} ${vector.wall}: ${vector.note}`
      );
    }
  });

  test('the shared vectors: instant to wall clock', function (assert) {
    assert.true(
      vectors.toWall.length >= 30,
      `${vectors.toWall.length} vectors`
    );
    for (const vector of vectors.toWall) {
      const zone = normalizeTimeZone(vector.zone);
      assert.strictEqual(
        wallText(wallAt(ms(vector.instant), zone)),
        vector.wall,
        `${vector.zone} ${vector.instant}: ${vector.note}`
      );
    }
  });

  test('the shared vectors: zone validity, and an unknown zone reads as UTC', function (assert) {
    assert.true(vectors.zones.length >= 4);
    for (const { zone, valid } of vectors.zones) {
      assert.strictEqual(validTimeZone(zone), valid, zone);
    }
    const unknown = vectors.unknownZoneReadsAsUtc;
    assert.strictEqual(
      iso(instantOf(wallFromText(unknown.wall), unknown.zone)),
      unknown.instant,
      'no throw: the wall clock as UTC (9 #24)'
    );
    assert.strictEqual(
      wallText(wallAt(ms(unknown.instant), unknown.zone)),
      unknown.wall
    );
  });

  test('normalizing and validating zones', function (assert) {
    assert.strictEqual(normalizeTimeZone(undefined), 'local');
    assert.strictEqual(normalizeTimeZone(null), 'local');
    assert.strictEqual(normalizeTimeZone(''), 'local');
    assert.strictEqual(normalizeTimeZone('local'), 'local');
    assert.strictEqual(normalizeTimeZone('UTC'), 'utc');
    assert.strictEqual(normalizeTimeZone('Utc'), 'utc');
    assert.strictEqual(normalizeTimeZone(NEW_YORK), NEW_YORK);
    assert.true(validTimeZone(undefined));
    assert.true(validTimeZone('local'));
    assert.true(validTimeZone('UTC'));
    assert.true(validTimeZone('Europe/Madrid'));
    assert.false(validTimeZone('Mars/Olympus'), '9 #24');
  });

  test('round trips every 30 minutes across both New York transitions', function (assert) {
    // every wall clock that exists maps to an instant that shows it again
    for (const day of ['2026-03-08', '2026-11-01']) {
      for (let minutes = 0; minutes < 24 * 60; minutes += 30) {
        const wall = wallOf(day, Math.floor(minutes / 60), minutes % 60);
        const at = instantOf(wall, NEW_YORK);
        if (wallExists(wall, NEW_YORK)) {
          assert.true(
            sameWall(wallAt(at, NEW_YORK), wall),
            `${day} ${minutes}`
          );
        } else {
          assert.strictEqual(
            day,
            '2026-03-08',
            'only the spring day has a gap'
          );
          assert.strictEqual(
            wallMs(wallAt(at, NEW_YORK)) - wallMs(wall),
            3_600_000,
            `${day} ${minutes}: forward by the gap`
          );
        }
      }
    }
    assert.false(wallExists(wallOf('2026-03-08', 2, 30), NEW_YORK));
    assert.true(wallExists(wallOf('2026-11-01', 1, 30), NEW_YORK));
  });

  test('a day change keeps the wall time and resolves again (9 #22, #23, #27)', function (assert) {
    // 01:30 EDT on 31 October; 1 November has two 01:30s
    const october = ms('2026-10-31T05:30:00.000Z');
    assert.strictEqual(
      iso(withDay(october, '2026-11-01', NEW_YORK)),
      '2026-11-01T05:30:00.000Z',
      'the first 01:30 of 1 November'
    );
    // 02:30 EST on 7 March; 8 March has no 02:30
    const march = ms('2026-03-07T07:30:00.000Z');
    assert.strictEqual(
      iso(withDay(march, '2026-03-08', NEW_YORK)),
      '2026-03-08T07:30:00.000Z',
      '03:30 EDT on 8 March'
    );
    // seconds and ms are kept when only the day changes
    const precise = ms('2026-11-24T15:30:45.123Z');
    assert.strictEqual(
      iso(withDay(precise, '2026-11-25', 'utc')),
      '2026-11-25T15:30:45.123Z'
    );
    assert.strictEqual(
      iso(withDay(precise, '2026-12-25', NEW_YORK)),
      '2026-12-25T15:30:45.123Z',
      'the same wall clock, 10:30:45.123 EST'
    );
  });

  test('a stored second occurrence keeps its wall clock (9 #21)', function (assert) {
    const second = ms('2026-11-01T06:30:00.000Z');
    const first = ms('2026-11-01T05:30:00.000Z');
    assert.true(
      sameWall(wallAt(second, NEW_YORK), wallAt(first, NEW_YORK)),
      'both read 01:30, so the picker sees no change to emit'
    );
    assert.strictEqual(
      iso(instantOf(wallAt(second, NEW_YORK), NEW_YORK)),
      iso(first),
      'resolving the wall clock again would give the first: the picker must not'
    );
  });

  test('today in a zone, from an injected clock (9 #25)', function (assert) {
    // 23:30 on 24 November in Mexico City is already 25 November in UTC and Tokyo
    const now = ms('2026-11-25T05:30:00.000Z');
    assert.strictEqual(todayIn('America/Mexico_City', now), '2026-11-24');
    assert.strictEqual(todayIn('utc', now), '2026-11-25');
    assert.strictEqual(todayIn('Asia/Tokyo', now), '2026-11-25');
    assert.strictEqual(
      todayIn('Pacific/Kiritimati', ms('2026-11-24T10:30:00.000Z')),
      '2026-11-25',
      'UTC+14'
    );
    assert.strictEqual(
      todayIn('Mars/Olympus', now),
      '2026-11-25',
      'unknown: UTC'
    );
    assert.strictEqual(dayAt(now, NEW_YORK), '2026-11-25');
    const local = new Date(now);
    const expected = `${local.getFullYear()}-${String(local.getMonth() + 1).padStart(2, '0')}-${String(local.getDate()).padStart(2, '0')}`;
    assert.strictEqual(
      todayIn(undefined, now),
      expected,
      'no zone: the browser'
    );
  });

  test('the start of a day, also when midnight does not exist', function (assert) {
    assert.strictEqual(
      iso(startOfDayIn('2026-11-24', 'America/Mexico_City')),
      '2026-11-24T06:00:00.000Z'
    );
    assert.strictEqual(
      iso(startOfDayIn('2026-03-29', 'Asia/Beirut')),
      '2026-03-28T22:00:00.000Z',
      'Beirut springs from 00:00 to 01:00: the day starts at 01:00'
    );
    assert.strictEqual(
      dayAt(startOfDayIn('2026-03-29', 'Asia/Beirut'), 'Asia/Beirut'),
      '2026-03-29'
    );
  });

  test('real wall clocks', function (assert) {
    assert.true(realWall(wallOf('2026-11-24', 23, 59, 59)));
    assert.false(realWall(wallOf('2026-11-24', 24, 0)), 'hour 24');
    assert.false(realWall(wallOf('2026-11-24', 12, 60)), 'minute 60');
    assert.false(realWall(wallOf('2026-02-31', 12, 0)), '31 February');
    assert.true(realWall(wallOf('0001-01-01')), 'year 0001');
  });

  test('local: round trips only', function (assert) {
    for (const text of [
      '2026-01-15T12:00:00.000Z',
      '2026-07-15T12:00:00.000Z',
      '2026-11-24T15:30:45.123Z'
    ]) {
      const at = ms(text);
      const wall = wallAt(at, 'local');
      assert.strictEqual(iso(instantOf(wall, 'local')), text, text);
    }
  });

  test('fixed offsets: parsing, normalizing, validity (DESIGN 17)', function (assert) {
    assert.strictEqual(offsetMinutes('+05:30'), 330);
    assert.strictEqual(offsetMinutes('-02:00'), -120);
    assert.strictEqual(offsetMinutes('+0530'), 330, '+HHMM, as Intl');
    assert.strictEqual(offsetMinutes('-03'), -180, '+HH, as Intl');
    assert.strictEqual(offsetMinutes('+23:59'), 23 * 60 + 59, 'the largest');
    assert.strictEqual(offsetMinutes('-00:00'), 0);
    for (const text of [
      '+24:00',
      '+05:60',
      '+5:30',
      '05:30',
      'UTC+05:30',
      'GMT-2',
      '+05:30:00',
      '',
      null,
      undefined,
      NEW_YORK
    ]) {
      assert.strictEqual(offsetMinutes(text), null, String(text));
    }
    assert.strictEqual(normalizeTimeZone('+0530'), '+05:30');
    assert.strictEqual(normalizeTimeZone('-02'), '-02:00');
    assert.strictEqual(normalizeTimeZone('-00:00'), '+00:00');
    assert.strictEqual(normalizeTimeZone('+05:30'), '+05:30');
    assert.true(validTimeZone('-03:00'));
    assert.false(validTimeZone('+24:00'));
    assert.false(validTimeZone('UTC-03:00'), 'not a form Intl reads');
  });

  test('a fixed offset has no gap and no overlap', function (assert) {
    // New York's two change days: every wall clock exists once at -02:00
    for (const zone of ['-02:00', '+05:30', '+14:00', '-12:00']) {
      for (const day of ['2026-03-08', '2026-11-01', '2026-03-29']) {
        for (let minutes = 0; minutes < 24 * 60; minutes += 30) {
          const wall = wallOf(day, Math.floor(minutes / 60), minutes % 60);
          assert.true(wallExists(wall, zone), `${zone} ${day} ${minutes}`);
          const at = instantOf(wall, zone);
          assert.strictEqual(
            at,
            wallMs(wall) - offsetMinutes(zone)! * 60_000,
            `${zone} ${day} ${minutes}: one instant, at the offset`
          );
        }
      }
    }
    // an hour later in UTC is always an hour later on the wall
    const start = ms('2026-11-01T04:00:00.000Z');
    for (let h = 0; h < 6; h++) {
      const wall = wallAt(start + h * 3_600_000, '-02:00');
      assert.strictEqual(wall.h, 2 + h, `${h}h later`);
    }
  });

  test('a fixed offset: today, the start of a day, a day change', function (assert) {
    const now = ms('2026-11-25T01:30:00.000Z');
    assert.strictEqual(todayIn('-02:00', now), '2026-11-24');
    assert.strictEqual(todayIn('+05:30', now), '2026-11-25');
    assert.strictEqual(todayIn('-0200', now), '2026-11-24', 'normalized');
    assert.strictEqual(
      iso(startOfDayIn('2026-11-24', '-03:00')),
      '2026-11-24T03:00:00.000Z'
    );
    assert.strictEqual(
      iso(withDay(ms('2026-10-31T05:30:45.123Z'), '2026-11-01', '-02:00')),
      '2026-11-01T05:30:45.123Z',
      'the same wall time, seconds kept'
    );
    assert.strictEqual(
      dayAt(ms('2026-11-24T23:00:00.000Z'), '+01:00'),
      '2026-11-25'
    );
  });
});
