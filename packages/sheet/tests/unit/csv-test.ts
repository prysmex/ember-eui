/**
 * CSV export (v0.4 06, CX1-CX6): `toCsv`; CSV import (v0.4 07, CI1-CI6):
 * `parseCsv`, `importMatrix` and its header matcher `matchHeader` (one of
 * batch E's three additions), from `@ember-eui/sheet/core`.
 */
import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  importMatrix,
  matchHeader,
  normalizeHeader,
  parseCsv,
  rangeMatrix,
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

const PEOPLE_FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name', importAliases: ['nombre', 'producto'] },
  { id: 'price', label: 'Unit price', type: 'number' },
  { id: 'due', label: 'Due date', type: 'date' },
  { id: 'notes' }
];

module('Unit | Sheet | csv import (v0.4 07)', function () {
  test('CI1 parseCsv: quoted cells with commas and line breaks, \\r\\n, a trailing empty line dropped', function (assert) {
    assert.deepEqual(
      parseCsv(
        'Name,Note\r\n"Lima, Perú","two\r\nlines"\r\nAna,"say ""hi"""\r\n'
      ),
      [
        ['Name', 'Note'],
        ['Lima, Perú', 'two\nlines'],
        ['Ana', 'say "hi"']
      ]
    );
    assert.deepEqual(
      parseCsv('a,b\n\n'),
      [['a', 'b'], ['']],
      'only one trailing empty line is dropped'
    );
    assert.deepEqual(parseCsv('a,,c'), [['a', '', 'c']], 'empty cells kept');
    assert.deepEqual(
      parseCsv('﻿Name,Qty\n1,2'),
      [
        ['Name', 'Qty'],
        ['1', '2']
      ],
      'a byte-order mark is dropped'
    );
    assert.deepEqual(
      parseCsv('"open,b\nc,d'),
      [
        ['"open', 'b'],
        ['c', 'd']
      ],
      'a quote that never closes is plain text'
    );
    assert.deepEqual(
      parseCsv('a "b" c,d'),
      [['a "b" c', 'd']],
      'a quote inside a cell is plain'
    );
    assert.deepEqual(parseCsv(''), [['']], 'empty text: one empty cell');
  });

  test('CI2 the delimiter is detected for comma, semicolon and tab files', function (assert) {
    assert.deepEqual(parseCsv('a,b,c\n1,2,3'), [
      ['a', 'b', 'c'],
      ['1', '2', '3']
    ]);
    assert.deepEqual(
      parseCsv('Nombre;Precio\nCafé;1,5'),
      [
        ['Nombre', 'Precio'],
        ['Café', '1,5']
      ],
      'semicolons: a decimal comma stays in its cell'
    );
    assert.deepEqual(parseCsv('a\tb\n1,5\t2'), [
      ['a', 'b'],
      ['1,5', '2']
    ]);
    assert.deepEqual(
      parseCsv('"a;b;c",d,e\n1,2,3'),
      [
        ['a;b;c', 'd', 'e'],
        ['1', '2', '3']
      ],
      'delimiters inside quotes are not counted'
    );
    assert.deepEqual(
      parseCsv('"x\ny;z;w",a\n1,2'),
      [
        ['x\ny;z;w', 'a'],
        ['1', '2']
      ],
      'the first line ends at a line break outside quotes'
    );
    assert.deepEqual(
      parseCsv('one\ntwo'),
      [['one'], ['two']],
      'none: one column'
    );
    assert.deepEqual(
      parseCsv('a;b,c', { delimiter: ';' }),
      [['a', 'b,c']],
      'an explicit delimiter wins'
    );
    assert.deepEqual(parseCsv('a;b,c'), [['a;b', 'c']], 'a tie is a comma');
  });

  test('CI3 headers by label, by id and ignoring case; an extra column in unmatched; fieldIds in the file order', function (assert) {
    const matrix = parseCsv(
      'NOTES , due date,Extra,unit PRICE,Name\nn1,01/02/2026,x,3,Ana\nn2,,y,4,Bo'
    );
    const result = importMatrix(matrix, PEOPLE_FIELDS);
    assert.deepEqual(result.fieldIds, ['notes', 'due', 'price', 'name']);
    assert.deepEqual(result.unmatched, ['Extra']);
    assert.deepEqual(result.rows, [
      ['n1', '01/02/2026', '3', 'Ana'],
      ['n2', '', '4', 'Bo']
    ]);
    assert.deepEqual(
      importMatrix([['Name', 'Name', 'name']], PEOPLE_FIELDS),
      { rows: [], fieldIds: ['name'], unmatched: ['Name', 'name'] },
      'a field takes one column: the first; the others are unmatched'
    );
    assert.deepEqual(
      importMatrix(
        [
          ['Name', 'Notes'],
          ['Ana', 'n', 'beyond'],
          ['Bo'],
          [' ', ''],
          ['Caro', 'm']
        ],
        PEOPLE_FIELDS
      ),
      {
        rows: [['Ana', 'n'], ['Bo'], ['Caro', 'm']],
        fieldIds: ['name', 'notes'],
        unmatched: []
      },
      'a short line gives a short row; a blank line is dropped; a cell past the header is dropped'
    );
    assert.deepEqual(
      importMatrix([['', 'Name']], PEOPLE_FIELDS),
      { rows: [], fieldIds: ['name'], unmatched: [''] },
      'an empty header matches nothing'
    );
    assert.deepEqual(
      importMatrix(
        [
          ['Ana', '3'],
          ['Bo', '4', 'x', 'y', 'z']
        ],
        PEOPLE_FIELDS,
        { headers: false }
      ),
      {
        rows: [
          ['Ana', '3'],
          ['Bo', '4', 'x', 'y']
        ],
        fieldIds: ['name', 'price', 'due', 'notes'],
        unmatched: []
      },
      'headers: false: the columns go to the fields by position, every line is a row'
    );
  });

  test('CI4 mapping overrides a header match', function (assert) {
    const matrix = [
      ['Name', 'Price', 'Notes', 'Other'],
      ['Ana', '3', 'n', 'o']
    ];
    assert.deepEqual(
      importMatrix(matrix, PEOPLE_FIELDS, {
        mapping: { 0: 'notes', 1: 'price', 2: null, 3: 'name' }
      }),
      {
        rows: [['Ana', '3', 'o']],
        fieldIds: ['notes', 'price', 'name'],
        unmatched: ['Notes']
      },
      'columns go where mapping says; null drops one'
    );
    assert.deepEqual(
      importMatrix(matrix, PEOPLE_FIELDS, { mapping: { 3: 'name' } }),
      {
        rows: [['3', 'n', 'o']],
        fieldIds: ['price', 'notes', 'name'],
        unmatched: ['Name']
      },
      'a field mapping names is not matched by another header; the rest still match (Price by id)'
    );
    assert.deepEqual(
      importMatrix(matrix, PEOPLE_FIELDS, {
        mapping: { 0: 'missing', 1: 'notes', 2: 'notes' }
      }),
      {
        rows: [['3']],
        fieldIds: ['notes'],
        unmatched: ['Name', 'Notes', 'Other']
      },
      'an unknown id drops the column; a field mapped twice keeps its first column'
    );
    assert.deepEqual(
      importMatrix([['Ana', 'x']], PEOPLE_FIELDS, {
        headers: false,
        mapping: { 0: 'notes' }
      }),
      { rows: [['Ana', 'x']], fieldIds: ['notes', 'price'], unmatched: [] },
      'without headers, mapping wins over position and takes its field'
    );
  });

  test('CI5 a round trip: toCsv, parseCsv, importMatrix give the same texts', function (assert) {
    const fields: EuiSheetField<Row>[] = [
      { id: 'name', label: 'Name' },
      { id: 'qty', label: 'Qty', type: 'number' },
      { id: 'due', label: 'Due', type: 'date' },
      { id: 'tags', label: 'Tags', type: 'multiSelect', options: TAGS },
      { id: 'note', label: 'Note' }
    ];
    const rows: Row[] = [
      {
        id: 'a',
        name: 'Lima, Perú',
        qty: -4,
        due: '2026-03-01',
        tags: ['r', 'g'],
        note: 'say "hi"\nbye'
      },
      { id: 'b', name: '=SUM(A1)', qty: 1.5, due: null, tags: [], note: '' }
    ];
    const texts = rangeMatrix(
      { ...ctx, records: rows, fields, getRecordId: (row: Row) => row.id },
      { top: 0, left: 0, bottom: 1, right: 4 }
    );
    for (const delimiter of [',', ';', '\t']) {
      const csv = toCsv(ctx, rows, fields, {
        delimiter,
        escapeFormulas: false
      });
      const result = importMatrix(parseCsv(csv), fields);
      assert.deepEqual(result.fieldIds, ['name', 'qty', 'due', 'tags', 'note']);
      assert.deepEqual(
        result.rows,
        texts,
        `delimiter ${JSON.stringify(delimiter)}`
      );
    }
    const escaped = importMatrix(parseCsv(toCsv(ctx, rows, fields)), fields);
    assert.strictEqual(
      escaped.rows[1]![0],
      "'=SUM(A1)",
      "with escaping on, an escaped cell keeps its ' (by design)"
    );
  });

  test('CI6 matchHeader: case, accents, spaces, _ and - ignored; aliases first, then label, then id', function (assert) {
    const fields: EuiSheetField<Row>[] = [
      {
        id: 'name',
        label: 'Name of product',
        importAliases: ['Nombre del producto', 'producto']
      },
      { id: 'year', label: 'Año' },
      { id: 'product' },
      { id: 'code', label: 'producto' }
    ];
    const id = (header: string) =>
      matchHeader(header, fields)?.field.id ?? null;
    const by = (header: string) => matchHeader(header, fields)?.by ?? null;
    assert.strictEqual(
      id('Nombre_del  producto '),
      'name',
      'alias, with _ and spaces'
    );
    assert.strictEqual(id('nombre-del-PRODUCTO'), 'name');
    assert.strictEqual(id('  NAME OF   product'), 'name', 'label');
    assert.strictEqual(by('NAME OF product'), 'label');
    assert.strictEqual(id('ano'), 'year', 'accents ignored (ñ is n)');
    assert.strictEqual(id('AÑO'), 'year');
    assert.strictEqual(id('Product'), 'product', 'id');
    assert.strictEqual(by('Product'), 'id');
    assert.strictEqual(
      id('Producto'),
      'name',
      "an alias wins over another field's label"
    );
    assert.strictEqual(by('Producto'), 'alias');
    assert.strictEqual(id(''), null, 'an empty header');
    assert.strictEqual(id(' _ '), null, 'only separators');
    assert.strictEqual(id('Price'), null);
    assert.strictEqual(
      normalizeHeader('  Nombre_del--Producto  '),
      'nombre del producto'
    );
    assert.strictEqual(
      normalizeHeader('Fecha de Creación'),
      'fecha de creacion'
    );
    // importMatrix uses it
    assert.deepEqual(
      importMatrix(
        [
          ['Producto', 'AÑO', 'nombre del producto'],
          ['Café', '2026', 'x']
        ],
        fields
      ),
      {
        rows: [['Café', '2026']],
        fieldIds: ['name', 'year'],
        unmatched: ['nombre del producto']
      },
      'importMatrix matches with it; a second alias of a taken field is unmatched'
    );
  });
});
