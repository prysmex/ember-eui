/**
 * CSV export (v0.4 06, CX1-CX6): `toCsv` from `@ember-eui/sheet/core`.
 */
import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  textFieldType,
  toCsv
} from '#src/core/index.ts';

import type { EuiSheetField, FieldType } from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const ctx = { types: builtInFieldTypes, messages: defaultMessages };

const TAGS = [
  { value: 'r', label: 'Red' },
  { value: 'g', label: 'Green' }
];

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'qty', label: 'Qty', type: 'number' },
  { id: 'due', label: 'Due', type: 'date' },
  { id: 'tags', label: 'Tags', type: 'multiSelect', options: TAGS }
];

const ROWS: Row[] = [
  { id: 'a', name: 'Ana', qty: 4, due: '2026-03-01', tags: ['r', 'g'] },
  { id: 'b', name: 'Beto', qty: null, due: null, tags: [] },
  { id: 'c', name: 'Caro', qty: 1.5, due: '2025-12-31', tags: ['g'] }
];

module('Unit | Sheet | csv export (v0.4 06)', function () {
  test('CX1 text, number, date and multi-select fields, with a header line', function (assert) {
    assert.strictEqual(
      toCsv(ctx, ROWS, FIELDS),
      [
        'Name,Qty,Due,Tags',
        'Ana,4,2026-03-01,"Red, Green"',
        'Beto,,,',
        'Caro,1.5,2025-12-31,Green'
      ].join('\r\n'),
      'dates as ISO, a multi-select as its labels joined by ", " (quoted: it has the delimiter), \\r\\n line ends, no line break at the end'
    );
    assert.strictEqual(
      toCsv(ctx, ROWS, [{ id: 'name' }, FIELDS[1]!]),
      'name,Qty\r\nAna,4\r\nBeto,\r\nCaro,1.5',
      'a field without a label is headed by its id; the fields given, in their order'
    );
    assert.strictEqual(
      toCsv(ctx, [], FIELDS),
      'Name,Qty,Due,Tags',
      'no records: the header line only'
    );
  });

  test('CX2 quoting: a comma, a quote and line breaks', function (assert) {
    const rows: Row[] = [
      { id: 'a', name: 'Lima, Perú' },
      { id: 'b', name: 'say "hi"' },
      { id: 'c', name: 'two\nlines' },
      { id: 'd', name: 'cr\r\nlf' },
      { id: 'e', name: 'plain; text' }
    ];
    assert.strictEqual(
      toCsv(ctx, rows, [{ id: 'name', label: 'Name' }], { headers: false }),
      [
        '"Lima, Perú"',
        '"say ""hi"""',
        '"two\nlines"',
        '"cr\r\nlf"',
        'plain; text'
      ].join('\r\n')
    );
  });

  test("CX3 delimiter ';' quotes cells with ';' and not cells with ','", function (assert) {
    const rows: Row[] = [{ id: 'a', name: 'a;b', note: '1,5' }];
    assert.strictEqual(
      toCsv(ctx, rows, [{ id: 'name', label: 'Name' }, { id: 'note' }], {
        delimiter: ';'
      }),
      'Name;note\r\n"a;b";1,5'
    );
    assert.strictEqual(
      toCsv(
        ctx,
        [{ id: 'a', qty: 1.5 }],
        [{ id: 'qty', type: 'number', decimalSeparator: ',' }],
        { delimiter: ';', headers: false }
      ),
      '1,5',
      'a number with a decimal comma stays unquoted with ";"'
    );
  });

  test("CX4 formula injection: a leading ' where a spreadsheet would run the cell", function (assert) {
    const fields: EuiSheetField<Row>[] = [
      { id: 'text' },
      { id: 'qty', type: 'number' },
      { id: 'phone', type: 'phone' },
      { id: 'pct', type: 'percent' }
    ];
    const rows: Row[] = [
      { id: 'a', text: '=SUM(A1)', qty: -5, phone: '+52 81 1234 5678' },
      { id: 'b', text: '@x', qty: null, phone: '', pct: -0.125 },
      { id: 'c', text: '-a', qty: 3 },
      { id: 'd', text: '+cmd|calc' },
      { id: 'e', text: '\tlead' },
      { id: 'f', text: 'a=b' }
    ];
    assert.strictEqual(
      toCsv(ctx, rows, fields, { headers: false }),
      [
        "'=SUM(A1),-5,+52 81 1234 5678,",
        "'@x,,,-12.5%",
        "'-a,3,,",
        "'+cmd|calc,,,",
        "'\tlead,,,",
        'a=b,,,'
      ].join('\r\n'),
      '=, @, a tab, and + or - not followed by a number are escaped; -5, a phone and -12.5% stay'
    );
    assert.strictEqual(
      toCsv(
        ctx,
        [{ id: 'a', text: '"=1"' }],
        [{ id: 'text', label: '=Total' }]
      ),
      `'=Total\r\n"""=1"""`,
      'a header label is escaped too; a cell starting with a quote is not a formula'
    );
    assert.strictEqual(
      toCsv(ctx, rows.slice(0, 1), fields, {
        headers: false,
        escapeFormulas: false
      }),
      '=SUM(A1),-5,+52 81 1234 5678,',
      'escapeFormulas: false writes the texts as they are'
    );
    assert.strictEqual(
      toCsv(ctx, [{ id: 'a', text: '=a,b' }], [{ id: 'text' }], {
        headers: false
      }),
      `"'=a,b"`,
      'escaped first, then quoted'
    );
  });

  test('CX5 headers: false leaves out the first line', function (assert) {
    assert.strictEqual(
      toCsv(ctx, ROWS.slice(0, 1), FIELDS, { headers: false }),
      'Ana,4,2026-03-01,"Red, Green"'
    );
    assert.strictEqual(
      toCsv(ctx, [], FIELDS, { headers: false }),
      '',
      'no records and no header: empty'
    );
  });

  test("CX6 an app type's copyText is used (else its format)", function (assert) {
    const money: FieldType<number | null> = {
      ...(textFieldType as unknown as FieldType<number | null>),
      format: (value) => (value == null ? '' : `$${value}`),
      copyText: (value) => (value == null ? '' : `${value} USD`)
    };
    const shown: FieldType<number | null> = {
      ...(textFieldType as unknown as FieldType<number | null>),
      format: (value) => (value == null ? '' : `#${value}`)
    };
    const types = { ...builtInFieldTypes, money, shown };
    assert.strictEqual(
      toCsv(
        { types, messages: defaultMessages },
        [{ id: 'a', price: 12, code: 7 }],
        [
          { id: 'price', label: 'Price', type: 'money' },
          { id: 'code', label: 'Code', type: 'shown' }
        ]
      ),
      'Price,Code\r\n12 USD,#7'
    );
  });
});
