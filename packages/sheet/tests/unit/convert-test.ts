/**
 * `convertField` (V03 6.5, FC1-FC6) and `localRecords`' field operations
 * (V03 6.7, LF1-LF3).
 */
import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  convertField,
  defaultMessages
} from '#src/core/index.ts';
import { localRecords } from '#src/local-records.ts';

import type { EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const getId = (record: Row) => record.id;
const ctx = {
  types: builtInFieldTypes,
  messages: defaultMessages,
  getRecordId: getId
};

module('Unit | Sheet | convertField', function () {
  test('FC1 text → number: "12" becomes 12; "abc" becomes null with a rejected entry', function (assert) {
    const records: Row[] = [
      { id: 'a', f: '12' },
      { id: 'b', f: 'abc' }
    ];
    const result = convertField(
      ctx,
      records,
      { id: 'f' },
      { id: 'f', type: 'number' }
    );
    assert.deepEqual(result.patches, [
      { recordId: 'a', fieldId: 'f', from: '12', to: 12 },
      { recordId: 'b', fieldId: 'f', from: 'abc', to: null }
    ]);
    assert.deepEqual(result.rejected, [
      {
        recordId: 'b',
        fieldId: 'f',
        text: 'abc',
        message: defaultMessages.notANumber('abc')
      }
    ]);
    assert.deepEqual(result.inserts, []);
  });

  test('FC2 text → singleSelect: matching labels convert; with createOnPaste the others become newOptions', function (assert) {
    const records: Row[] = [
      { id: 'a', f: 'open' },
      { id: 'b', f: 'Later' },
      { id: 'c', f: 'Later' }
    ];
    const options = [{ value: 'o', label: 'Open' }];
    const strict = convertField(
      ctx,
      records,
      { id: 'f' },
      { id: 'f', type: 'singleSelect', options }
    );
    assert.deepEqual(
      strict.patches.map((patch) => [patch.recordId, patch.to]),
      [
        ['a', 'o'],
        ['b', null],
        ['c', null]
      ]
    );
    assert.strictEqual(strict.rejected.length, 2);
    assert.deepEqual(strict.newOptions, []);

    const created = convertField(
      ctx,
      records,
      { id: 'f' },
      { id: 'f', type: 'singleSelect', options, createOnPaste: true }
    );
    assert.deepEqual(
      created.patches.map((patch) => [patch.recordId, patch.to]),
      [['a', 'o']],
      'an unmatched text is its own new option: the stored value stays'
    );
    assert.deepEqual(created.rejected, []);
    assert.deepEqual(
      created.newOptions,
      [{ fieldId: 'f', option: { value: 'Later', label: 'Later' } }],
      'once per option'
    );
  });

  test('FC3 singleSelect → text: the option label', function (assert) {
    const from: EuiSheetField = {
      id: 'f',
      type: 'singleSelect',
      options: [{ value: 'o', label: 'Open' }]
    };
    const result = convertField(ctx, [{ id: 'a', f: 'o' }], from, { id: 'f' });
    assert.deepEqual(result.patches, [
      { recordId: 'a', fieldId: 'f', from: 'o', to: 'Open' }
    ]);
  });

  test('FC4 number → currency and back: unchanged values give no patch', function (assert) {
    const records: Row[] = [
      { id: 'a', f: 12.5 },
      { id: 'b', f: 0 }
    ];
    const number: EuiSheetField = { id: 'f', type: 'number' };
    const currency: EuiSheetField = {
      id: 'f',
      type: 'currency',
      currency: 'USD',
      locale: 'en-US'
    };
    assert.deepEqual(convertField(ctx, records, number, currency).patches, []);
    assert.deepEqual(convertField(ctx, records, currency, number).patches, []);
  });

  test('FC5 date → text → date round-trips', function (assert) {
    const records: Row[] = [{ id: 'a', f: '2026-11-19' }];
    const date: EuiSheetField = { id: 'f', type: 'date' };
    const text: EuiSheetField = { id: 'f' };
    const toText = convertField(ctx, records, date, text);
    assert.deepEqual(
      toText.patches,
      [],
      'the copy text is the ISO date: as text it is the same string'
    );
    const typed: Row[] = [{ id: 'a', f: '19/11/2026' }];
    const back = convertField(ctx, typed, text, date);
    assert.deepEqual(back.patches, [
      { recordId: 'a', fieldId: 'f', from: '19/11/2026', to: '2026-11-19' }
    ]);
    assert.deepEqual(convertField(ctx, records, text, date).patches, []);
  });

  test('FC6 empty values give no patch and no rejection', function (assert) {
    const records: Row[] = [
      { id: 'a', f: '' },
      { id: 'b', f: null },
      { id: 'c' }
    ];
    const result = convertField(
      ctx,
      records,
      { id: 'f' },
      { id: 'f', type: 'number' }
    );
    assert.deepEqual(result.patches, []);
    assert.deepEqual(result.rejected, []);
    assert.deepEqual(result.newOptions, []);
  });
});

module('Unit | Sheet | localRecords field operations', function () {
  const FIELDS: EuiSheetField<Row>[] = [
    { id: 'name', label: 'Name' },
    { id: 'qty', label: 'Qty', type: 'number' }
  ];

  test('LF1 createField: a unique slug id, placed after `after`, values copied with copyOf', function (assert) {
    const store = localRecords<Row>(
      [
        { id: 'a', name: 'Ana', qty: 1 },
        { id: 'b', name: 'Beto', qty: 2 }
      ],
      { getRecordId: getId, fields: FIELDS }
    );
    store.createField({ label: 'Qty', type: 'number' }, { index: 1 });
    assert.deepEqual(
      store.fields.map((field) => field.id),
      ['name', 'qty-2', 'qty'],
      'at the index without `after`'
    );
    store.createField(
      { label: 'Estado de ánimo', type: 'text' },
      { index: 0, after: 'qty' }
    );
    assert.deepEqual(
      store.fields.map((field) => field.id),
      ['name', 'qty-2', 'qty', 'estado-de-animo'],
      '`after` wins over the index'
    );
    store.createField(
      { label: 'Qty copy', type: 'number' },
      { index: 3, after: 'qty', copyOf: 'qty' }
    );
    assert.deepEqual(
      store.records.map((record) => record['qty-copy']),
      [1, 2]
    );
    assert.deepEqual(store.fields[3], {
      id: 'qty-copy',
      label: 'Qty copy',
      type: 'number'
    });
  });

  test('LF2 updateField: merged; a type change converts the values and logs what was lost', function (assert) {
    const store = localRecords<Row>(
      [
        { id: 'a', name: '12', qty: 1 },
        { id: 'b', name: 'abc', qty: 2 }
      ],
      { getRecordId: getId, fields: FIELDS }
    );
    store.updateField('qty', { label: 'Amount', type: 'number' });
    assert.deepEqual(store.fields[1], {
      id: 'qty',
      label: 'Amount',
      type: 'number'
    });
    assert.strictEqual(store.log.length, 0, 'same type: nothing converted');
    store.updateField('name', { label: 'Name', type: 'number' });
    assert.deepEqual(
      store.records.map((record) => record['name']),
      [12, null]
    );
    assert.strictEqual(store.log.length, 1);
    assert.deepEqual(
      store.log[0]!.rejected.map((rejection) => rejection.text),
      ['abc']
    );
  });

  test('LF3 deleteField: the field and its key in every record', function (assert) {
    const store = localRecords<Row>(
      [
        { id: 'a', name: 'Ana', qty: 1 },
        { id: 'b', name: 'Beto' }
      ],
      { getRecordId: getId, fields: FIELDS }
    );
    store.deleteField('qty');
    assert.deepEqual(
      store.fields.map((field) => field.id),
      ['name']
    );
    assert.deepEqual(store.records, [
      { id: 'a', name: 'Ana' },
      { id: 'b', name: 'Beto' }
    ]);
  });
});
