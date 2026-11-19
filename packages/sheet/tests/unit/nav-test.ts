import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  edgeTarget
} from '#src/core/index.ts';

import type { EuiSheetField, Pos, SheetContext } from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

/** A grid of text cells from a picture: `x` is a value, `.` empty. */
function ctx(picture: string[]): SheetContext<Row> {
  const width = picture[0]!.length;
  const fields: EuiSheetField<Row>[] = Array.from(
    { length: width },
    (_, i) => ({
      id: `c${i}`
    })
  );
  const records = picture.map((line, row) => {
    const record: Row = { id: `r${row}` };
    [...line].forEach((char, col) => {
      record[`c${col}`] = char === '.' ? '' : char;
    });
    return record;
  });
  return {
    records,
    fields,
    getRecordId: (record) => record.id,
    types: builtInFieldTypes,
    messages: defaultMessages
  };
}

const at = (row: number, col: number): Pos => ({ row, col });

module('Unit | Sheet | nav', function () {
  test('NV1 edgeTarget in the four directions, over gaps, at the edges', function (assert) {
    const sheet = ctx([
      'xx.xx', // r0
      'x....', // r1
      'x...x', // r2
      '.....', // r3
      'x..xx' // r4
    ]);
    // down: inside a block, to its end; from its end, over the gap to the next value
    assert.deepEqual(edgeTarget(sheet, at(0, 0), 'down'), at(2, 0));
    assert.deepEqual(edgeTarget(sheet, at(2, 0), 'down'), at(4, 0));
    // from an empty cell: the next value
    assert.deepEqual(
      edgeTarget(sheet, at(0, 2), 'down'),
      at(4, 2),
      'none: the last cell'
    );
    assert.deepEqual(edgeTarget(sheet, at(1, 4), 'down'), at(2, 4));
    // at the edge: stays
    assert.deepEqual(edgeTarget(sheet, at(4, 0), 'down'), at(4, 0));
    // up
    assert.deepEqual(edgeTarget(sheet, at(4, 0), 'up'), at(2, 0));
    assert.deepEqual(edgeTarget(sheet, at(2, 0), 'up'), at(0, 0));
    assert.deepEqual(edgeTarget(sheet, at(0, 3), 'up'), at(0, 3));
    // right
    assert.deepEqual(edgeTarget(sheet, at(0, 0), 'right'), at(0, 1));
    assert.deepEqual(edgeTarget(sheet, at(0, 1), 'right'), at(0, 3));
    assert.deepEqual(
      edgeTarget(sheet, at(1, 0), 'right'),
      at(1, 4),
      'none: the last cell'
    );
    assert.deepEqual(edgeTarget(sheet, at(4, 3), 'right'), at(4, 4));
    // left
    assert.deepEqual(edgeTarget(sheet, at(0, 4), 'left'), at(0, 3));
    assert.deepEqual(edgeTarget(sheet, at(0, 3), 'left'), at(0, 1));
    assert.deepEqual(edgeTarget(sheet, at(2, 4), 'left'), at(2, 0));
    assert.deepEqual(edgeTarget(sheet, at(3, 0), 'left'), at(3, 0));
    // the add row (one past the records) counts as empty
    assert.deepEqual(edgeTarget(sheet, at(5, 0), 'up'), at(4, 0));
    assert.deepEqual(edgeTarget(sheet, at(5, 0), 'down'), at(5, 0));
  });
});
