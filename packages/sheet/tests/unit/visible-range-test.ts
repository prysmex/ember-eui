import { module, test } from 'qunit';

import { buildRowModel } from '#src/core/index.ts';
import { changed, toRecordRange } from '#src/-private/visible-range.ts';

module('Unit | visible range (v0.4 09)', function () {
  test('VR6 toRecordRange: the grid rows in view as positions in @records', function (assert) {
    // 0 header A, 1 r0, 2 r1, 3 add A, 4 header B (collapsed, nothing
    // loaded), 5 header C, 6 r2, 7 r3, 8 r4, 9 add C
    const grouped = buildRowModel({
      recordCount: 5,
      addRow: true,
      groups: [
        { depth: 0, loaded: 2 },
        { depth: 0, loaded: 0, collapsed: true },
        { depth: 0, loaded: 3 }
      ]
    });
    const range = (start: number, stop: number) =>
      toRecordRange({ start, stop }, grouped, 5);

    assert.deepEqual(range(0, 9), { first: 0, last: 4, count: 5 }, 'all');
    assert.deepEqual(
      range(2, 6),
      { first: 1, last: 2, count: 5 },
      'across groups'
    );
    assert.deepEqual(
      range(3, 7),
      { first: 2, last: 3, count: 5 },
      'from an add row'
    );
    assert.deepEqual(
      range(0, 1),
      { first: 0, last: 0, count: 5 },
      'a header, then r0'
    );
    assert.strictEqual(range(3, 5), null, 'an add row and headers only');
    assert.strictEqual(range(4, 4), null, 'a collapsed header only');
    assert.strictEqual(range(9, 9), null, 'the last add row only');

    // without groups: the identity; the add row is not a record
    const flat = buildRowModel({ recordCount: 40, addRow: true });
    assert.deepEqual(
      toRecordRange({ start: 30, stop: 40 }, flat, 40),
      { first: 30, last: 39, count: 40 },
      'the end, with the add row in view'
    );
    assert.strictEqual(
      toRecordRange(
        { start: 0, stop: 0 },
        buildRowModel({ recordCount: 0, addRow: true }),
        0
      ),
      null,
      'no records'
    );
  });

  test('VR7 changed: first, last or count', function (assert) {
    const range = { first: 0, last: 10, count: 100 };
    assert.true(changed(null, range), 'nothing reported yet');
    assert.false(changed(range, { ...range }), 'the same values');
    assert.true(changed(range, { ...range, first: 1 }), 'first');
    assert.true(changed(range, { ...range, last: 11 }), 'last');
    assert.true(changed(range, { ...range, count: 150 }), 'count');
  });
});
