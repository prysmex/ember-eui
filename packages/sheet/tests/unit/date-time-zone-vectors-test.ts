/**
 * The zone vectors shared with core (`EuiDatePicker`, DESIGN 5.2 and 10.1):
 * the same algorithm lives in `src/core/field-types/date-time.ts` and in
 * core's `utils/date/zone.ts`, because `src/core` may not import from core.
 * Both suites run this file so the two copies cannot drift. Driven through
 * the public API: `parse` for wall clock to instant, `dateTimeLocalValue`
 * for instant to wall clock, both with seconds.
 */
import { module, test } from 'qunit';

import {
  dateTimeFieldType,
  dateTimeLocalValue,
  defaultMessages,
  validTimeZone
} from '#src/core/index.ts';

import type { DateTimeField } from '#src/core/index.ts';

interface Vectors {
  toInstant: { zone: string; wall: string; instant: string; note: string }[];
  toWall: { zone: string; instant: string; wall: string; note: string }[];
  zones: { zone: string; valid: boolean }[];
  unknownZoneReadsAsUtc: { zone: string; wall: string; instant: string };
}

// a glob, not an import: TypeScript does not resolve it across packages
const files = import.meta.glob(
  '../../../core/tests/unit/utils/date-zone-vectors.json',
  { import: 'default', eager: true }
) as Record<string, Vectors>;
const vectors = Object.values(files)[0]!;

function field(timeZone: string): DateTimeField {
  return { id: 'at', type: 'dateTime', timeZone, seconds: true };
}

function parse(text: string, timeZone: string): unknown {
  const result = dateTimeFieldType.parse(text, field(timeZone), {
    record: undefined,
    messages: defaultMessages,
    source: 'edit'
  });
  return 'value' in result ? result.value : result;
}

module('Unit | Sheet | dateTime zone vectors (shared with core)', function () {
  test('ZV1 the vector file is found', function (assert) {
    assert.strictEqual(Object.keys(files).length, 1, 'one file');
    assert.true(vectors.toInstant.length >= 30, 'toInstant');
    assert.true(vectors.toWall.length >= 30, 'toWall');
  });

  test('ZV2 wall clock to instant (gaps forward, overlaps to the first)', function (assert) {
    for (const vector of vectors.toInstant) {
      assert.strictEqual(
        parse(vector.wall, vector.zone),
        vector.instant,
        `${vector.zone} ${vector.wall}: ${vector.note}`
      );
    }
  });

  test('ZV3 instant to wall clock', function (assert) {
    for (const vector of vectors.toWall) {
      assert.strictEqual(
        dateTimeLocalValue(vector.instant, field(vector.zone)),
        vector.wall,
        `${vector.zone} ${vector.instant}: ${vector.note}`
      );
    }
  });

  test('ZV4 zone validity, and an unknown zone reads as UTC', function (assert) {
    for (const { zone, valid } of vectors.zones) {
      assert.strictEqual(validTimeZone(zone), valid, zone);
    }
    const unknown = vectors.unknownZoneReadsAsUtc;
    assert.strictEqual(parse(unknown.wall, unknown.zone), unknown.instant);
    assert.strictEqual(
      dateTimeLocalValue(unknown.instant, field(unknown.zone)),
      unknown.wall
    );
  });
});
