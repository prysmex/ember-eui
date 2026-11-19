/** Bulk resolve in the core: planPaste, planCommit, resolveCells (V02-DESIGN.md 8.2, RS1-RS4). */
import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  fillDown,
  pasteMatrix,
  planCommit,
  planPaste,
  resolveCells,
  withoutConflicts
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

/** A single-value app type that always needs the owner (as d04's zone). */
const zoneType: FieldType<{ id: string; label: string } | null> = {
  parse: (text) =>
    text.trim() === '' ? { value: null } : { unresolved: text.trim() },
  format: (value) => value?.label ?? '',
  equals: (a, b) => (a?.id ?? null) === (b?.id ?? null)
};

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name' },
  { id: 'links', type: 'linkedRecord', search: () => Promise.resolve([]) },
  { id: 'zone', type: 'zone' },
  { id: 'tags', type: 'multiSelect', options: [{ value: 'a', label: 'A' }] }
];

const ana = { id: 'p1', label: 'Ana' };
const bo = { id: 'p2', label: 'Bo' };

function ctx(records: Row[]): SheetContext<Row> {
  return {
    records,
    fields: FIELDS,
    getRecordId: (record) => record.id,
    types: { ...builtInFieldTypes, zone: zoneType },
    messages: defaultMessages
  };
}

const rows = (): Row[] => [
  { id: 'r0', name: 'x', links: [], zone: null, tags: [] },
  { id: 'r1', name: 'y', links: [ana], zone: null, tags: ['a'] }
];

module('Unit | Sheet | resolve', function () {
  test('RS1 planPaste splits the synchronous part from the pending cells', function (assert) {
    const c = ctx(rows());
    const matrix = [
      ['n0', 'Ana, Bo', 'Dock'],
      ['n1', 'Bo', '']
    ];
    const plan = planPaste(c, { row: 0, col: 0 }, matrix);
    assert.deepEqual(
      plan.changeSet,
      {
        source: 'paste',
        patches: [
          { recordId: 'r0', fieldId: 'name', from: 'x', to: 'n0' },
          { recordId: 'r1', fieldId: 'name', from: 'y', to: 'n1' }
        ],
        inserts: [],
        rejected: [],
        newOptions: []
      },
      'names at once; an empty zone is unchanged'
    );
    assert.deepEqual(plan.pending, [
      {
        recordId: 'r0',
        fieldId: 'links',
        text: 'Ana, Bo',
        parts: ['Ana', 'Bo']
      },
      { recordId: 'r0', fieldId: 'zone', text: 'Dock', parts: ['Dock'] },
      { recordId: 'r1', fieldId: 'links', text: 'Bo', parts: ['Bo'] }
    ]);
    // without resolve, the same paste rejects them (v0.1)
    const plain = pasteMatrix(c, { row: 0, col: 0 }, matrix)!;
    assert.deepEqual(
      plain.rejected.map((r) => [r.recordId, r.fieldId, r.message]),
      [
        ['r0', 'links', '"Ana, Bo" could not be resolved'],
        ['r0', 'zone', '"Dock" could not be resolved'],
        ['r1', 'links', '"Bo" could not be resolved']
      ]
    );
    assert.deepEqual(plain.patches, plan.changeSet!.patches);
    // an equal array is not a patch (equals)
    const same = planPaste(c, { row: 1, col: 3 }, [['A']]);
    assert.strictEqual(same.changeSet, null, 'tags already ["a"]');
    assert.strictEqual(
      fillDown(
        {
          ...c,
          records: [rows()[1]!, { ...rows()[1]!, id: 'r2', tags: ['a'] }]
        },
        { top: 0, left: 3, bottom: 1, right: 3 }
      ),
      null,
      'fill of an equal array: nothing'
    );
  });

  test('RS2 requests: one per field, distinct texts', function (assert) {
    const records = rows();
    const plan = planPaste(ctx(records), { row: 0, col: 1 }, [
      ['Ana, Bo', 'Dock'],
      ['Bo, Ana', 'Dock']
    ]);
    assert.deepEqual(plan.requests, [
      {
        fieldId: 'links',
        texts: ['Ana', 'Bo'],
        cells: [
          { text: 'Ana, Bo', recordId: 'r0', record: records[0] },
          { text: 'Bo, Ana', recordId: 'r1', record: records[1] }
        ]
      },
      {
        fieldId: 'zone',
        texts: ['Dock'],
        cells: [
          { text: 'Dock', recordId: 'r0', record: records[0] },
          { text: 'Dock', recordId: 'r1', record: records[1] }
        ]
      }
    ]);
    const typed = planCommit(ctx(records), { row: 1, col: 1 }, 'Bo');
    assert.strictEqual(typed.changeSet, null);
    assert.deepEqual(typed.pending, [
      { recordId: 'r1', fieldId: 'links', text: 'Bo', parts: ['Bo'] }
    ]);
    assert.deepEqual(typed.requests, [
      {
        fieldId: 'links',
        texts: ['Bo'],
        cells: [{ text: 'Bo', recordId: 'r1', record: records[1] }]
      }
    ]);
    const plainText = planCommit(ctx(records), { row: 0, col: 0 }, 'z');
    assert.deepEqual(plainText.pending, []);
    assert.deepEqual(plainText.changeSet?.patches, [
      { recordId: 'r0', fieldId: 'name', from: 'x', to: 'z' }
    ]);
  });

  test('RS3 resolveCells: values, null gives a rejection, parts combine', function (assert) {
    const records = rows();
    const plan = planPaste(ctx(records), { row: 0, col: 1 }, [
      ['Ana, Bo', 'Dock'],
      ['Bo, Zed', 'Nowhere']
    ]);
    const dock = { id: 'z1', label: 'Dock' };
    const set = resolveCells(ctx(records), plan.pending, {
      links: { Ana: ana, Bo: bo, Zed: null },
      zone: { Dock: dock }
    });
    assert.deepEqual(set, {
      source: 'resolve',
      patches: [
        { recordId: 'r0', fieldId: 'links', from: [], to: [ana, bo] },
        { recordId: 'r0', fieldId: 'zone', from: null, to: dock }
      ],
      inserts: [],
      rejected: [
        {
          recordId: 'r1',
          fieldId: 'links',
          text: 'Bo, Zed',
          message: '"Zed" could not be resolved'
        },
        {
          recordId: 'r1',
          fieldId: 'zone',
          text: 'Nowhere',
          message: '"Nowhere" could not be resolved'
        }
      ],
      newOptions: []
    });
    // `from` is read now: the record changed meanwhile
    const later = [{ ...records[0]!, links: [bo] }, records[1]!];
    const again = resolveCells(ctx(later), plan.pending.slice(0, 1), {
      links: { Ana: ana, Bo: bo }
    });
    assert.deepEqual(again?.patches, [
      { recordId: 'r0', fieldId: 'links', from: [bo], to: [ana, bo] }
    ]);
    // an equal value is no patch
    assert.strictEqual(
      resolveCells(ctx(records), [plan.pending[0]!], {
        links: { Ana: { ...ana }, Bo: { ...bo } }
      })?.patches.length,
      1
    );
    const unchanged = resolveCells(
      ctx([{ ...records[0]!, links: [ana, bo] }]),
      [plan.pending[0]!],
      { links: { Ana: ana, Bo: bo } }
    );
    assert.strictEqual(unchanged, null, 'same ids: nothing');
    // the undo conflict check uses equals: an equal array is not a conflict
    const equals = (fieldId: string, a: unknown, b: unknown) =>
      fieldId === 'links'
        ? builtInFieldTypes['linkedRecord']!.equals!(a, b)
        : Object.is(a, b);
    assert.ok(
      withoutConflicts(set!, [{ id: 'r0', links: [] }], (r: Row) => r.id, {
        equals
      })?.patches.length,
      'a fresh [] equals the patch from []'
    );
  });

  test('RS4 a pending cell in an inserted row patches its tempId', function (assert) {
    const records = rows();
    let n = 0;
    const plan = planPaste(
      ctx(records),
      { row: 2, col: 0 },
      [
        ['', 'Ana'],
        ['', 'Bo']
      ],
      { nextTempId: () => `t${++n}` }
    );
    assert.deepEqual(
      plan.changeSet?.inserts.map((insert) => [insert.tempId, insert.values]),
      [
        ['t1', { name: '' }],
        ['t2', { name: '' }]
      ],
      'rows past the end get their inserts'
    );
    assert.deepEqual(plan.pending, [
      { tempId: 't1', fieldId: 'links', text: 'Ana', parts: ['Ana'] },
      { tempId: 't2', fieldId: 'links', text: 'Bo', parts: ['Bo'] }
    ]);
    assert.deepEqual(
      plan.requests[0]!.cells[0],
      {
        text: 'Ana',
        tempId: 't1',
        record: { name: '' } as unknown as Row
      },
      'the accepted values of the inserted row'
    );
    // a row past the end with only a pending cell is still inserted
    const only = planPaste(ctx(records), { row: 2, col: 1 }, [['Ana']], {
      nextTempId: () => 'solo'
    });
    assert.deepEqual(
      only.changeSet?.inserts.map((i) => [i.tempId, i.values]),
      [['solo', {}]]
    );
    // before the owner applied the insert: from is undefined
    const set = resolveCells(ctx(records), plan.pending, {
      links: { Ana: ana, Bo: null }
    });
    assert.deepEqual(set?.patches, [
      { recordId: 't1', fieldId: 'links', from: undefined, to: [ana] }
    ]);
    assert.deepEqual(set?.rejected, [
      {
        tempId: 't2',
        fieldId: 'links',
        text: 'Bo',
        message: '"Bo" could not be resolved'
      }
    ]);
  });
});
