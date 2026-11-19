import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  checkboxFieldType,
  createRegistry,
  dateFieldType,
  defaultMessages,
  numberFieldType,
  resolveType,
  singleSelectFieldType,
  textFieldType
} from '#src/core/index.ts';

import type {
  DateField,
  EuiSheetField,
  FieldType,
  NumberField,
  ParseContext,
  SingleSelectField,
  TextField
} from '#src/core/index.ts';

const edit: ParseContext = {
  record: undefined,
  messages: defaultMessages,
  source: 'edit'
};
const paste: ParseContext = { ...edit, source: 'paste' };
const view = { record: undefined, messages: defaultMessages };

const STATUS: SingleSelectField = {
  id: 'status',
  type: 'singleSelect',
  options: [
    { value: 'open', label: 'Open' },
    { value: 'closed', label: 'Closed', color: 'success' },
    { value: 7, label: 'Seven' }
  ]
};

module('Unit | Sheet | field types', function () {
  test('F1 text', function (assert) {
    const field: TextField = { id: 't' };
    assert.deepEqual(
      textFieldType.parse('  a b ', field, edit),
      {
        value: '  a b '
      },
      'keeps spaces'
    );
    assert.strictEqual(textFieldType.format(null, field, view), '');
    assert.deepEqual(
      textFieldType.validate!('abcdef', { id: 't', maxLength: 5 }, view),
      ['Must be 5 characters or fewer']
    );
    assert.deepEqual(
      textFieldType.validate!('abc', { id: 't', pattern: /^\d+$/ }, view),
      ['Invalid format']
    );
    assert.deepEqual(
      textFieldType.validate!(
        'abc',
        { id: 't', pattern: /^\d+$/, patternMessage: 'Digits only' },
        view
      ),
      ['Digits only']
    );
    assert.deepEqual(
      textFieldType.validate!('123', { id: 't', pattern: /^\d+$/g }, view),
      [],
      'a global pattern is reset between calls'
    );
  });

  test('F2 number', function (assert) {
    const dot: NumberField = { id: 'n', type: 'number' };
    const comma: NumberField = {
      id: 'n',
      type: 'number',
      decimalSeparator: ','
    };
    const parse = (text: string, field = dot) =>
      numberFieldType.parse(text, field, edit);
    assert.deepEqual(parse('12'), { value: 12 });
    assert.deepEqual(parse('-1.5'), { value: -1.5 });
    assert.deepEqual(parse('1,234.5'), { value: 1234.5 });
    assert.deepEqual(parse(' 1 234 '), { value: 1234 }, 'spaces removed');
    assert.deepEqual(parse('1,23'), { error: '"1,23" is not a number' });
    assert.deepEqual(parse('abc'), { error: '"abc" is not a number' });
    assert.deepEqual(parse('1e3'), { error: '"1e3" is not a number' });
    assert.deepEqual(parse(''), { value: null });
    assert.deepEqual(parse('  '), { value: null });
    assert.deepEqual(parse('1.234,5', comma), { value: 1234.5 });
    assert.deepEqual(parse('1,5', comma), { value: 1.5 });
    assert.deepEqual(parse('1.5', comma), { error: '"1.5" is not a number' });
    assert.strictEqual(numberFieldType.format(1.5, comma, view), '1,5');
    assert.strictEqual(numberFieldType.format(null, dot, view), '');
    const bounded: NumberField = { id: 'n', type: 'number', min: 0, max: 10 };
    assert.deepEqual(numberFieldType.validate!(-1, bounded, view), [
      'Must be 0 or more'
    ]);
    assert.deepEqual(numberFieldType.validate!(11, bounded, view), [
      'Must be 10 or less'
    ]);
    assert.deepEqual(numberFieldType.validate!(5, bounded, view), []);
    assert.deepEqual(
      numberFieldType.validate!('x' as unknown as number, dot, view),
      ['"x" is not a number'],
      'a stored non-number'
    );
  });

  test('F3 checkbox', function (assert) {
    const field = { id: 'c', type: 'checkbox' as const };
    for (const word of ['true', '1', 'yes', 'y', 'x', '✓', 'si', 'sí']) {
      assert.deepEqual(
        checkboxFieldType.parse(word, field, edit),
        { value: true },
        word
      );
      assert.deepEqual(
        checkboxFieldType.parse(word.toUpperCase(), field, edit),
        { value: true },
        word.toUpperCase()
      );
    }
    for (const word of ['false', '0', 'no', 'n', '']) {
      assert.deepEqual(
        checkboxFieldType.parse(word, field, edit),
        { value: false },
        word
      );
      assert.deepEqual(
        checkboxFieldType.parse(word.toUpperCase(), field, edit),
        { value: false },
        word.toUpperCase()
      );
    }
    assert.deepEqual(checkboxFieldType.parse('maybe', field, edit), {
      error: '"maybe" is not a checkbox value'
    });
    assert.deepEqual(checkboxFieldType.navKey!(' ', false, field), {
      value: true
    });
    assert.deepEqual(checkboxFieldType.navKey!(' ', true, field), {
      value: false
    });
    assert.strictEqual(checkboxFieldType.navKey!('a', false, field), undefined);
    assert.true(checkboxFieldType.isEmpty!(false));
    assert.true(checkboxFieldType.isEmpty!(undefined));
    assert.false(checkboxFieldType.isEmpty!(true));
    assert.strictEqual(checkboxFieldType.format(null, field, view), 'false');
  });

  test('F4 singleSelect', function (assert) {
    const t = singleSelectFieldType;
    assert.deepEqual(
      t.parse('closed', STATUS, edit),
      { value: 'closed' },
      'label, any case'
    );
    assert.deepEqual(t.parse(' CLOSED ', STATUS, edit), { value: 'closed' });
    assert.deepEqual(t.parse('7', STATUS, edit), { value: 7 }, 'by value');
    assert.deepEqual(t.parse('', STATUS, edit), { value: null });
    assert.deepEqual(t.parse('Purple', STATUS, edit), {
      error: '"Purple" is not an option'
    });
    const creating = { ...STATUS, createOnPaste: true };
    assert.deepEqual(t.parse('Purple', creating, paste), {
      value: 'Purple',
      newOption: { value: 'Purple', label: 'Purple' }
    });
    assert.deepEqual(
      t.parse('Purple', creating, edit),
      { error: '"Purple" is not an option' },
      'only a paste creates'
    );
    assert.strictEqual(t.format('closed', STATUS, view), 'Closed');
    assert.strictEqual(t.format('gone', STATUS, view), 'gone', 'unknown value');
    assert.strictEqual(t.format(null, STATUS, view), '');
    assert.deepEqual(t.validate!('gone', STATUS, view), [
      '"gone" is not an option'
    ]);
    assert.deepEqual(t.validate!('open', STATUS, view), []);
  });

  test('F5 singleSelect with options from the record', function (assert) {
    const byArea: Record<string, { value: string; label: string }[]> = {
      a: [{ value: 'a1', label: 'Operator' }],
      b: [{ value: 'b1', label: 'Supervisor' }]
    };
    const field: SingleSelectField<{ area: string }> = {
      id: 'position',
      type: 'singleSelect',
      options: (record) => byArea[record.area] ?? []
    };
    const inA = { ...edit, record: { area: 'a' } };
    const inB = { ...edit, record: { area: 'b' } };
    assert.deepEqual(singleSelectFieldType.parse('Operator', field, inA), {
      value: 'a1'
    });
    assert.deepEqual(singleSelectFieldType.parse('Operator', field, inB), {
      error: '"Operator" is not an option'
    });
    assert.strictEqual(
      singleSelectFieldType.format('a1', field, inA),
      'Operator'
    );
    assert.strictEqual(singleSelectFieldType.format('a1', field, inB), 'a1');
    assert.deepEqual(singleSelectFieldType.validate!('a1', field, inA), []);
    assert.deepEqual(singleSelectFieldType.validate!('a1', field, inB), [
      '"a1" is not an option'
    ]);
  });

  test('F6 date', function (assert) {
    const dmy: DateField = { id: 'd', type: 'date' };
    const mdy: DateField = { id: 'd', type: 'date', dateOrder: 'mdy' };
    const parse = (text: string, field = dmy) =>
      dateFieldType.parse(text, field, edit);
    assert.deepEqual(parse('2026-11-19'), { value: '2026-11-19' });
    assert.deepEqual(parse('19/11/2026'), { value: '2026-11-19' });
    assert.deepEqual(parse('1-2-2026'), { value: '2026-02-01' });
    assert.deepEqual(parse('1.2.2026'), { value: '2026-02-01' });
    assert.deepEqual(parse('2026/11/19'), { value: '2026-11-19' });
    assert.deepEqual(parse('2026-11-19T10:00:00Z'), { value: '2026-11-19' });
    assert.deepEqual(parse('2026-11-19 10:00'), { value: '2026-11-19' });
    assert.deepEqual(parse('31/02/2026'), {
      error: '"31/02/2026" is not a date'
    });
    assert.deepEqual(parse('11/19/2026'), {
      error: '"11/19/2026" is not a date'
    });
    assert.deepEqual(parse('19/11/26'), { error: '"19/11/26" is not a date' });
    assert.deepEqual(parse('19 Nov 2026'), {
      error: '"19 Nov 2026" is not a date'
    });
    assert.deepEqual(parse(''), { value: null });
    assert.deepEqual(parse('11/19/2026', mdy), { value: '2026-11-19' });
    assert.deepEqual(parse('19/11/2026', mdy), {
      error: '"19/11/2026" is not a date'
    });
    assert.strictEqual(
      dateFieldType.format('2026-11-19', dmy, view),
      '19/11/2026'
    );
    assert.strictEqual(
      dateFieldType.format('2026-11-19', mdy, view),
      '11/19/2026'
    );
    assert.strictEqual(dateFieldType.format(null, dmy, view), '');
    assert.strictEqual(
      dateFieldType.format('soon', dmy, view),
      'soon',
      'not ISO: raw'
    );
    assert.strictEqual(
      dateFieldType.copyText!('2026-11-19', dmy, view),
      '2026-11-19'
    );
    const bounded: DateField = { ...dmy, min: '2026-01-01', max: '2026-12-31' };
    assert.deepEqual(dateFieldType.validate!('2025-12-31', bounded, view), [
      'Must be 01/01/2026 or more'
    ]);
    assert.deepEqual(dateFieldType.validate!('2027-01-01', bounded, view), [
      'Must be 31/12/2026 or less'
    ]);
    assert.deepEqual(dateFieldType.validate!('2026-06-01', bounded, view), []);
    assert.deepEqual(dateFieldType.validate!('2026-02-30', dmy, view), [
      '"2026-02-30" is not a date'
    ]);
  });

  test('F7 parse(copyText(v)) gives v; the registry', function (assert) {
    const cases: Array<[FieldType<any, any>, EuiSheetField, unknown[]]> = [
      [textFieldType, { id: 't' }, ['', 'a', ' spaced ', '12']],
      [
        numberFieldType,
        { id: 'n', type: 'number' },
        [null, 0, 12, -1.5, 1234.25]
      ],
      [
        numberFieldType,
        { id: 'n', type: 'number', decimalSeparator: ',' },
        [null, 1.5, -1234.25]
      ],
      [checkboxFieldType, { id: 'c', type: 'checkbox' }, [true, false]],
      [singleSelectFieldType, STATUS, [null, 'open', 'closed', 7]],
      [
        dateFieldType,
        { id: 'd', type: 'date' },
        [null, '2026-11-19', '2024-02-29']
      ],
      [
        dateFieldType,
        { id: 'd', type: 'date', dateOrder: 'mdy' },
        [null, '2026-01-02']
      ]
    ];
    for (const [type, field, values] of cases) {
      for (const value of values) {
        const text = (type.copyText ?? type.format)(value, field, view);
        assert.deepEqual(
          type.parse(text, field, paste),
          { value },
          `${field.type ?? 'text'} ${JSON.stringify(value)} → ${JSON.stringify(text)}`
        );
      }
    }
    const custom: FieldType = {
      parse: (t) => ({ value: t }),
      format: () => 'custom'
    };
    const registry = createRegistry({ text: custom });
    assert.strictEqual(registry['text'], custom, 'a built-in name is replaced');
    assert.strictEqual(registry['number'], builtInFieldTypes['number']);
    assert.strictEqual(
      resolveType(registry, { id: 'x' }),
      custom,
      'default type is text'
    );
    assert.throws(
      () => resolveType(registry, { id: 'x', type: 'nope' }),
      /EuiSheet: unknown field type "nope" \(field "x"\)/
    );
  });
});
