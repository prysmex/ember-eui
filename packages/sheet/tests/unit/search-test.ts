import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  findMatches
} from '#src/core/index.ts';

import type { EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const ctx = {
  types: builtInFieldTypes,
  messages: defaultMessages,
  getRecordId: (row: Row) => row.id
};

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    options: [
      { value: 'open', label: 'Open' },
      { value: 'wip', label: 'Painting' }
    ]
  },
  { id: 'hours', label: 'Hours', type: 'number' }
];

const ROWS: Row[] = [
  { id: 'a', name: 'Paint the fence', status: 'open', hours: 12 },
  { id: 'b', name: 'Buy nails', status: 'wip', hours: 3 },
  { id: 'c', name: 'Pintura española', status: null, hours: 120 }
];

module('Unit | Sheet | findMatches', function () {
  test('SN5 order, case, a select label, accents, an empty term', function (assert) {
    assert.deepEqual(
      findMatches(ctx, ROWS, FIELDS, 'PAINT'),
      [
        { recordId: 'a', fieldId: 'name' },
        { recordId: 'b', fieldId: 'status' }
      ],
      'by row then field, without case; the select by its label "Painting"'
    );
    assert.deepEqual(
      findMatches(ctx, ROWS, FIELDS, 'wip'),
      [],
      'the stored value is not shown text'
    );
    assert.deepEqual(
      findMatches(ctx, ROWS, FIELDS, 'espanola'),
      [{ recordId: 'c', fieldId: 'name' }],
      'without accents, as @highlight marks'
    );
    assert.deepEqual(
      findMatches(ctx, ROWS, FIELDS, '12'),
      [
        { recordId: 'a', fieldId: 'hours' },
        { recordId: 'c', fieldId: 'hours' }
      ],
      'numbers by their formatted text'
    );
    assert.deepEqual(findMatches(ctx, ROWS, FIELDS, ''), [], 'empty term');
    assert.deepEqual(
      findMatches(ctx, ROWS, [FIELDS[0]!], 'paint'),
      [{ recordId: 'a', fieldId: 'name' }],
      'only the given fields'
    );
  });
});
