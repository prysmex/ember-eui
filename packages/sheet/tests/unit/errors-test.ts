import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  compareValues,
  createMessages,
  createRegistry,
  defaultMessages,
  interpolate,
  mergeErrors,
  sheetMessageTokens,
  validateCell
} from '#src/core/index.ts';

import type {
  EuiSheetField,
  FieldType,
  SheetContext
} from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

function ctx(
  fields: EuiSheetField<Row>[],
  types = builtInFieldTypes
): SheetContext<Row> {
  return {
    records: [],
    fields,
    getRecordId: (record) => record.id,
    types,
    messages: defaultMessages
  };
}

module('Unit | Sheet | errors', function () {
  test('E1 validateCell: required', function (assert) {
    let calls = 0;
    const counting: FieldType = {
      parse: (text) => ({ value: text }),
      format: (value) => (typeof value === 'string' ? value : ''),
      validate: () => {
        calls++;
        return ['type rule'];
      }
    };
    const types = createRegistry({ counted: counting });
    const field: EuiSheetField<Row> = {
      id: 'a',
      type: 'counted',
      required: true
    };
    assert.deepEqual(
      validateCell(ctx([field], types), field, { id: 'r', a: '' }),
      ['Required']
    );
    assert.strictEqual(
      calls,
      0,
      "the type's validate is not called on an empty value"
    );
    assert.deepEqual(
      validateCell(ctx([field], types), field, { id: 'r', a: 'x' }),
      ['type rule']
    );
    const conditional: EuiSheetField<Row> = {
      id: 'a',
      required: (record) => record['done'] === true
    };
    assert.deepEqual(
      validateCell(ctx([conditional]), conditional, {
        id: 'r',
        a: '',
        done: true
      }),
      ['Required']
    );
    assert.deepEqual(
      validateCell(ctx([conditional]), conditional, {
        id: 'r',
        a: '',
        done: false
      }),
      []
    );
    const box: EuiSheetField<Row> = {
      id: 'ok',
      type: 'checkbox',
      required: true
    };
    assert.deepEqual(
      validateCell(ctx([box]), box, { id: 'r', ok: false }),
      ['Required'],
      'a required checkbox must be checked'
    );
  });

  test('E2 validateCell: type rules, then field.validate', function (assert) {
    const field: EuiSheetField<Row> = {
      id: 'n',
      type: 'number',
      max: 10,
      validate: (value) => (Number(value) % 2 ? 'Must be even' : undefined)
    };
    assert.deepEqual(validateCell(ctx([field]), field, { id: 'r', n: 11 }), [
      'Must be 10 or less',
      'Must be even'
    ]);
    const many: EuiSheetField<Row> = {
      id: 'n',
      type: 'number',
      validate: (value, record) => [`a ${String(value)}`, `b ${record.id}`]
    };
    assert.deepEqual(validateCell(ctx([many]), many, { id: 'r', n: 3 }), [
      'a 3',
      'b r'
    ]);
  });

  test('E3 mergeErrors and compareValues', function (assert) {
    assert.deepEqual(
      mergeErrors('a', ['b', 'a', ''], undefined, '', ['c'], 'b'),
      ['a', 'b', 'c']
    );
    const types = builtInFieldTypes;
    const number = { id: 'n', type: 'number' };
    const date = { id: 'd', type: 'date' };
    assert.strictEqual(compareValues(types, number, null, 1), -1);
    assert.strictEqual(compareValues(types, number, 1, null), 1);
    assert.strictEqual(compareValues(types, number, null, null), 0);
    assert.true(compareValues(types, number, 2, 10) < 0);
    assert.strictEqual(compareValues(types, date, null, '2026-01-01'), -1);
    assert.strictEqual(
      compareValues(types, date, '2026-02-01', '2026-01-31'),
      1
    );
  });

  test('messages: English defaults, tokens, a translate function', function (assert) {
    assert.strictEqual(defaultMessages.required(), 'Required');
    assert.strictEqual(
      defaultMessages.notANumber('abc'),
      '"abc" is not a number'
    );
    assert.strictEqual(
      defaultMessages.notACheckbox('maybe'),
      '"maybe" is not a checkbox value'
    );
    assert.strictEqual(
      defaultMessages.notAnOption('Purple'),
      '"Purple" is not an option'
    );
    assert.strictEqual(
      defaultMessages.notADate('31/02/2026'),
      '"31/02/2026" is not a date'
    );
    assert.strictEqual(defaultMessages.min(0), 'Must be 0 or more');
    assert.strictEqual(defaultMessages.max(10), 'Must be 10 or less');
    assert.strictEqual(
      defaultMessages.maxLength(5),
      'Must be 5 characters or fewer'
    );
    assert.strictEqual(defaultMessages.pattern(), 'Invalid format');
    assert.strictEqual(
      defaultMessages.unresolved('x'),
      '"x" could not be resolved'
    );
    for (const [key, { token }] of Object.entries(sheetMessageTokens)) {
      assert.strictEqual(token, `euiSheet.${key}`, key);
    }
    const seen: unknown[] = [];
    const messages = createMessages((token, defaultMessage, values) => {
      seen.push([token, defaultMessage, values]);
      return token === 'euiSheet.notANumber'
        ? interpolate('"{text}" no es un número', values)
        : interpolate(defaultMessage, values);
    });
    assert.strictEqual(messages.notANumber('abc'), '"abc" no es un número');
    assert.strictEqual(messages.min(3), 'Must be 3 or more');
    assert.deepEqual(seen, [
      ['euiSheet.notANumber', '"{text}" is not a number', { text: 'abc' }],
      ['euiSheet.min', 'Must be {min} or more', { min: 3 }]
    ]);
  });
});
