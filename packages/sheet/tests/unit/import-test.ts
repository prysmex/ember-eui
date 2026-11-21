/**
 * The import screen's pure helpers (v0.4 10, stage 1), from
 * `@ember-eui/sheet/core`: IG1-IG3 `guessColumn`; IP1 `decodeText`, IP2
 * `matchColumns`, IP3 `previewImport`, IP4 `runImport` and `errorsCsv`,
 * IP5 one header matcher for `importMatrix` and `matchColumns`.
 */
import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  decodeText,
  defaultMessages,
  errorsCsv,
  guessColumn,
  importFieldId,
  importMatrix,
  importSignature,
  matchColumns,
  normalizeHeader,
  pasteMatrix,
  previewImport,
  runImport,
  suggestValueMap
} from '#src/core/index.ts';

import type {
  EuiSheetField,
  FieldType,
  SheetImportColumn,
  SheetImportPlan,
  SheetImportTransform
} from '#src/core/index.ts';

const types = builtInFieldTypes;
const messages = defaultMessages;
const ctx = { types, messages };

const typesOf = (texts: string[], candidates?: string[]) =>
  guessColumn(ctx, texts, candidates).map((guess) => guess.type);

/** Twenty distinct dates (day, month) as D/M/Y texts. */
const dmyTexts = (days: Array<[number, number]>) =>
  days.map(
    ([d, m]) =>
      `${String(d).padStart(2, '0')}/${String(m).padStart(2, '0')}/2026`
  );

module('Unit | import screen helpers', function () {
  test('IG1 dates: D/M/Y by default, M/D/Y only when a text proves it, a mix under 95% is text', function (assert) {
    const dmy = guessColumn(ctx, [
      '19/11/2026',
      '01/02/2026',
      '15/03/2025',
      ''
    ]);
    assert.deepEqual(dmy[0], {
      type: 'date',
      share: 1,
      options: { dateOrder: 'dmy' }
    });
    // ambiguous texts read either way: D/M/Y
    assert.deepEqual(guessColumn(ctx, ['01/02/2026', '03/04/2026'])[0], {
      type: 'date',
      share: 1,
      options: { dateOrder: 'dmy' }
    });
    const mdy = guessColumn(ctx, ['11/19/2026', '01/02/2026', '03/04/2025']);
    assert.deepEqual(mdy[0], {
      type: 'date',
      share: 1,
      options: { dateOrder: 'mdy' }
    });
    // one proof among 30 still decides the order (D/M/Y would read 96.7%)
    const many = [
      ...dmyTexts(
        Array.from({ length: 29 }, (_, i) => [(i % 12) + 1, (i % 12) + 1])
      ),
      '11/19/2026'
    ];
    assert.deepEqual(guessColumn(ctx, many)[0]!.options, { dateOrder: 'mdy' });
    // texts that prove both orders: D/M/Y, which reads half of them
    const mix = [
      ...dmyTexts([
        [19, 1],
        [20, 2],
        [21, 3]
      ]),
      '01/19/2026',
      '02/20/2026',
      '03/21/2026'
    ];
    assert.deepEqual(typesOf(mix), ['text'], 'under 95%: text');
    assert.strictEqual(
      guessColumn(ctx, mix, ['date', 'text'])[0]!.type,
      'text',
      'not date'
    );
  });

  test('IG2 numbers, checkboxes, selects, long text, percents, currencies, emails', function (assert) {
    assert.deepEqual(guessColumn(ctx, ['1.234,5', '12,5', '3', '1.000'])[0], {
      type: 'number',
      share: 1,
      options: { decimalSeparator: ',' }
    });
    assert.deepEqual(guessColumn(ctx, ['1,234.5', '12.5', '3'])[0], {
      type: 'number',
      share: 1,
      options: { decimalSeparator: '.' }
    });
    assert.deepEqual(guessColumn(ctx, ['Sí', 'No', 'sí', 'no', 'Sí'])[0], {
      type: 'checkbox',
      share: 1,
      options: {}
    });
    const statuses = ['Open', 'Done', 'Doing', 'Blocked', 'Later'];
    const select = guessColumn(ctx, [...statuses, ...statuses.reverse()]);
    assert.strictEqual(select[0]!.type, 'singleSelect');
    assert.deepEqual(
      select[0]!.options,
      {
        options: ['Later', 'Blocked', 'Doing', 'Done', 'Open']
          .reverse()
          .map((label) => ({ value: label, label }))
      },
      'its options: the distinct texts, in order'
    );
    assert.deepEqual(
      typesOf(['Open', 'Done', 'Open']),
      ['text'],
      'a text used once: not a select'
    );
    assert.deepEqual(typesOf(['line one\nline two', 'short']), [
      'longText',
      'text'
    ]);
    assert.strictEqual(typesOf(['x'.repeat(201)])[0], 'longText');
    assert.deepEqual(guessColumn(ctx, ['25%', '30 %', '7.5%'])[0], {
      type: 'percent',
      share: 1,
      options: { decimalSeparator: '.' }
    });
    assert.deepEqual(
      typesOf(['12', '30'])[0],
      'number',
      'plain numbers are not percents'
    );
    assert.deepEqual(guessColumn(ctx, ['$1,200.00', 'MXN 300', '45.5 €'])[0], {
      type: 'currency',
      share: 1,
      options: { decimalSeparator: '.' }
    });
    assert.deepEqual(
      typesOf(['Calle 5', 'Av 3', 'Calle 9']),
      ['text'],
      'a text with a number is not a currency'
    );
    assert.strictEqual(typesOf(['ana@acme.mx', 'bo@x.com'])[0], 'email');
    assert.strictEqual(typesOf(['acme.mx', 'https://x.com/a'])[0], 'url');
    assert.strictEqual(typesOf(['(81) 1234-5678', '+52 (55) 1-2'])[0], 'phone');
  });

  test('IG3 only the candidate types are tried', function (assert) {
    assert.deepEqual(typesOf(['Sí', 'No'], ['text', 'number']), ['text']);
    assert.deepEqual(
      typesOf(['19/11/2026', '20/11/2026'], ['number', 'text']),
      ['text']
    );
    assert.deepEqual(typesOf(['abc'], ['checkbox']), [], 'none reads it');
    assert.deepEqual(
      typesOf(['19/11/2026'], ['date', 'nope', 'text']),
      ['date', 'text'],
      'an unknown name is ignored'
    );
    assert.deepEqual(
      guessColumn(
        { types: { text: types['text']! }, messages },
        ['1'],
        ['number', 'text']
      ).map((guess) => guess.type),
      ['text'],
      'a candidate missing from ctx.types is not tried'
    );
    const app: FieldType<string> = {
      parse: (text) => ({ value: text }),
      format: (value) => value ?? ''
    };
    assert.deepEqual(
      guessColumn(
        { types: { ...types, app }, messages },
        ['x'],
        ['app', 'text']
      ).map((guess) => guess.type),
      ['text'],
      'an app type is not a candidate'
    );
    assert.deepEqual(guessColumn(ctx, ['', ' ']), [
      { type: 'text', share: 1, options: {} }
    ]);
    assert.deepEqual(guessColumn(ctx, [''], ['number']), [], 'empty, no text');
    assert.strictEqual(
      guessColumn(ctx, ['19/11/2026'])[0]!.type,
      'date',
      'the default candidates: the field editor’s list'
    );
    assert.deepEqual(
      typesOf(['2026-11-19 10:30'], ['dateTime', 'text']),
      ['dateTime', 'text'],
      'dateTime when it is a candidate'
    );
  });

  test('IP1 decodeText: a BOM is stripped; windows-1252 bytes decode; UTF-8 stays UTF-8', function (assert) {
    const utf8 = new TextEncoder().encode('Año;Precio');
    assert.deepEqual(decodeText(utf8), {
      text: 'Año;Precio',
      encoding: 'utf-8'
    });
    const bom = new Uint8Array([0xef, 0xbb, 0xbf, ...utf8]);
    assert.deepEqual(decodeText(bom.buffer), {
      text: 'Año;Precio',
      encoding: 'utf-8'
    });
    // `Año` in windows-1252: ñ is 0xF1, not valid UTF-8
    assert.deepEqual(decodeText(new Uint8Array([0x41, 0xf1, 0x6f])), {
      text: 'Año',
      encoding: 'windows-1252'
    });
    assert.deepEqual(
      decodeText(new Uint8Array([0x80, 0x20, 0x31])),
      { text: '€ 1', encoding: 'windows-1252' },
      '0x80 is the euro sign'
    );
    assert.deepEqual(decodeText(new Uint8Array([])), {
      text: '',
      encoding: 'utf-8'
    });
  });

  test('IP2 matchColumns: saved mapping, then alias, label, id; a field matched twice keeps the first', function (assert) {
    const fields: EuiSheetField[] = [
      { id: 'name', label: 'Nombre del producto', importAliases: ['producto'] },
      { id: 'price', label: 'Precio', type: 'number' },
      { id: 'stock', label: 'Existencias', type: 'number' },
      { id: 'year', label: 'Año' }
    ];
    const headers = [
      'PRODUCTO',
      'precio ',
      'stock',
      'Nombre_del  Producto',
      'AÑO',
      'Extra'
    ];
    assert.deepEqual(matchColumns(headers, fields), [
      {
        index: 0,
        header: 'PRODUCTO',
        target: { field: 'name' },
        matchedBy: 'alias'
      },
      {
        index: 1,
        header: 'precio ',
        target: { field: 'price' },
        matchedBy: 'label'
      },
      {
        index: 2,
        header: 'stock',
        target: { field: 'stock' },
        matchedBy: 'id'
      },
      {
        index: 3,
        header: 'Nombre_del  Producto',
        target: 'skip',
        taken: 'name'
      },
      {
        index: 4,
        header: 'AÑO',
        target: { field: 'year' },
        matchedBy: 'label'
      },
      { index: 5, header: 'Extra', target: 'skip' }
    ]);

    // a saved mapping of this header line wins; its fields are taken first
    const saved = {
      signature: importSignature([
        'producto',
        'Precio',
        'STOCK',
        'nombre del producto',
        'ano',
        'extra'
      ]),
      columns: [
        {
          index: 0,
          header: 'producto',
          target: { field: 'price' },
          transform: 'cents',
          trim: false
        },
        { index: 1, header: 'Precio', target: 'skip' },
        { index: 2, header: 'STOCK', target: { field: 'gone' } },
        {
          index: 5,
          header: 'extra',
          target: { newField: { label: 'Extra', type: 'number' } }
        }
      ] satisfies SheetImportColumn[]
    };
    assert.strictEqual(
      saved.signature,
      importSignature(headers),
      'the same normalised header line'
    );
    const columns = matchColumns(headers, fields, saved);
    assert.deepEqual(columns[0], {
      index: 0,
      header: 'PRODUCTO',
      target: { field: 'price' },
      transform: 'cents',
      trim: false,
      matchedBy: 'saved'
    });
    assert.deepEqual(columns[1]!.target, 'skip');
    assert.strictEqual(columns[1]!.matchedBy, 'saved');
    assert.deepEqual(
      [columns[2]!.target, columns[2]!.matchedBy],
      [{ field: 'stock' }, 'id'],
      'a saved field that no longer exists: matched by its header'
    );
    assert.deepEqual(
      [columns[3]!.target, columns[3]!.matchedBy],
      [{ field: 'name' }, 'label'],
      'name is free: column 0 is price now'
    );
    assert.deepEqual(columns[5]!.target, {
      newField: { label: 'Extra', type: 'number' }
    });

    // another header line: the saved mapping is ignored
    assert.deepEqual(
      matchColumns(['producto', 'precio'], fields, saved).map((c) => c.target),
      [{ field: 'name' }, { field: 'price' }]
    );
    // without a header line: by position
    assert.deepEqual(
      matchColumns(['', '', '', '', ''], fields, null, { headers: false }).map(
        (c) => c.target
      ),
      [
        { field: 'name' },
        { field: 'price' },
        { field: 'stock' },
        { field: 'year' },
        'skip'
      ]
    );
    assert.strictEqual(
      importSignature([' Año_X ', 'b']),
      JSON.stringify(['ano x', 'b'])
    );
  });

  test('IP3 previewImport: a transform, a value map and an M/D/Y copy; a throwing transform; linked on import; a new option', function (assert) {
    const due: EuiSheetField = { id: 'due', label: 'Fecha', type: 'date' };
    const fields: EuiSheetField[] = [
      due,
      { id: 'active', label: 'Activo', type: 'checkbox' },
      {
        id: 'status',
        label: 'Estado',
        type: 'singleSelect',
        createOnPaste: true,
        options: [
          { value: 'o', label: 'Open' },
          { value: 'd', label: 'Done' }
        ]
      },
      { id: 'price', label: 'Precio', type: 'number' },
      {
        id: 'client',
        label: 'Cliente',
        type: 'linkedRecord',
        search: () => Promise.resolve([])
      },
      { id: 'name', label: 'Nombre' }
    ];
    const seen: Array<{ line: number; header: string; name: string }> = [];
    const transforms: SheetImportTransform[] = [
      {
        id: 'cents',
        label: 'Cents to amount',
        apply(text, { line, header, row }) {
          seen.push({ line, header, name: row['Nombre']! });
          if (!/^\d+$/.test(text)) throw new Error(`"${text}" is not cents`);
          return (Number(text) / 100).toFixed(2);
        }
      },
      { id: 'never', label: 'Empty', apply: () => null }
    ];
    const matrix = [
      ['Fecha', 'Activo', 'Estado', 'Centavos', 'Cliente', 'Nombre'],
      ['11/19/2026', 'Sí', 'Abierto', '12345', 'Acme', ' Ana '],
      ['02/01/2026', 'N', 'Nuevo', 'x', '', 'Bo'],
      [' ', '', '', '', '', ''],
      ['12/31/2026', 'yes', 'done', '5', 'Acme, Bolt', 'Cy']
    ];
    const columns: SheetImportColumn[] = [
      { index: 0, header: 'Fecha', target: { field: 'due' }, dateOrder: 'mdy' },
      {
        index: 1,
        header: 'Activo',
        target: { field: 'active' },
        valueMap: { Sí: true, N: false }
      },
      {
        index: 2,
        header: 'Estado',
        target: { field: 'status' },
        valueMap: { Abierto: 'o' }
      },
      {
        index: 3,
        header: 'Centavos',
        target: { field: 'price' },
        transform: 'cents'
      },
      { index: 4, header: 'Cliente', target: { field: 'client' } },
      { index: 5, header: 'Nombre', target: { field: 'name' } }
    ];
    const plan: SheetImportPlan = { columns };
    const preview = previewImport({ ...ctx, fields }, matrix, plan, transforms);
    assert.deepEqual(preview.lines, [1, 2, 4], 'the blank line is left out');
    assert.deepEqual(preview.columns, [0, 1, 2, 3, 4, 5]);
    assert.deepEqual(
      preview.fields[0],
      { ...due, dateOrder: 'mdy' },
      'read with an M/D/Y copy'
    );
    assert.strictEqual(due['dateOrder'], undefined, 'the field is unchanged');
    assert.deepEqual(preview.cells[0], [
      {
        state: 'value',
        text: '11/19/2026',
        value: '2026-11-19',
        display: '11/19/2026'
      },
      { state: 'value', text: 'true', value: true, display: 'true' },
      { state: 'value', text: 'Open', value: 'o', display: 'Open' },
      { state: 'value', text: '123.45', value: 123.45, display: '123.45' },
      { state: 'linked', text: 'Acme' },
      { state: 'value', text: 'Ana', value: 'Ana', display: 'Ana' }
    ]);
    assert.deepEqual(preview.cells[1], [
      {
        state: 'value',
        text: '02/01/2026',
        value: '2026-02-01',
        display: '02/01/2026'
      },
      { state: 'value', text: 'false', value: false, display: 'false' },
      {
        state: 'newOption',
        text: 'Nuevo',
        value: 'Nuevo',
        display: 'Nuevo',
        options: [{ value: 'Nuevo', label: 'Nuevo' }]
      },
      { state: 'error', text: 'x', message: '"x" is not cents' },
      { state: 'value', text: '', value: null, display: '' },
      { state: 'value', text: 'Bo', value: 'Bo', display: 'Bo' }
    ]);
    assert.deepEqual(
      preview.cells[2]!.slice(1, 3).map((c) => c.state === 'value' && c.value),
      [true, 'd'],
      'texts not in the map go through the type: yes, done (a label)'
    );
    assert.deepEqual(
      seen[0],
      { line: 1, header: 'Centavos', name: ' Ana ' },
      'the transform gets the line, its header and the line’s texts'
    );

    // without the copy, the M/D/Y text is the date type's error
    const plain = previewImport(
      { ...ctx, fields },
      matrix,
      { columns: [{ ...columns[0]!, dateOrder: undefined }] },
      [],
      { size: 1 }
    );
    assert.deepEqual(plain.lines, [1], 'size');
    assert.deepEqual(plain.cells, [
      [
        {
          state: 'error',
          text: '11/19/2026',
          message: messages.notADate('11/19/2026')
        }
      ]
    ]);

    // a transform that returns null; trim and "empty is no value" off; skip
    const options = previewImport(
      { ...ctx, fields },
      matrix,
      {
        columns: [
          {
            index: 3,
            header: 'Centavos',
            target: { field: 'name' },
            transform: 'never'
          },
          {
            index: 5,
            header: 'Nombre',
            target: { field: 'name' },
            trim: false,
            emptyIsNull: false
          },
          { index: 0, header: 'Fecha', target: 'skip' },
          { index: 1, header: 'Activo', target: { field: 'gone' } }
        ]
      },
      transforms,
      { size: 1 }
    );
    assert.deepEqual(
      options.columns,
      [3, 5],
      'skip and unknown fields are not read'
    );
    assert.deepEqual(options.cells[0], [
      { state: 'value', text: '', value: null, display: '' },
      { state: 'value', text: ' Ana ', value: ' Ana ', display: ' Ana ' }
    ]);
    const empty = previewImport({ ...ctx, fields }, [['Nombre'], [''], ['x']], {
      columns: [
        {
          index: 0,
          header: 'Nombre',
          target: { field: 'name' },
          emptyIsNull: false
        }
      ]
    });
    assert.deepEqual(empty.lines, [2], 'a blank line is no line');

    // a new field's column: read with its draft, under a placeholder id
    const created = previewImport(
      { ...ctx, fields: [] },
      [['Activo'], ['Sí'], ['no']],
      {
        columns: [
          {
            index: 0,
            header: 'Activo',
            target: { newField: { label: 'Activo', type: 'checkbox' } }
          }
        ]
      }
    );
    assert.deepEqual(created.fields, [
      { id: importFieldId(0), label: 'Activo', type: 'checkbox' }
    ]);
    assert.deepEqual(
      created.cells.map(([cell]) => cell!.state === 'value' && cell!.value),
      [true, false]
    );

    // the value map's prefill
    assert.deepEqual(
      suggestValueMap(['Sí', ' no', 'x', 'Sí', 'quizá', ''], {
        id: 'a',
        type: 'checkbox'
      }),
      {
        texts: ['Sí', 'no', 'x', 'quizá', ''],
        map: { Sí: true, no: false, x: true, '': false }
      }
    );
    assert.deepEqual(suggestValueMap(['open', 'DÓNE', 'Nuevo'], fields[2]!), {
      texts: ['open', 'DÓNE', 'Nuevo'],
      map: { open: 'o', DÓNE: 'd' }
    });
    assert.deepEqual(
      suggestValueMap(['Red'], {
        id: 't',
        type: 'multiSelect',
        options: [{ value: 'r', label: 'red' }]
      }).map,
      { Red: ['r'] }
    );
    assert.deepEqual(suggestValueMap(['a'], { id: 'n', label: 'N' }), {
      texts: [],
      map: {}
    });
  });

  test('IP4 runImport over 1,000 lines: rows, values and errors; errorsCsv lists the failed lines under the header', function (assert) {
    const fields: EuiSheetField[] = [
      { id: 'name', label: 'Name' },
      { id: 'qty', label: 'Qty', type: 'number' },
      { id: 'due', label: 'Due', type: 'date' },
      {
        id: 'client',
        label: 'Client',
        type: 'linkedRecord',
        search: () => Promise.resolve([])
      }
    ];
    const matrix = [
      ['Name', 'Qty', 'Due', 'Client'],
      ...Array.from({ length: 1000 }, (_, i) => [
        i === 500 ? 'a, "b"' : `n${i}`,
        i % 100 === 0 ? 'bad' : String(i),
        '19/11/2026',
        i === 1 ? 'Acme' : ''
      ])
    ];
    const plan: SheetImportPlan = { columns: matchColumns(matrix[0]!, fields) };
    const run = runImport({ ...ctx, fields }, matrix, plan);
    assert.strictEqual(run.rows.length, 1000);
    assert.deepEqual(run.fieldIds, ['name', 'qty', 'due', 'client']);
    assert.deepEqual(run.fields, fields, 'no copies: the fields themselves');
    assert.deepEqual(run.rows[1], ['n1', '1', '19/11/2026', 'Acme']);
    assert.deepEqual(run.values[1], ['n1', 1, '2026-11-19', undefined]);
    assert.deepEqual(run.values[2], ['n2', 2, '2026-11-19', null]);
    assert.strictEqual(run.lines[0], 1, 'line indexes in the matrix');
    assert.strictEqual(run.errors.length, 10);
    assert.deepEqual(run.errors[0], {
      line: 1,
      column: 1,
      fieldId: 'qty',
      text: 'bad',
      message: messages.notANumber('bad')
    });
    assert.deepEqual(run.unresolved, [
      { line: 2, column: 3, fieldId: 'client', text: 'Acme' }
    ]);
    assert.deepEqual(run.skippedLines, []);

    const skipped = runImport({ ...ctx, fields }, matrix, plan, [], {
      skipLinesWithErrors: true
    });
    assert.strictEqual(skipped.rows.length, 990);
    assert.deepEqual(
      skipped.skippedLines,
      Array.from({ length: 10 }, (_, k) => k * 100 + 1)
    );
    assert.false(skipped.lines.includes(101));
    assert.strictEqual(
      skipped.errors.length,
      10,
      'the errors are still listed'
    );

    const csv = errorsCsv(matrix, run.errors);
    const lines = csv.split('\r\n');
    assert.strictEqual(lines.length, 11, 'the header and ten lines');
    assert.strictEqual(lines[0], 'Name,Qty,Due,Client');
    assert.strictEqual(lines[1], 'n0,bad,19/11/2026,');
    assert.strictEqual(lines[6], '"a, ""b""",bad,19/11/2026,', 'quoted');
    assert.strictEqual(
      errorsCsv(matrix, [run.errors[1]!, run.errors[0]!, run.errors[0]!], {
        headers: false,
        delimiter: ';'
      }),
      'n0;bad;19/11/2026;\r\nn100;bad;19/11/2026;',
      'once each, in file order; no header; another delimiter'
    );

    // what the sheet does with `rows` and `fields` (appendRows' paste
    // path): the values runImport gives, with per-column copies
    const small = [
      ['Due', 'Size', 'Name'],
      ['11/19/2026', '1.234,5', 'Ana'],
      ['02/01/2026', '', 'Bo'],
      ['13/13/2026', 'x', 'Cy']
    ];
    const read = runImport(
      {
        ...ctx,
        fields: [
          { id: 'due', type: 'date' },
          { id: 'size', type: 'number' },
          { id: 'name' }
        ]
      },
      small,
      {
        columns: [
          {
            index: 0,
            header: 'Due',
            target: { field: 'due' },
            dateOrder: 'mdy'
          },
          {
            index: 1,
            header: 'Size',
            target: { field: 'size' },
            decimalSeparator: ','
          },
          { index: 2, header: 'Name', target: { field: 'name' } }
        ]
      }
    );
    const pasted = pasteMatrix(
      {
        ...ctx,
        records: [],
        fields: read.fields,
        getRecordId: () => ''
      },
      { row: 0, col: 0 },
      read.rows
    )!;
    assert.deepEqual(
      pasted.inserts.map((insert) => insert.values),
      read.values.map((values) =>
        Object.fromEntries(
          values
            .map((value, k) => [read.fieldIds[k], value] as const)
            .filter(([, value]) => value !== undefined)
        )
      ),
      'the inserts have the values runImport gives'
    );
    assert.deepEqual(
      pasted.rejected.map((r) => [r.fieldId, r.text, r.message]),
      read.errors.map((e) => [e.fieldId, e.text, e.message]),
      'and the rejections are its errors'
    );
  });

  test('IP5 importMatrix and matchColumns share one header matcher', function (assert) {
    const fields: EuiSheetField[] = [
      { id: 'name', label: 'Name', importAliases: ['nombre_del producto'] },
      { id: 'qty', label: 'Qty' }
    ];
    const headers = ['Nombre del Producto', 'NAME', 'cantidad'];
    const matrix = importMatrix([headers, ['a', 'b', '1']], fields);
    assert.deepEqual(matrix.fieldIds, ['name']);
    assert.deepEqual(matrix.unmatched, ['NAME', 'cantidad']);
    const columns = matchColumns(headers, fields);
    assert.deepEqual(
      columns.map((c) => [c.target, c.matchedBy, c.taken]),
      [
        [{ field: 'name' }, 'alias', undefined],
        ['skip', undefined, 'name'],
        ['skip', undefined, undefined]
      ],
      'the alias in both; the taken field unmatched in both'
    );
    assert.strictEqual(
      importSignature(headers),
      JSON.stringify(headers.map(normalizeHeader))
    );
  });
});
