/** EuiSheet with the five built-in field types: cases N1-N20 (PACKAGE-DESIGN.md 10.3). */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  doubleClick,
  fillIn,
  render,
  settled,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  cellTitle,
  changeSet,
  clipboard,
  editor,
  editorFrame,
  el,
  focusCell,
  isInvalid,
  press,
  pressed,
  text,
  type
} from '../../helpers/sheet.ts';

import type {
  CellErrors,
  EuiSheetField,
  SheetOption
} from '#src/core/index.ts';

interface Task {
  id: string;
  name: string;
  qty: number | null;
  done: boolean;
  status: string | null;
  due: string | null;
  [key: string]: unknown;
}

const STATUS: SheetOption[] = [
  { value: 'open', label: 'Open' },
  { value: 'closed', label: 'Closed', color: 'success' },
  { value: 'hold', label: 'On hold' }
];

const FIELDS: EuiSheetField<Task>[] = [
  { id: 'name', required: true },
  { id: 'qty', type: 'number' },
  { id: 'done', type: 'checkbox' },
  { id: 'status', type: 'singleSelect', options: STATUS },
  { id: 'due', type: 'date' }
];

const tasks = (count = 5): Task[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    name: `name${i}`,
    qty: i,
    done: false,
    status: 'open',
    due: null
  }));

const getId = (record: { id: string }) => record.id;

class State {
  @tracked cellErrors: CellErrors | undefined;
  @tracked readOnly = false;
}

/** An option's label, without the screen-reader instructions EuiSelectable adds. */
function labelOf(option: Element): string {
  const copy = option.cloneNode(true) as Element;
  copy
    .querySelectorAll('.euiScreenReaderOnly')
    .forEach((element) => element.remove());
  return copy.textContent?.trim() ?? '';
}

/** The label of the select editor's current option. */
function activeLabel(): string | null {
  const id = editor()?.getAttribute('aria-activedescendant');
  const option = id ? document.getElementById(id) : null;
  return option ? labelOf(option) : null;
}

/** The labels the open select editor lists. */
function listed(): string[] {
  return Array.from(editorFrame()?.querySelectorAll('[role=option]') ?? []).map(
    labelOf
  );
}

function option(label: string): HTMLElement {
  const found = Array.from(
    editorFrame()?.querySelectorAll<HTMLElement>('[role=option]') ?? []
  ).find((element) => labelOf(element) === label);
  if (!found) throw new Error(`No option ${label}`);
  return found;
}

module('Integration | Component | EuiSheet field types', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(
    options: {
      records?: (records: Task[]) => Task[];
      fields?: (fields: EuiSheetField<Task>[]) => EuiSheetField<Task>[];
      state?: State;
      count?: number;
      height?: number;
    } = {}
  ) {
    const records = (options.records ?? ((r) => r))(tasks(options.count));
    const height = options.height;
    const fields = (options.fields ?? ((f) => f))(FIELDS);
    const store = localRecords<Task>(records, { getRecordId: getId, fields });
    const state = options.state ?? new State();
    await render(
      <template>
        <div style="width:900px">
          <EuiSheet
            @records={{store.records}}
            @fields={{store.fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @cellErrors={{state.cellErrors}}
            @readOnly={{state.readOnly}}
            @height={{height}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('N1 number: typing saves a number', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 1);
    await type('7');
    assert.dom(editor()).hasAttribute('inputmode', 'decimal');
    assert.dom(editor()).hasAttribute('type', 'text');
    await press('Enter');
    assert.deepEqual(store.log, [
      changeSet({
        source: 'edit',
        patches: [{ recordId: 'r0', fieldId: 'qty', from: 0, to: 7 }]
      })
    ]);
    assert.strictEqual(typeof store.records[0]!.qty, 'number');
  });

  test('N2 number: paste of abc gives a cell error', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 1);
    await clipboard('paste', 'abc');
    assert.deepEqual(store.log, [
      changeSet({
        source: 'paste',
        rejected: [
          {
            recordId: 'r0',
            fieldId: 'qty',
            text: 'abc',
            message: '"abc" is not a number'
          }
        ]
      })
    ]);
    assert.strictEqual(text(0, 1), 'abc');
    assert.true(isInvalid(0, 1), 'invalid');
    assert.strictEqual(cellTitle(0, 1), '"abc" is not a number');
    assert.strictEqual(store.records[0]!.qty, 0, 'the record keeps its value');
  });

  test('N3 number: typing an invalid text', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 1);
    await type('a');
    await fillIn(editor()!, 'abc');
    await press('Enter');
    assert.deepEqual(store.log[0]!.rejected, [
      {
        recordId: 'r0',
        fieldId: 'qty',
        text: 'abc',
        message: '"abc" is not a number'
      }
    ]);
    assert.deepEqual(store.log[0]!.patches, []);
    assert.strictEqual(text(0, 1), 'abc');
    assert.true(isInvalid(0, 1));
    assert.strictEqual(store.records[0]!.qty, 0);
    await waitUntil(() => document.activeElement === cell(1, 1));
    assert.strictEqual(document.activeElement, cell(1, 1), 'focus moved down');

    await focusCell(0, 1);
    await press('Enter');
    assert.strictEqual(
      editor()?.value,
      'abc',
      'the editor opens on the rejected text'
    );
    await fillIn(editor()!, '12');
    await press('Enter');
    assert.deepEqual(store.log[1]!.patches, [
      { recordId: 'r0', fieldId: 'qty', from: 0, to: 12 }
    ]);
    assert.false(isInvalid(0, 1), 'no longer invalid');
    assert.strictEqual(text(0, 1), '12');
  });

  test('N4 a rejection is cleared by Delete', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 1);
    await clipboard('paste', 'abc');
    assert.true(isInvalid(0, 1));
    await press('Delete');
    assert.false(isInvalid(0, 1), 'not invalid');
    assert.strictEqual(text(0, 1), '');
    assert.strictEqual(store.log.length, 2);
    assert.deepEqual(
      store.log[1],
      changeSet({
        source: 'clear',
        patches: [{ recordId: 'r0', fieldId: 'qty', from: 0, to: null }]
      })
    );
  });

  test('N5 a mixed paste', async function (assert) {
    const store = await renderSheet();
    await focusCell(1, 0);
    await clipboard('paste', 'x\tabc');
    assert.deepEqual(store.log, [
      changeSet({
        source: 'paste',
        patches: [{ recordId: 'r1', fieldId: 'name', from: 'name1', to: 'x' }],
        rejected: [
          {
            recordId: 'r1',
            fieldId: 'qty',
            text: 'abc',
            message: '"abc" is not a number'
          }
        ]
      })
    ]);
    assert.strictEqual(text(1, 0), 'x');
    assert.true(isInvalid(1, 1));
  });

  test('N6 checkbox: Space toggles', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 2);
    const box = () => el('[data-test-subj=euiSheetCheckbox]', cell(0, 2));
    assert.dom(box()).doesNotHaveClass('euiSheet__checkbox--checked');
    assert.true(await pressed(' '), 'prevented');
    assert.strictEqual(editor(), null, 'no editor');
    assert.dom(box()).hasClass('euiSheet__checkbox--checked');
    assert.true(await pressed(' '), 'prevented');
    assert.dom(box()).doesNotHaveClass('euiSheet__checkbox--checked');
    assert.deepEqual(
      store.log.map((set) => set.patches),
      [
        [{ recordId: 'r0', fieldId: 'done', from: false, to: true }],
        [{ recordId: 'r0', fieldId: 'done', from: true, to: false }]
      ]
    );
  });

  test('N7 checkbox: click toggles, other keys do nothing', async function (assert) {
    const store = await renderSheet();
    await click(el('[data-test-subj=euiSheetCheckbox]', cell(1, 2)));
    assert.deepEqual(
      store.log.map((set) => set.patches),
      [[{ recordId: 'r1', fieldId: 'done', from: false, to: true }]]
    );
    await focusCell(1, 2);
    await press('Enter');
    await press('F2');
    await type('x');
    await doubleClick(cell(1, 2));
    assert.strictEqual(editor(), null, 'no editor');
    assert.strictEqual(store.log.length, 1, 'no further change set');
    const box = el('[data-test-subj=euiSheetCheckbox]', cell(1, 2));
    assert.dom(box).doesNotHaveAttribute('tabindex');
    assert.dom('[data-euigrid-tab-managed]', cell(1, 2)).doesNotExist();
  });

  test('N8 checkbox: paste', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 2);
    await clipboard('paste', 'true\n1\nyes\nx\nno');
    assert.deepEqual(store.log[0]!.patches, [
      { recordId: 'r0', fieldId: 'done', from: false, to: true },
      { recordId: 'r1', fieldId: 'done', from: false, to: true },
      { recordId: 'r2', fieldId: 'done', from: false, to: true },
      { recordId: 'r3', fieldId: 'done', from: false, to: true }
    ]);
    await focusCell(0, 2);
    await clipboard('paste', 'false\n0\nmaybe');
    assert.deepEqual(store.log[1]!.patches, [
      { recordId: 'r0', fieldId: 'done', from: true, to: false },
      { recordId: 'r1', fieldId: 'done', from: true, to: false }
    ]);
    assert.deepEqual(store.log[1]!.rejected, [
      {
        recordId: 'r2',
        fieldId: 'done',
        text: 'maybe',
        message: '"maybe" is not a checkbox value'
      }
    ]);
    assert.strictEqual(text(2, 2), 'maybe', 'the rejected text shows as text');
    assert.true(isInvalid(2, 2));
  });

  test('N9 Space on a text cell does nothing', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 0);
    assert.true(await pressed(' '), 'prevented');
    assert.strictEqual(editor(), null);
    assert.strictEqual(store.log.length, 0);
  });

  test('N10 select: the cell shows a chip', async function (assert) {
    await renderSheet({
      records: (records) =>
        records.map((r) => (r.id === 'r1' ? { ...r, status: 'closed' } : r))
    });
    assert.dom('[data-test-subj=euiSheetChip]', cell(0, 3)).hasText('Open');
    const closed = el('[data-test-subj=euiSheetChip]', cell(1, 3));
    assert.dom(closed).hasText('Closed');
    assert.true(
      /euiBadge-success/.test(closed.className),
      `success colour class (${closed.className})`
    );
    assert
      .dom(el('[data-test-subj=euiSheetChip]', cell(0, 3)))
      .hasTagName('span');
  });

  test('N11 select: pick with the keyboard', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 3);
    await press('Enter');
    const frame = editorFrame()!;
    assert.dom(frame).hasClass('euiSheet__editor--panel');
    assert.false(el('.euiDataGrid').contains(frame), 'outside the grid');
    assert.true(
      el('[data-test-subj=euiSheet]').contains(frame),
      'inside the wrapper'
    );
    assert.strictEqual(
      document.activeElement,
      editor(),
      'the search has focus'
    );
    assert.dom(editor()).hasAttribute('data-test-subj', 'euiSheetSelectSearch');
    // V5: opened with Enter, the checked option (the current value) is the
    // current one (the design expected none, hence 2 presses)
    assert.strictEqual(
      activeLabel(),
      'Open',
      'the current value is the current option'
    );
    let presses = 0;
    while (activeLabel() !== 'Closed' && presses < 5) {
      await press('ArrowDown');
      presses++;
    }
    assert.strictEqual(presses, 1, 'one ArrowDown press');
    assert.strictEqual(editorFrame(), frame, 'still open');
    await press('Enter');
    assert.deepEqual(store.log, [
      changeSet({
        source: 'edit',
        patches: [
          { recordId: 'r0', fieldId: 'status', from: 'open', to: 'closed' }
        ]
      })
    ]);
    assert.strictEqual(editorFrame(), null, 'no editor');
    await waitUntil(() => document.activeElement === cell(1, 3));
    assert.strictEqual(document.activeElement, cell(1, 3));

    await press('Enter');
    assert.strictEqual(activeLabel(), 'Open', 'the current value');
    await press('Enter');
    assert.strictEqual(store.log.length, 1, 'no change set');
    assert.strictEqual(editorFrame(), null, 'the editor is closed');
  });

  test('N12 select: type to filter, Tab, Escape, click', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 3);
    await type('h');
    assert.strictEqual(editor()?.value, 'h', 'the search is seeded');
    assert.deepEqual(listed(), ['On hold']);
    // V5: after a seeded search no option is current; Tab and Enter take the
    // first match (the editor's fallback)
    assert.strictEqual(
      activeLabel(),
      null,
      'no current option after a seeded search'
    );
    await press('Tab');
    assert.deepEqual(
      store.log.map((set) => set.patches),
      [[{ recordId: 'r0', fieldId: 'status', from: 'open', to: 'hold' }]]
    );
    await waitUntil(() => document.activeElement === cell(0, 4));
    assert.strictEqual(document.activeElement, cell(0, 4));

    await focusCell(1, 3);
    await press('Enter');
    await press('Escape');
    assert.strictEqual(editorFrame(), null);
    assert.strictEqual(store.log.length, 1, 'Escape: no change set');
    await waitUntil(() => document.activeElement === cell(1, 3));
    assert.strictEqual(document.activeElement, cell(1, 3));

    await press('Enter');
    await click(option('Closed'));
    assert.deepEqual(store.log[1]!.patches, [
      { recordId: 'r1', fieldId: 'status', from: 'open', to: 'closed' }
    ]);
    assert.strictEqual(editorFrame(), null);
    await waitUntil(() => document.activeElement === cell(1, 3));
    assert.strictEqual(
      document.activeElement,
      cell(1, 3),
      'focus back on the cell'
    );

    await press('Enter');
    await click(cell(3, 0));
    assert.strictEqual(editorFrame(), null, 'closed by the click elsewhere');
    assert.strictEqual(store.log.length, 2, 'no change set');
    assert.strictEqual(document.activeElement, cell(3, 0));
  });

  test('N12 select: Enter after typing takes the first match', async function (assert) {
    const store = await renderSheet();
    await focusCell(2, 3);
    await type('c');
    assert.deepEqual(listed(), ['Closed']);
    await press('Enter');
    assert.deepEqual(
      store.log.map((set) => set.patches),
      [[{ recordId: 'r2', fieldId: 'status', from: 'open', to: 'closed' }]]
    );
    await waitUntil(() => document.activeElement === cell(3, 3));
    assert.strictEqual(document.activeElement, cell(3, 3), 'focus moved down');
  });

  test('N21 the select panel is not clipped and flips above near the bottom (V6)', async function (assert) {
    await renderSheet({ count: 30, height: 400 });
    /** Whether the point is painted by the panel (not clipped, not covered). */
    const paintsAt = (frame: HTMLElement, x: number, y: number) => {
      const hit = document.elementFromPoint(x, y);
      return !!hit && frame.contains(hit);
    };
    await focusCell(0, 3);
    await press('Enter');
    let frame = editorFrame()!;
    let box = frame.getBoundingClientRect();
    const top = cell(0, 3).getBoundingClientRect();
    assert.dom(frame).hasClass('euiSheet__editor--panel');
    assert.true(box.top >= top.bottom - 1, 'below the cell');
    assert.true(Math.abs(box.left - top.left) <= 1, 'aligned with the cell');
    assert.true(
      paintsAt(frame, box.left + box.width / 2, box.top + 4) &&
        paintsAt(frame, box.left + box.width / 2, box.bottom - 4),
      `the panel's top and bottom are painted (${JSON.stringify(box)})`
    );
    await press('Escape');

    const visible = Array.from(
      document.querySelectorAll<HTMLElement>(
        '[role=gridcell][data-gridcell-column-index="3"]'
      )
    ).map((element) => Number(element.dataset['gridcellVisibleRowIndex']));
    const wrapper = el('[data-test-subj=euiSheet]').getBoundingClientRect();
    // the last row that is fully inside the sheet's box
    const last = Math.max(
      ...visible.filter(
        (row) => cell(row, 3).getBoundingClientRect().bottom <= wrapper.bottom
      )
    );
    await focusCell(last, 3);
    await press('Enter');
    frame = editorFrame()!;
    box = frame.getBoundingClientRect();
    const bottom = cell(last, 3).getBoundingClientRect();
    assert.true(box.bottom <= bottom.top + 1, `above the cell of row ${last}`);
    assert.true(
      paintsAt(frame, box.left + box.width / 2, box.top + 4) &&
        paintsAt(frame, box.left + box.width / 2, box.bottom - 4),
      `the flipped panel is painted (${JSON.stringify(box)})`
    );
    assert.strictEqual(
      document.activeElement,
      editor(),
      'the search has focus'
    );
  });

  test('N13 select: options that depend on the record', async function (assert) {
    const AREAS: SheetOption[] = [
      { value: 'a', label: 'Area A' },
      { value: 'b', label: 'Area B' }
    ];
    const byArea: Record<string, SheetOption[]> = {
      a: [
        { value: 'a1', label: 'Operator' },
        { value: 'a2', label: 'Lead' }
      ],
      b: [{ value: 'b1', label: 'Supervisor' }]
    };
    const store = await renderSheet({
      records: (records) =>
        records.map((r) => ({ ...r, area: 'a', position: 'a1' })),
      fields: () => [
        { id: 'area', type: 'singleSelect', options: AREAS },
        {
          id: 'position',
          type: 'singleSelect',
          options: (record: Task) => byArea[record['area'] as string] ?? []
        }
      ]
    });
    await focusCell(0, 1);
    await press('Enter');
    assert.deepEqual(listed(), ['Operator', 'Lead'], "only area a's options");
    await press('Escape');

    await focusCell(0, 0);
    await clipboard('paste', 'Area B');
    assert.deepEqual(
      store.log[0]!.patches,
      [{ recordId: 'r0', fieldId: 'area', from: 'a', to: 'b' }],
      'no patch for position'
    );
    assert.strictEqual(store.records[0]!['position'], 'a1', 'position kept');
    assert.true(isInvalid(0, 1));
    assert.strictEqual(cellTitle(0, 1), '"a1" is not an option');
  });

  test('N14 select: paste of an unknown value', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 3);
    await clipboard('paste', 'Purple');
    assert.deepEqual(store.log[0]!.rejected, [
      {
        recordId: 'r0',
        fieldId: 'status',
        text: 'Purple',
        message: '"Purple" is not an option'
      }
    ]);
    assert.deepEqual(store.log[0]!.newOptions, []);
    assert.true(isInvalid(0, 3));
    assert.strictEqual(cellTitle(0, 3), '"Purple" is not an option');
    assert.strictEqual(text(0, 3), 'Purple');
    assert
      .dom('[data-test-subj=euiSheetChip]', cell(0, 3))
      .doesNotExist('plain text');

    await focusCell(1, 3);
    await clipboard('paste', 'closed');
    await focusCell(2, 3);
    await clipboard('paste', 'Closed');
    assert.deepEqual(
      store.log.slice(1).map((set) => set.patches),
      [
        [{ recordId: 'r1', fieldId: 'status', from: 'open', to: 'closed' }],
        [{ recordId: 'r2', fieldId: 'status', from: 'open', to: 'closed' }]
      ]
    );
  });

  test('N15 select: createOnPaste', async function (assert) {
    const store = await renderSheet({
      fields: (fields) =>
        fields.map((f) =>
          f.id === 'status' ? { ...f, createOnPaste: true } : f
        )
    });
    await focusCell(0, 3);
    await clipboard('paste', 'Purple');
    assert.deepEqual(store.log[0]!.newOptions, [
      { fieldId: 'status', option: { value: 'Purple', label: 'Purple' } }
    ]);
    assert.deepEqual(store.log[0]!.patches, [
      { recordId: 'r0', fieldId: 'status', from: 'open', to: 'Purple' }
    ]);
    await settled();
    assert.dom('[data-test-subj=euiSheetChip]', cell(0, 3)).hasText('Purple');
    assert.false(isInvalid(0, 3));
    await press('Enter');
    assert.true(
      listed().includes('Purple'),
      `the editor lists Purple (${listed().join(', ')})`
    );
  });

  test('N16 date: paste', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 4);
    await clipboard('paste', '2026-11-19');
    await focusCell(1, 4);
    await clipboard('paste', '19/11/2026');
    await focusCell(2, 4);
    await clipboard('paste', '31/02/2026');
    assert.deepEqual(
      store.log.map((set) => set.patches),
      [
        [{ recordId: 'r0', fieldId: 'due', from: null, to: '2026-11-19' }],
        [{ recordId: 'r1', fieldId: 'due', from: null, to: '2026-11-19' }],
        []
      ]
    );
    assert.strictEqual(text(0, 4), '19/11/2026');
    assert.strictEqual(text(1, 4), '19/11/2026');
    assert.true(isInvalid(2, 4));
    assert.strictEqual(cellTitle(2, 4), '"31/02/2026" is not a date');
    await focusCell(0, 4);
    const copied = await clipboard('copy');
    assert.strictEqual(copied.text, '2026-11-19');
  });

  test('N17 date: editors', async function (assert) {
    const store = await renderSheet({
      records: (records) =>
        records.map((r) => (r.id === 'r0' ? { ...r, due: '2026-11-19' } : r))
    });
    await focusCell(0, 4);
    await press('Enter');
    assert.dom(editor()).hasAttribute('type', 'date');
    assert.strictEqual(editor()?.value, '2026-11-19', 'the ISO value');
    assert.strictEqual(document.activeElement, editor());
    await fillIn(editor()!, '2026-12-01');
    await press('Enter');
    assert.deepEqual(store.log[0]!.patches, [
      { recordId: 'r0', fieldId: 'due', from: '2026-11-19', to: '2026-12-01' }
    ]);
    await waitUntil(() => document.activeElement === cell(1, 4));

    await type('1');
    assert.dom(editor()).hasAttribute('type', 'text');
    assert.strictEqual(editor()?.value, '1');
    await fillIn(editor()!, '1/2/2026');
    await press('Tab');
    assert.deepEqual(store.log[1]!.patches, [
      { recordId: 'r1', fieldId: 'due', from: null, to: '2026-02-01' }
    ]);
    await waitUntil(() => document.activeElement === cell(1, 4));
    await type('a');
    assert.strictEqual(editor(), null, 'a letter opens no date editor');
  });

  test('N18 required field cleared', async function (assert) {
    const store = await renderSheet({
      records: (records) =>
        records.map((r) => (r.id === 'r3' ? { ...r, name: '' } : r))
    });
    assert.true(isInvalid(3, 0), 'empty on first render');
    assert.strictEqual(cellTitle(3, 0), 'Required');
    await focusCell(0, 0);
    await press('Delete');
    assert.deepEqual(
      store.log[0]!.patches,
      [{ recordId: 'r0', fieldId: 'name', from: 'name0', to: '' }],
      'the patch is emitted'
    );
    assert.true(isInvalid(0, 0));
    assert.strictEqual(cellTitle(0, 0), 'Required');
  });

  test('N18 required as a function of the record', async function (assert) {
    await renderSheet({
      records: (records) =>
        records.map((r) => ({ ...r, name: '', done: r.id === 'r2' })),
      fields: (fields) =>
        fields.map((f) =>
          f.id === 'name' ? { ...f, required: (r: Task) => r.done } : f
        )
    });
    assert.deepEqual(
      [0, 1, 2, 3, 4].map((row) => isInvalid(row, 0)),
      [false, false, true, false, false]
    );
  });

  test('N19 owner @cellErrors', async function (assert) {
    const state = new State();
    state.cellErrors = { r1: { qty: 'Too many' } };
    await renderSheet({
      state,
      records: (records) =>
        records.map((r) => (r.id === 'r2' ? { ...r, name: '' } : r))
    });
    assert.true(isInvalid(1, 1));
    assert.strictEqual(cellTitle(1, 1), 'Too many');
    state.cellErrors = {
      r1: { qty: 'Too many' },
      r2: { name: 'Ask the owner' }
    };
    await settled();
    assert.strictEqual(
      cellTitle(2, 0),
      'Required\nAsk the owner',
      'owner errors last'
    );
    state.cellErrors = undefined;
    await settled();
    assert.false(isInvalid(1, 1), 'cleared');
    assert.strictEqual(cellTitle(1, 1), null);
    assert.strictEqual(cellTitle(2, 0), 'Required');
  });

  test('N20 @readOnly and a read-only function', async function (assert) {
    const state = new State();
    state.readOnly = true;
    const store = await renderSheet({ state });
    await focusCell(0, 0);
    await press('Enter');
    await type('x');
    assert.strictEqual(editor(), null, 'no editor');
    await focusCell(0, 2);
    await pressed(' ');
    await click(el('[data-test-subj=euiSheetCheckbox]', cell(0, 2)));
    await focusCell(0, 0);
    await press('Delete');
    await clipboard('paste', 'a\tb');
    assert.strictEqual(store.log.length, 0, 'nothing changed');
    const copied = await clipboard('copy');
    assert.strictEqual(copied.text, 'name0', 'copy still works');
  });

  test('N20 a read-only function on one field', async function (assert) {
    const store = await renderSheet({
      fields: (fields) =>
        fields.map((f) =>
          f.id === 'qty' ? { ...f, readOnly: (r: Task) => r.id === 'r1' } : f
        )
    });
    await focusCell(1, 1);
    await type('5');
    assert.strictEqual(editor(), null, 'r1.qty is locked');
    await focusCell(0, 1);
    await type('5');
    assert.ok(editor(), 'r0.qty is not');
    await press('Enter');
    await focusCell(0, 1);
    await clipboard('paste', '8\n9');
    assert.deepEqual(
      store.log.map((set) => set.patches),
      [
        [{ recordId: 'r0', fieldId: 'qty', from: 0, to: 5 }],
        [{ recordId: 'r0', fieldId: 'qty', from: 5, to: 8 }]
      ],
      'the paste skips the locked cell'
    );
  });
});
