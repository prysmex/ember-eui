import { module, test } from 'qunit';

import {
  attachmentFieldType,
  builtInFieldTypes,
  checkboxFieldType,
  createRegistry,
  currencyFieldType,
  dateFieldType,
  defaultMessages,
  durationFieldType,
  emailFieldType,
  joinList,
  linkedRecordFieldType,
  longTextFieldType,
  multiSelectFieldType,
  numberFieldType,
  percentFieldType,
  phoneFieldType,
  ratingFieldType,
  resolveType,
  safeFileUrl,
  safeLink,
  singleSelectFieldType,
  splitList,
  textFieldType,
  urlFieldType,
  userFieldType
} from '#src/core/index.ts';

import type {
  AttachmentField,
  CurrencyField,
  DateField,
  DurationField,
  EuiSheetField,
  FieldType,
  LinkedRecordField,
  LinkField,
  LongTextField,
  MultiSelectField,
  NumberField,
  ParseContext,
  PercentField,
  RatingField,
  SingleSelectField,
  TextField,
  UserField
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

  test('F8 multiSelect', function (assert) {
    const field: MultiSelectField = {
      id: 'tags',
      type: 'multiSelect',
      options: [
        { value: 'red', label: 'Red' },
        { value: 'blue', label: 'Blue' },
        { value: 3, label: 'Three' }
      ]
    };
    const t = multiSelectFieldType;
    assert.deepEqual(t.parse('red, BLUE', field, edit), {
      value: ['red', 'blue']
    });
    assert.deepEqual(
      t.parse('3, Red, red', field, edit),
      {
        value: [3, 'red']
      },
      'value, then a repeat dropped'
    );
    assert.deepEqual(t.parse('', field, edit), { value: [] });
    assert.deepEqual(t.parse('Red, Pink', field, edit), {
      error: '"Pink" is not an option'
    });
    assert.strictEqual(t.format(['blue', 'red'], field, view), 'Blue, Red');
    assert.strictEqual(t.copyText!(['blue', 3], field, view), 'Blue, Three');
    assert.deepEqual(t.validate!(['red', 'x'], field, view), [
      '"x" is not an option'
    ]);
    assert.true(t.isEmpty!([]));
    assert.true(t.isEmpty!(null));
    assert.false(t.isEmpty!(['red']));
    assert.true(t.equals!(['red', 'blue'], ['red', 'blue']), 'equal arrays');
    assert.false(t.equals!(['red', 'blue'], ['blue', 'red']), 'order counts');
    assert.false(t.equals!(['red'], null));
    assert.true(t.compare!(['red'], ['blue'], field) < 0, 'option order');
    assert.true(
      t.compare!(['red'], ['red', 'blue'], field) < 0,
      'shorter first'
    );
    assert.strictEqual(t.navKey, undefined);
    assert.strictEqual(t.toNumber, undefined);
  });

  test('F9 linkedRecord', function (assert) {
    const field: LinkedRecordField = {
      id: 'links',
      type: 'linkedRecord',
      search: () => Promise.resolve([])
    };
    const t = linkedRecordFieldType;
    assert.deepEqual(t.parse(' Ana, Bo ', field, paste), {
      unresolved: 'Ana, Bo'
    });
    assert.deepEqual(t.parse(' ', field, paste), { value: [] });
    assert.deepEqual(t.resolve!.parts('Ana, "Bo, Jr", ', field, paste), [
      'Ana',
      'Bo, Jr'
    ]);
    assert.deepEqual(
      t.resolve!.parts('Ana, Bo', { ...field, multiple: false }, paste),
      ['Ana'],
      'one part without multiple'
    );
    const ana = { id: 1, label: 'Ana' };
    const bo = { id: 'b', label: 'Bo, Jr' };
    assert.deepEqual(
      t.resolve!.combine(
        [
          { text: 'Ana', value: ana },
          { text: 'Bo, Jr', value: bo },
          { text: 'ana', value: ana }
        ],
        field,
        paste
      ),
      { value: [ana, bo] }
    );
    assert.deepEqual(
      t.resolve!.combine(
        [
          { text: 'Ana', value: ana },
          { text: 'Zed', value: null }
        ],
        field,
        paste
      ),
      { error: '"Zed" could not be resolved' }
    );
    assert.strictEqual(t.format([ana, bo], field, view), 'Ana, Bo, Jr');
    assert.strictEqual(t.copyText!([ana, bo], field, view), 'Ana, "Bo, Jr"');
    assert.true(t.equals!([ana], [{ id: '1', label: 'renamed' }]), 'by id');
    assert.false(t.equals!([ana, bo], [bo, ana]));
    assert.true(t.isEmpty!([]));
    assert.true(t.compare!([ana], [bo], field) < 0);
  });

  test('F10 user', function (assert) {
    const ana = { id: 'u1', label: 'Ana Ruiz', email: 'ana@x.com' };
    const bo = { id: 'u2', label: 'Bo Vela', avatarUrl: 'https://x/b.png' };
    const field: UserField = { id: 'owner', type: 'user', options: [ana, bo] };
    const t = userFieldType;
    assert.deepEqual(t.parse('ana ruiz', field, paste), { value: ana });
    assert.deepEqual(
      t.parse('ANA@x.com', field, paste),
      { value: ana },
      'email'
    );
    assert.deepEqual(t.parse('', field, paste), { value: null });
    assert.deepEqual(t.parse('Zed', field, paste), {
      error: '"Zed" is not an option'
    });
    const multi: UserField = { ...field, multiple: true };
    assert.deepEqual(t.parse('Bo Vela, ana@x.com', multi, paste), {
      value: [bo, ana]
    });
    assert.deepEqual(t.parse('', multi, paste), { value: [] });
    const remote: UserField = {
      id: 'owner',
      type: 'user',
      search: () => Promise.resolve([])
    };
    assert.deepEqual(t.parse('Ana', remote, paste), { unresolved: 'Ana' });
    assert.deepEqual(
      t.resolve!.combine([{ text: 'Ana', value: ana }], remote, paste),
      { value: ana },
      'one user without multiple'
    );
    assert.strictEqual(t.format(ana, field, view), 'Ana Ruiz');
    assert.strictEqual(t.format([ana, bo], multi, view), 'Ana Ruiz, Bo Vela');
    assert.true(t.equals!(ana, { id: 'u1', label: 'other' }));
    assert.false(t.equals!(ana, bo));
    assert.true(t.isEmpty!(null));
    assert.true(t.isEmpty!([]));
    assert.true(t.compare!(ana, bo, field) < 0);
  });

  test('F11 attachment', function (assert) {
    const field: AttachmentField = { id: 'files', type: 'attachment' };
    const t = attachmentFieldType;
    const a = { id: 'a', name: 'a.pdf', url: 'https://x/a.pdf' };
    const b = {
      id: 'b',
      name: 'b.png',
      url: 'https://x/b.png',
      type: 'image/png'
    };
    assert.deepEqual(t.parse('', field, edit), { value: [] });
    assert.deepEqual(t.parse('https://x/a.pdf', field, paste), {
      error: 'Text is not a file'
    });
    assert.strictEqual(t.format([a, b], field, view), 'a.pdf, b.png');
    assert.strictEqual(
      t.copyText!([a, b], field, view),
      'https://x/a.pdf, https://x/b.png'
    );
    assert.true(t.equals!([a, b], [{ ...a }, { ...b }]));
    assert.false(t.equals!([a, b], [a]));
    assert.true(t.isEmpty!([]));
    assert.true(t.compare!([a], [a, b], field) < 0);
    assert.strictEqual(safeFileUrl('https://x/a.png'), 'https://x/a.png');
    assert.strictEqual(safeFileUrl('blob:https://x/1'), 'blob:https://x/1');
    assert.strictEqual(
      safeFileUrl('data:image/png;base64,AAAA'),
      'data:image/png;base64,AAAA'
    );
    assert.strictEqual(safeFileUrl('data:text/html,<b>x</b>'), undefined);
    assert.strictEqual(safeFileUrl('javascript:alert(1)'), undefined);
  });

  test('F12 currency', function (assert) {
    const field: CurrencyField = {
      id: 'price',
      type: 'currency',
      currency: 'USD',
      locale: 'en-US',
      min: 0
    };
    const t = currencyFieldType;
    assert.deepEqual(t.parse('$1,234.50', field, paste), { value: 1234.5 });
    assert.deepEqual(t.parse('USD 12', field, paste), { value: 12 });
    assert.deepEqual(t.parse(' 7.25 usd', field, paste), { value: 7.25 });
    assert.deepEqual(t.parse('', field, paste), { value: null });
    assert.deepEqual(t.parse('abc', field, paste), {
      error: '"abc" is not a number'
    });
    assert.strictEqual(t.format(1234.5, field, view), '$1,234.50');
    assert.strictEqual(t.copyText!(1234.5, field, view), '1234.5');
    const euro: CurrencyField = {
      id: 'p',
      type: 'currency',
      currency: 'EUR',
      locale: 'de-DE'
    };
    assert.deepEqual(
      t.parse('1.234,50 €', euro, paste),
      { value: 1234.5 },
      'locale decimal'
    );
    assert.strictEqual(t.copyText!(1234.5, euro, view), '1234,5');
    assert.deepEqual(t.validate!(-1, field, view), ['Must be $0.00 or more']);
    assert.strictEqual(t.toNumber!(3, field), 3);
    assert.true(t.compare!(null, 1, field) < 0);
  });

  test('F13 percent', function (assert) {
    const field: PercentField = { id: 'pct', type: 'percent' };
    const t = percentFieldType;
    assert.deepEqual(t.parse('25%', field, paste), { value: 0.25 });
    assert.deepEqual(t.parse('25', field, paste), { value: 0.25 });
    assert.deepEqual(t.parse('12.5 %', field, paste), { value: 0.125 });
    assert.deepEqual(
      t.parse('7%', field, paste),
      { value: 0.07 },
      'no float noise'
    );
    assert.deepEqual(t.parse('', field, paste), { value: null });
    assert.deepEqual(t.parse('x%', field, paste), {
      error: '"x%" is not a number'
    });
    assert.strictEqual(t.format(0.25, field, view), '25%');
    assert.strictEqual(t.format(0.125, field, view), '13%', 'precision 0');
    assert.strictEqual(
      t.format(0.125, { ...field, precision: 1 }, view),
      '12.5%'
    );
    assert.strictEqual(t.copyText!(0.125, field, view), '12.5%', 'not rounded');
    assert.deepEqual(t.validate!(1.5, { ...field, max: 1 }, view), [
      'Must be 100% or less'
    ]);
    assert.strictEqual(t.toNumber!(0.5, field), 0.5);
  });

  test('F14 duration', function (assert) {
    const field: DurationField = { id: 'd', type: 'duration' };
    const seconds: DurationField = { ...field, durationFormat: 'h:mm:ss' };
    const t = durationFieldType;
    assert.deepEqual(t.parse('1:30', field, paste), { value: 5400 });
    assert.deepEqual(t.parse('1:30:15', field, paste), { value: 5415 });
    assert.deepEqual(t.parse('1h 30m', field, paste), { value: 5400 });
    assert.deepEqual(t.parse('1.5h', field, paste), { value: 5400 });
    assert.deepEqual(t.parse('45s', field, paste), { value: 45 });
    assert.deepEqual(t.parse('90', field, paste), { value: 5400 }, 'minutes');
    assert.deepEqual(t.parse('90', seconds, paste), { value: 90 }, 'seconds');
    assert.deepEqual(t.parse('', field, paste), { value: null });
    assert.deepEqual(t.parse('soon', field, paste), {
      error: '"soon" is not a duration'
    });
    assert.deepEqual(t.parse('1:75', field, paste), {
      error: '"1:75" is not a duration'
    });
    assert.strictEqual(t.format(5400, field, view), '1:30');
    assert.strictEqual(t.format(5415, field, view), '1:30', 'whole minutes');
    assert.strictEqual(t.format(5415, seconds, view), '1:30:15');
    assert.strictEqual(t.format(36000, field, view), '10:00');
    assert.deepEqual(t.validate!(-5, field, view), ['"-5" is not a duration']);
    assert.strictEqual(t.toNumber!(60, field), 60);
  });

  test('F15 rating', function (assert) {
    const field: RatingField = { id: 'r', type: 'rating' };
    const t = ratingFieldType;
    assert.deepEqual(t.parse('4', field, paste), { value: 4 });
    assert.deepEqual(t.parse('0', field, paste), { value: null }, '0 clears');
    assert.deepEqual(t.parse('', field, paste), { value: null });
    assert.deepEqual(t.parse('6', field, paste), {
      error: 'Must be 5 or less'
    });
    assert.deepEqual(t.parse('2.5', field, paste), {
      error: '"2.5" is not a number'
    });
    assert.deepEqual(t.parse('9', { ...field, max: 10 }, paste), { value: 9 });
    assert.deepEqual(t.navKey!('3', null, field), { value: 3 });
    assert.deepEqual(t.navKey!('0', 3, field), { value: null });
    assert.strictEqual(t.navKey!('7', null, field), undefined, 'over max');
    assert.strictEqual(t.navKey!('a', null, field), undefined);
    assert.strictEqual(t.format(3, field, view), '3');
    assert.true(t.isEmpty!(null));
    assert.deepEqual(t.validate!(3, field, view), []);
    assert.strictEqual(t.toNumber!(3, field), 3);
    assert.true(t.compare!(1, 3, field) < 0);
  });

  test('F16 url, email, phone', function (assert) {
    const url: LinkField = { id: 'u', type: 'url' };
    const email: LinkField = { id: 'e', type: 'email' };
    const phone: LinkField = { id: 'p', type: 'phone' };
    assert.deepEqual(urlFieldType.parse(' example.com ', url, paste), {
      value: 'example.com'
    });
    assert.deepEqual(
      urlFieldType.validate!('example.com/a?b=1', url, view),
      []
    );
    assert.deepEqual(urlFieldType.validate!('https://x.org', url, view), []);
    assert.deepEqual(urlFieldType.validate!('not a url', url, view), [
      '"not a url" is not a URL'
    ]);
    assert.deepEqual(urlFieldType.validate!('word', url, view), [
      '"word" is not a URL'
    ]);
    assert.strictEqual(
      urlFieldType.link!('example.com', url),
      'https://example.com'
    );
    assert.strictEqual(
      urlFieldType.link!('http://x.org/a', url),
      'http://x.org/a'
    );
    assert.deepEqual(emailFieldType.validate!('ana@x.com', email, view), []);
    assert.deepEqual(emailFieldType.validate!('ana@x', email, view), [
      '"ana@x" is not an email address'
    ]);
    assert.strictEqual(
      emailFieldType.link!('ana@x.com', email),
      'mailto:ana@x.com'
    );
    assert.deepEqual(
      phoneFieldType.validate!('+52 (81) 1234-5678', phone, view),
      []
    );
    assert.deepEqual(phoneFieldType.validate!('call me', phone, view), [
      '"call me" is not a phone number'
    ]);
    assert.strictEqual(
      phoneFieldType.link!('+52 (81) 1234-5678', phone),
      'tel:+528112345678'
    );
    assert.strictEqual(phoneFieldType.link!('', phone), undefined);
    assert.deepEqual(
      urlFieldType.validate!('example.com', { ...url, maxLength: 5 }, view),
      ['Must be 5 characters or fewer']
    );
  });

  test('F17 longText', function (assert) {
    const field: LongTextField = {
      id: 'notes',
      type: 'longText',
      maxLength: 8
    };
    const t = longTextFieldType;
    assert.deepEqual(t.parse('a\nb ', field, paste), { value: 'a\nb ' });
    assert.strictEqual(t.format('a\nb', field, view), 'a\nb');
    assert.deepEqual(t.validate!('one\ntwo\nthree', field, view), [
      'Must be 8 characters or fewer'
    ]);
    assert.true(t.compare!('a', 'b', field) < 0);
  });

  test('F18 parse(copyText(v)) gives v for the new types (attachment excepted)', function (assert) {
    const tags: MultiSelectField = {
      id: 'tags',
      type: 'multiSelect',
      options: [
        { value: 'a', label: 'Alpha' },
        { value: 'b', label: 'Beta, two' },
        { value: 'c', label: '"Quoted"' }
      ]
    };
    const ana = { id: 'u1', label: 'Ana' };
    const bo = { id: 'u2', label: 'Bo, Jr' };
    const users: UserField = { id: 'u', type: 'user', options: [ana, bo] };
    const cases: Array<[FieldType<any, any>, EuiSheetField, unknown[]]> = [
      [multiSelectFieldType, tags, [[], ['a'], ['b', 'a'], ['c', 'b']]],
      [userFieldType, users, [null, ana, bo]],
      [userFieldType, { ...users, multiple: true }, [[], [ana], [bo, ana]]],
      [
        currencyFieldType,
        { id: 'c', type: 'currency', currency: 'MXN', locale: 'es-MX' },
        [null, 0, 12.5, -1234.25]
      ],
      [
        currencyFieldType,
        { id: 'c', type: 'currency', currency: 'EUR', locale: 'de-DE' },
        [null, 1234.5]
      ],
      [
        percentFieldType,
        { id: 'p', type: 'percent' },
        [null, 0, 0.25, 0.125, 0.07, 1.5]
      ],
      [
        durationFieldType,
        { id: 'd', type: 'duration' },
        [null, 0, 60, 5400, 36000]
      ],
      [
        durationFieldType,
        { id: 'd', type: 'duration', durationFormat: 'h:mm:ss' },
        [null, 5415, 59]
      ],
      [ratingFieldType, { id: 'r', type: 'rating' }, [null, 1, 5]],
      [urlFieldType, { id: 'u', type: 'url' }, ['', 'https://x.org/a?b=1']],
      [emailFieldType, { id: 'e', type: 'email' }, ['ana@x.com']],
      [phoneFieldType, { id: 'p', type: 'phone' }, ['+52 81 1234']],
      [longTextFieldType, { id: 'l', type: 'longText' }, ['', 'one\ntwo']]
    ];
    for (const [type, field, values] of cases) {
      for (const value of values) {
        const text = (type.copyText ?? type.format)(value, field, view);
        assert.deepEqual(
          type.parse(text, field, paste),
          { value },
          `${field.type} ${JSON.stringify(value)} → ${JSON.stringify(text)}`
        );
      }
    }
    // linkedRecord (and user without options) go through the owner: the
    // copied text splits back into the labels, which combine rebuilds
    const linked: LinkedRecordField = {
      id: 'l',
      type: 'linkedRecord',
      search: () => Promise.resolve([])
    };
    const records = [ana, bo];
    const text = linkedRecordFieldType.copyText!(records, linked, view);
    assert.deepEqual(linkedRecordFieldType.parse(text, linked, paste), {
      unresolved: text
    });
    const parts = linkedRecordFieldType.resolve!.parts(text, linked, paste);
    assert.deepEqual(parts, ['Ana', 'Bo, Jr']);
    assert.deepEqual(
      linkedRecordFieldType.resolve!.combine(
        parts.map((part) => ({
          text: part,
          value: records.find((r) => r.label === part) ?? null
        })),
        linked,
        paste
      ),
      { value: records },
      'linkedRecord through parts and combine'
    );
  });

  test('F19 multiSelect: quoted parts and newOptions on paste', function (assert) {
    const field: MultiSelectField = {
      id: 'tags',
      type: 'multiSelect',
      options: [{ value: 'a', label: 'Alpha' }],
      createOnPaste: true
    };
    assert.deepEqual(splitList(' "x, y" ,Alpha,, "say ""hi""" '), [
      'x, y',
      'Alpha',
      'say "hi"'
    ]);
    assert.strictEqual(
      joinList(['x, y', 'Alpha', '"q"']),
      '"x, y", Alpha, """q"""'
    );
    assert.deepEqual(
      multiSelectFieldType.parse('"New, one", Alpha, Two, two', field, paste),
      {
        value: ['New, one', 'a', 'Two'],
        newOptions: [
          { value: 'New, one', label: 'New, one' },
          { value: 'Two', label: 'Two' }
        ]
      },
      'unknown parts become options once'
    );
    assert.deepEqual(
      multiSelectFieldType.parse('Two', field, edit),
      { error: '"Two" is not an option' },
      'only on paste'
    );
  });

  test('F20 link schemes: only http, https, mailto and tel open', function (assert) {
    const url: LinkField = { id: 'u', type: 'url' };
    assert.strictEqual(
      urlFieldType.link!('javascript:alert(1)', url),
      undefined
    );
    assert.deepEqual(urlFieldType.validate!('javascript:alert(1)', url, view), [
      '"javascript:alert(1)" is not a URL'
    ]);
    assert.strictEqual(urlFieldType.link!('data:text/html,x', url), undefined);
    assert.strictEqual(urlFieldType.link!('ftp://x.org', url), undefined);
    assert.strictEqual(
      emailFieldType.link!('javascript:alert(1)//@x.com', {
        id: 'e',
        type: 'email'
      }),
      'mailto:javascript:alert(1)//@x.com',
      'an email link is always mailto:'
    );
    assert.strictEqual(safeLink('javascript:alert(1)'), undefined);
    assert.strictEqual(safeLink('JAVASCRIPT:alert(1)'), undefined);
    assert.strictEqual(safeLink(' https://x.org '), 'https://x.org');
    assert.strictEqual(safeLink('mailto:a@b.c'), 'mailto:a@b.c');
    assert.strictEqual(safeLink('tel:+1'), 'tel:+1');
    assert.strictEqual(safeLink('vbscript:x'), undefined);
    assert.strictEqual(safeLink('not a url'), undefined);
  });
});
