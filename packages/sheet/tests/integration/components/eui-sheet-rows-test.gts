/**
 * Records (V02-DESIGN.md 5): row numbers, row and column selection, the
 * add row, Shift+Enter, the row menu, insert, delete and duplicate. The
 * add row's look (V03 5.2): AR1-AR8.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  focus,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  clipboard,
  el,
  focusCell,
  press,
  pressed,
  selected,
  text
} from '../../helpers/sheet.ts';

import type { ChangeSet, EuiSheetField, RecordId } from '#src/core/index.ts';
import type { SheetApi, SheetRowAction } from '#src/types.ts';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';

interface Row {
  id: string;
  name: string;
  city: string;
  qty: number | null;
  code?: string;
  notes?: string;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name' },
  { id: 'city' },
  { id: 'qty', type: 'number' }
];

const rows = (count: number): Row[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    name: `name${i}`,
    city: `city${i}`,
    qty: i,
    code: `c${i}`,
    notes: `note${i}`
  }));

const getId = (row: { id: string }) => row.id;

class State {
  @tracked readOnly = false;
  @tracked canInsert: boolean | undefined = undefined;
  @tracked canDelete: boolean | undefined = undefined;
  @tracked rowNumbers: boolean | undefined = undefined;
  @tracked rowNumberOffset: number | undefined = undefined;
  @tracked rowLabel: ((row: Row, position: number) => string) | undefined =
    undefined;
  @tracked checked: RecordId[] = [];
  @tracked fields: EuiSheetField<Row>[] = FIELDS;
  @tracked frozenFields: number | undefined = undefined;
  hiddenFields: EuiSheetField<Row>[] | undefined = undefined;
  newRecordValues:
    | ((context: {
        above: Row | undefined;
        below: Row | undefined;
      }) => Record<string, unknown>)
    | undefined = undefined;
  rowActions: SheetRowAction<Row>[] | undefined = undefined;
  onCheckedChange: ((ids: RecordId[]) => void) | undefined = undefined;
  api: SheetApi | null = null;
}

/** The row-number cell of a row (grid column 0). */
function rowCell(row: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"]`
  );
}

/** The header of a data column. */
function header(col: number): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-index="${col + 1}"]`);
}

function menu(): HTMLElement | null {
  return document.querySelector<HTMLElement>(
    '[data-test-subj=euiSheetRowMenu]'
  );
}

function menuLabels(): string[] {
  return Array.from(
    menu()?.querySelectorAll<HTMLElement>(
      '[data-test-subj^=euiSheetRowMenu-]'
    ) ?? []
  ).map((item) => item.textContent?.trim() ?? '');
}

async function pick(id: string): Promise<void> {
  await click(el(`[data-test-subj=euiSheetRowMenu-${id}]`));
}

/** A right-click on an element: the press, then the contextmenu event. */
async function rightClick(element: HTMLElement): Promise<void> {
  const box = element.getBoundingClientRect();
  const point = { clientX: box.left + 5, clientY: box.top + 5 };
  await triggerEvent(element, 'mousedown', { button: 2, ...point });
  await triggerEvent(element, 'contextmenu', { button: 2, ...point });
}

const recordsOf = (store: { records: Row[] }) =>
  store.records.map((row) => row.id);

module('Integration | Component | EuiSheet records', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(count = 4, state = new State()) {
    const store = localRecords<Row>(rows(count), { getRecordId: getId });
    const register = (api: SheetApi) => (state.api = api);
    await render(
      <template>
        <div style="width:800px">
          <EuiSheet
            @records={{store.records}}
            @fields={{state.fields}}
            @hiddenFields={{state.hiddenFields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @readOnly={{state.readOnly}}
            @canInsert={{state.canInsert}}
            @canDelete={{state.canDelete}}
            @rowNumbers={{state.rowNumbers}}
            @rowNumberOffset={{state.rowNumberOffset}}
            @rowLabel={{state.rowLabel}}
            @newRecordValues={{state.newRecordValues}}
            @rowActions={{state.rowActions}}
            @checkedRecordIds={{state.checked}}
            @onCheckedChange={{state.onCheckedChange}}
            @registerApi={{register}}
            @frozenFields={{state.frozenFields}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('RW1 row numbers: positions, @rowNumberOffset, @rowLabel, @rowNumbers={{false}}', async function (assert) {
    const state = new State();
    await renderSheet(3, state);
    const labels = () =>
      [0, 1, 2].map(
        (row) =>
          rowCell(row).querySelector('[data-test-subj=euiSheetRowLabel]')
            ?.textContent ?? ''
      );
    assert.deepEqual(labels(), ['1', '2', '3'], 'positions');
    assert.strictEqual(rowCell(1).getAttribute('aria-label'), 'Row 2');
    assert.strictEqual(text(1, 0), 'name1', 'data column 0 is the first field');
    assert.strictEqual(
      cell(1, 2).dataset['gridcellColumnId'],
      'qty',
      'the grid index of a data cell is shifted by one (C8)'
    );

    state.rowNumberOffset = 50;
    await settled();
    assert.deepEqual(labels(), ['51', '52', '53'], 'page offset');

    state.rowLabel = (row) => `#${row.id.toUpperCase()}-long-label`;
    await settled();
    assert.deepEqual(labels(), [
      '#R0-long-label',
      '#R1-long-label',
      '#R2-long-label'
    ]);
    assert.true(
      header(-1).getBoundingClientRect().width >
        64 *
          (rowCell(0).getBoundingClientRect().width / rowCell(0).offsetWidth),
      'the column grows for the labels'
    );

    state.rowNumbers = false;
    await settled();
    assert
      .dom('[data-gridcell-column-id=euiSheetRow]')
      .doesNotExist('no row-number column');
    assert.strictEqual(
      el(
        '[role=gridcell][data-gridcell-visible-row-index="1"][data-gridcell-column-index="0"]'
      ).dataset['gridcellColumnId'],
      'name'
    );
  });

  test('RW2 a row number selects the row, Shift+click extends, Delete clears them', async function (assert) {
    const store = await renderSheet();
    await click(rowCell(1));
    assert.deepEqual(selected(), ['1:0', '1:1', '1:2'], 'the whole row');
    assert.strictEqual(
      document.activeElement,
      rowCell(1),
      'focus on the number'
    );
    assert.strictEqual(rowCell(1).getAttribute('aria-selected'), 'true');

    await click(rowCell(2), { shiftKey: true });
    assert.deepEqual(selected(), ['1:0', '1:1', '1:2', '2:0', '2:1', '2:2']);

    assert.true(await pressed('Delete'), 'Delete is the sheet’s');
    assert.deepEqual(
      store.log.at(-1)!.patches.map((p) => `${p.recordId}.${p.fieldId}`),
      ['r1.name', 'r1.city', 'r1.qty', 'r2.name', 'r2.city', 'r2.qty']
    );
    assert.strictEqual(text(1, 0), '');

    // drag over the row numbers
    await triggerEvent(rowCell(0), 'mousedown', { button: 0 });
    await triggerEvent(rowCell(3), 'mouseover');
    await triggerEvent(rowCell(3), 'mouseup');
    assert.strictEqual(selected().length, 12, 'rows 0 to 3');
  });

  test('RW3 a header click selects the column; copy gives it; the actions button still opens', async function (assert) {
    await renderSheet(3);
    await focusCell(0, 0);
    await click(el('.euiDataGridHeaderCell__content', header(1)));
    assert.deepEqual(selected(), ['0:1', '1:1', '2:1'], 'the column');
    const copied = await clipboard('copy', '', header(1));
    assert.strictEqual(copied.text, 'city0\ncity1\ncity2', 'one column');
    assert.true(copied.prevented);

    await click(el('.euiDataGridHeaderCell__content', header(2)), {
      shiftKey: true
    });
    assert.strictEqual(selected().length, 6, 'Shift+click extends');

    // Delete with focus on the header clears the selected columns
    await click(el('.euiDataGridHeaderCell__content', header(1)));
    header(1).focus();
    await settled();
    assert.true(await pressed('Delete'), 'Delete on the header is the sheet’s');
    assert.deepEqual([text(0, 1), text(1, 1), text(2, 1)], ['', '', '']);
    assert.strictEqual(text(0, 0), 'name0', 'only the column');

    await click(el('[data-test-subj=dataGridHeaderCellActionButton-qty]'));
    await waitUntil(() =>
      document.querySelector(
        '[data-test-subj=dataGridHeaderCellActionGroup-qty]'
      )
    );
    assert.ok(true, 'the column actions menu opens');
  });

  test('RW4 checkboxes: toggle, Shift+click range, header, controlled', async function (assert) {
    await renderSheet(5);
    const check = (row: number) =>
      el('[data-test-subj=euiSheetRowCheck]', rowCell(row));
    const checkedRows = () =>
      [0, 1, 2, 3, 4].filter((row) =>
        rowCell(row).classList.contains('euiSheet__rowCell--checked')
      );
    await click(check(1));
    assert.deepEqual(checkedRows(), [1]);
    await click(check(3), { shiftKey: true });
    assert.deepEqual(checkedRows(), [1, 2, 3], 'Shift+click checks between');
    await click(check(2));
    assert.deepEqual(checkedRows(), [1, 3]);

    // Space on a row number toggles
    await click(rowCell(0));
    await pressed(' ');
    assert.deepEqual(checkedRows(), [0, 1, 3]);

    const all = el('[data-test-subj=euiSheetRowCheckAll]');
    assert.dom(all).hasClass('euiSheet__checkbox--mixed');
    await click(all);
    assert.deepEqual(checkedRows(), [0, 1, 2, 3, 4], 'all');
    assert.dom(all).hasClass('euiSheet__checkbox--checked');
    await click(all);
    assert.deepEqual(checkedRows(), [], 'none');
  });

  test('RW4 controlled @checkedRecordIds', async function (assert) {
    const state = new State();
    const calls: RecordId[][] = [];
    state.checked = ['r2'];
    state.onCheckedChange = (ids) => calls.push(ids);
    await renderSheet(4, state);
    assert.dom(rowCell(2)).hasClass('euiSheet__rowCell--checked');
    await click(el('[data-test-subj=euiSheetRowCheck]', rowCell(0)));
    assert.deepEqual(calls, [['r2', 'r0']], 'the handler gets the new list');
    assert
      .dom(rowCell(0))
      .doesNotHaveClass(
        'euiSheet__rowCell--checked',
        'not until the owner says'
      );
    state.checked = calls[0]!;
    await settled();
    assert.dom(rowCell(0)).hasClass('euiSheet__rowCell--checked');
  });

  test('RW5 the add row: a click inserts at the end, focus on the first editable field', async function (assert) {
    const state = new State();
    state.fields = [{ id: 'name', readOnly: true }, ...FIELDS.slice(1)];
    const store = await renderSheet(2, state);
    assert.dom('.euiSheet__addRow').exists('the add row');
    assert.strictEqual(
      el('[data-test-subj=euiSheetAddRecord]', cell(2, 0)).textContent?.trim(),
      'Add record'
    );
    await click(cell(2, 1));
    assert.strictEqual(store.log.length, 1);
    const set = store.log[0]!;
    const tempId = set.inserts[0]!.tempId;
    assert.deepEqual(set, {
      source: 'insert',
      patches: [],
      inserts: [
        {
          tempId,
          index: 2,
          values: {},
          anchor: { recordId: 'r1', position: 'after' }
        }
      ],
      rejected: [],
      newOptions: []
    });
    assert.deepEqual(recordsOf(store), ['r0', 'r1', tempId]);
    await settled();
    assert.strictEqual(
      document.activeElement,
      cell(2, 1),
      'focus on the new row’s first editable field'
    );
    const addRows = document.querySelectorAll<HTMLElement>('.euiSheet__addRow');
    assert.strictEqual(addRows.length, 1, 'one add row');
    assert.true(
      addRows[0]!.contains(cell(3, 0)),
      'it is the row after the new record'
    );

    // Enter on the add row, and a click on its row number
    await focusCell(3, 0);
    await press('Enter');
    await click(rowCell(4));
    assert.strictEqual(store.records.length, 5);
    assert.deepEqual(
      store.log.map((s) => s.source),
      ['insert', 'insert', 'insert']
    );
    // typing and Delete on the add row do nothing
    await focusCell(5, 1);
    await pressed('Delete');
    assert.strictEqual(store.log.length, 3);
  });

  test('RW6 Shift+Enter inserts below with an anchor; focus on the new row', async function (assert) {
    const store = await renderSheet(3);
    await focusCell(1, 2);
    assert.true(await pressed('Enter', { shiftKey: true }));
    const set = store.log[0]!;
    assert.strictEqual(set.source, 'insert');
    assert.deepEqual(set.inserts[0]!.anchor, {
      recordId: 'r1',
      position: 'after'
    });
    assert.strictEqual(set.inserts[0]!.index, 2);
    assert.deepEqual(recordsOf(store), [
      'r0',
      'r1',
      set.inserts[0]!.tempId,
      'r2'
    ]);
    await settled();
    assert.strictEqual(
      document.activeElement,
      cell(2, 2),
      'same field, new row'
    );
    assert.strictEqual(
      document.querySelector('[data-test-subj=euiSheetEditor]'),
      null,
      'no editor (v0.1 opened one)'
    );
  });

  test('RW7 the row menu: items, change sets, right-click selection, Escape', async function (assert) {
    const store = await renderSheet(4);
    await focusCell(1, 1);
    await rightClick(cell(2, 0));
    assert.ok(menu(), 'right-click opens the menu');
    assert.deepEqual(
      selected(),
      ['2:0'],
      'outside the range: selects that cell'
    );
    assert.deepEqual(menuLabels(), [
      'Insert record above',
      'Insert record below',
      'Duplicate record',
      'Expand record',
      'Copy row',
      'Delete record'
    ]);
    assert.strictEqual(
      document.activeElement,
      el('[data-test-subj=euiSheetRowMenu-insertAbove]'),
      'the first item has focus'
    );
    await press('Escape');
    assert.strictEqual(menu(), null, 'Escape closes');
    assert.strictEqual(document.activeElement, cell(2, 0), 'and re-focuses');

    // Insert above
    await rightClick(cell(2, 0));
    await pick('insertAbove');
    let set = store.log.at(-1)!;
    assert.deepEqual(
      [set.source, set.inserts[0]!.index, set.inserts[0]!.anchor],
      ['insert', 2, { recordId: 'r2', position: 'before' }]
    );
    await settled();
    assert.strictEqual(document.activeElement, cell(2, 0), 'on the new row');
    const above = set.inserts[0]!.tempId;

    // a range inside: right-click keeps it; Shift+F10 opens it too
    await focusCell(3, 0);
    await press('ArrowDown', { shiftKey: true });
    assert.deepEqual(selected(), ['3:0', '4:0']);
    await rightClick(cell(4, 0));
    assert.deepEqual(selected(), ['3:0', '4:0'], 'inside the range: kept');
    assert.deepEqual(menuLabels().slice(2, 5), [
      'Duplicate 2 records',
      'Copy 2 rows',
      'Delete 2 records'
    ]);
    await pick('delete');
    set = store.log.at(-1)!;
    assert.deepEqual(set.deletes, ['r2', 'r3']);
    assert.deepEqual(
      set.removed!.map((r) => [r.recordId, r.index, r.after]),
      [
        ['r2', 3, above],
        ['r3', 4, 'r2']
      ]
    );
    assert.deepEqual(recordsOf(store), ['r0', 'r1', above]);
    await settled();

    await focusCell(0, 1);
    assert.true(await pressed('F10', { shiftKey: true }), 'Shift+F10');
    assert.ok(menu());
    await pick('insertBelow');
    set = store.log.at(-1)!;
    assert.deepEqual(set.inserts[0]!.anchor, {
      recordId: 'r0',
      position: 'after'
    });
    await settled();
    assert.strictEqual(document.activeElement, cell(1, 1));

    // a click outside closes
    await rightClick(cell(0, 0));
    await triggerEvent(document.body, 'mousedown');
    assert.strictEqual(menu(), null, 'a press outside closes');

    // Expand record opens it; closing it focuses the cell again
    await rightClick(cell(1, 2));
    await pick('expand');
    const shell = document.querySelector<HTMLElement>(
      '[data-test-subj=euiSheetRecord]'
    );
    assert.ok(shell, 'the expanded record');
    await triggerEvent(shell!, 'keydown', { key: 'Escape' });
    await waitUntil(() => document.activeElement === cell(1, 2));
    assert.strictEqual(document.activeElement, cell(1, 2));
  });

  test('RW8 delete then Ctrl+Z restores the same objects at their indexes; Ctrl+Shift+Z deletes again', async function (assert) {
    const store = await renderSheet(5);
    const before = [...store.records];
    await click(rowCell(1));
    await click(rowCell(3), { shiftKey: true });
    await rightClick(rowCell(2));
    await pick('delete');
    assert.deepEqual(recordsOf(store), ['r0', 'r4']);
    await settled();
    assert.strictEqual(document.activeElement, cell(1, 0), 'the next record');

    assert.true(await pressed('z', { ctrlKey: true }));
    assert.deepEqual(recordsOf(store), ['r0', 'r1', 'r2', 'r3', 'r4']);
    assert.true(
      store.records.every((row, i) => row === before[i]),
      'the same objects'
    );
    await pressed('Z', { ctrlKey: true, shiftKey: true });
    assert.deepEqual(recordsOf(store), ['r0', 'r4'], 'deleted again');
  });

  test('RW9 duplicate copies the writable fields, hidden ones too', async function (assert) {
    const state = new State();
    state.fields = [{ id: 'name' }, { id: 'city', readOnly: true }, FIELDS[2]!];
    state.hiddenFields = [{ id: 'notes' }, { id: 'code', readOnly: true }];
    const store = await renderSheet(3, state);
    await rightClick(rowCell(1));
    await pick('duplicate');
    const set = store.log[0]!;
    assert.deepEqual(set.inserts[0]!.values, {
      name: 'name1',
      qty: 1,
      notes: 'note1'
    });
    assert.deepEqual(set.inserts[0]!.anchor, {
      recordId: 'r1',
      position: 'after'
    });
    assert.strictEqual(store.records[2]!.id, set.inserts[0]!.tempId);
    // checked rows: those are the menu's records
    await click(el('[data-test-subj=euiSheetRowCheck]', rowCell(0)));
    await click(el('[data-test-subj=euiSheetRowCheck]', rowCell(3)));
    await rightClick(cell(1, 0));
    assert.true(menuLabels().includes('Duplicate 2 records'));
    await pick('duplicate');
    assert.deepEqual(
      store.log.at(-1)!.inserts.map((i) => i.anchor?.recordId),
      ['r0', 'r2']
    );
  });

  test('RW10 @readOnly, @canInsert and @canDelete', async function (assert) {
    const state = new State();
    state.readOnly = true;
    const store = await renderSheet(2, state);
    assert.dom('.euiSheet__addRow').doesNotExist('read-only: no add row');
    await rightClick(cell(0, 0));
    assert.deepEqual(menuLabels(), ['Expand record', 'Copy row']);
    await press('Escape');
    await focusCell(0, 0);
    await pressed('Enter', { shiftKey: true });
    assert.strictEqual(store.log.length, 0, 'Shift+Enter inserts nothing');

    state.readOnly = false;
    state.canInsert = false;
    await settled();
    assert.dom('.euiSheet__addRow').doesNotExist('no add row');
    await rightClick(cell(0, 0));
    assert.deepEqual(menuLabels(), [
      'Expand record',
      'Copy row',
      'Delete record'
    ]);
    await press('Escape');

    state.canInsert = true;
    state.canDelete = false;
    await settled();
    assert.dom('.euiSheet__addRow').exists();
    await rightClick(cell(0, 0));
    assert.false(menuLabels().includes('Delete record'));
  });

  test('RW10 @canInsert={{false}}: a paste only fills the rows that exist', async function (assert) {
    const state = new State();
    state.canInsert = false;
    const store = await renderSheet(2, state);
    await focusCell(1, 0);
    await clipboard('paste', 'a\nb\nc');
    assert.deepEqual(recordsOf(store), ['r0', 'r1'], 'no insert');
    assert.deepEqual(store.log[0]!.inserts, []);
    assert.strictEqual(text(1, 0), 'a');
  });

  test('RW11 paste on the add row inserts', async function (assert) {
    const store = await renderSheet(2);
    await focusCell(2, 0);
    await clipboard('paste', 'a\tb\nc\td');
    assert.deepEqual(
      store.records.slice(2).map((row) => [row.name, row.city]),
      [
        ['a', 'b'],
        ['c', 'd']
      ]
    );
    assert.strictEqual(store.log[0]!.source, 'paste');
  });

  test('RW12 @rowActions get the records of the selection', async function (assert) {
    const state = new State();
    const got: string[][] = [];
    state.rowActions = [
      {
        id: 'archive',
        label: 'Archive',
        icon: 'folderClosed',
        onSelect: (records) => got.push(records.map((r) => r.id))
      },
      {
        id: 'never',
        label: 'Never',
        isDisabled: () => true,
        onSelect: () => got.push(['never'])
      }
    ];
    await renderSheet(4, state);
    await click(rowCell(1));
    await click(rowCell(2), { shiftKey: true });
    await rightClick(rowCell(1));
    assert.deepEqual(menuLabels().slice(-3), [
      'Archive',
      'Never',
      'Delete 2 records'
    ]);
    assert
      .dom('[data-test-subj=euiSheetRowMenu-never]')
      .isDisabled('isDisabled disables the item');
    await pick('archive');
    assert.deepEqual(got, [['r1', 'r2']]);
    assert.strictEqual(menu(), null);
    assert.strictEqual(document.activeElement, rowCell(1), 'focus back');
  });

  test('RW13 the control cells have no tabbable element and no focus trap', async function (assert) {
    await renderSheet(3);
    const cells = Array.from(
      document.querySelectorAll<HTMLElement>(
        '[data-gridcell-column-id=euiSheetRow]'
      )
    );
    assert.strictEqual(cells.length, 5, 'header, 3 records, the add row');
    const tabbable =
      'a[href], button, input, select, textarea, [contenteditable], [tabindex]';
    for (const control of cells) {
      const found = Array.from(
        control.querySelectorAll<HTMLElement>(tabbable)
      ).filter((element) => element.getAttribute('tabindex') !== '-1');
      assert.deepEqual(found, [], `${control.getAttribute('aria-label')}`);
      assert.strictEqual(
        control.getAttribute('aria-describedby'),
        null,
        'no focus-trap hint'
      );
    }
    // the add row's first data cell too
    assert.strictEqual(cell(3, 0).querySelectorAll('button, input').length, 0);
  });

  test('RW14 @newRecordValues', async function (assert) {
    const state = new State();
    const seen: Array<[string | undefined, string | undefined]> = [];
    state.newRecordValues = ({ above, below }) => {
      seen.push([above?.id, below?.id]);
      return { city: above?.city ?? 'none' };
    };
    const store = await renderSheet(2, state);
    await focusCell(0, 0);
    await pressed('Enter', { shiftKey: true });
    assert.deepEqual(store.log[0]!.inserts[0]!.values, { city: 'city0' });
    await click(cell(3, 0));
    assert.deepEqual(seen, [
      ['r0', 'r1'],
      ['r1', undefined]
    ]);
    assert.deepEqual(store.log[1]!.inserts[0]!.values, { city: 'city1' });
  });

  test('RW15 Home and Ctrl+Home land on the first field; ArrowLeft reaches the row number and clears the range', async function (assert) {
    const store = await renderSheet(3);
    await focusCell(2, 2);
    assert.true(await pressed('Home'));
    await settled();
    assert.strictEqual(document.activeElement, cell(2, 0), 'Home');
    await focusCell(2, 2);
    await pressed('Home', { ctrlKey: true });
    await settled();
    assert.strictEqual(document.activeElement, cell(0, 0), 'Ctrl+Home');

    await press('ArrowLeft');
    await settled();
    assert.strictEqual(document.activeElement, rowCell(0), 'the row number');
    assert.deepEqual(selected(), [], 'no range');
    await pressed('Delete');
    const copied = await clipboard('copy');
    assert.strictEqual(store.log.length, 0, 'Delete does nothing');
    assert.false(copied.prevented, 'copy is not the sheet’s');

    // Shift+ArrowDown on row numbers selects rows
    await pressed('ArrowDown', { shiftKey: true });
    await settled();
    assert.strictEqual(document.activeElement, rowCell(1));
    assert.deepEqual(selected(), ['0:0', '0:1', '0:2', '1:0', '1:1', '1:2']);
    await press('ArrowRight');
    await settled();
    assert.deepEqual(selected(), ['1:0'], 'back to cells');
  });

  test('RW16 the API: insertRecord, deleteRecords, expandRecord', async function (assert) {
    const state = new State();
    const store = await renderSheet(3, state);
    state.api!.insertRecord({ anchor: { recordId: 'r0', position: 'after' } });
    await settled();
    assert.strictEqual(store.records[1]!.id, store.log[0]!.inserts[0]!.tempId);
    state.api!.insertRecord({ values: { name: 'end' } });
    await settled();
    assert.strictEqual(store.records.at(-1)!.name, 'end');
    state.api!.deleteRecords(['r1', 'nope']);
    await settled();
    assert.deepEqual(store.log.at(-1)!.deletes, ['r1']);
    state.api!.expandRecord('r2');
    await settled();
    assert.dom('[data-test-subj=euiSheetRecord]', document.body).exists();
    state.api!.expandRecord(null);
    await settled();
    assert.dom('[data-test-subj=euiSheetRecord]', document.body).doesNotExist();
    const sets: ChangeSet[] = store.log;
    assert.deepEqual(
      sets.map((s) => s.source),
      ['insert', 'insert', 'delete']
    );
  });

  test('RW17 copy rows writes the visible fields as TSV', async function (assert) {
    const written: string[] = [];
    const clip = navigator.clipboard as unknown as {
      writeText: (text: string) => Promise<void>;
    };
    const original = Object.getOwnPropertyDescriptor(clip, 'writeText');
    Object.defineProperty(clip, 'writeText', {
      configurable: true,
      value: (value: string) => {
        written.push(value);
        return Promise.resolve();
      }
    });
    try {
      await renderSheet(3);
      await click(rowCell(0));
      await click(rowCell(1), { shiftKey: true });
      await rightClick(rowCell(0));
      await pick('copy');
      assert.deepEqual(written, ['name0\tcity0\t0\nname1\tcity1\t1']);

      // writeText rejects (no permission): a textarea and execCommand
      Object.defineProperty(clip, 'writeText', {
        configurable: true,
        value: () => Promise.reject(new Error('denied'))
      });
      const commands: string[] = [];
      const copied: string[] = [];
      const execCommand = document.execCommand;
      document.execCommand = (command: string) => {
        commands.push(command);
        copied.push((document.activeElement as HTMLTextAreaElement).value);
        return true;
      };
      try {
        await rightClick(rowCell(2));
        await pick('copy');
        await waitUntil(() => commands.length > 0);
      } finally {
        document.execCommand = execCommand;
      }
      assert.deepEqual(commands, ['copy']);
      assert.deepEqual(copied, ['name2\tcity2\t2'], 'the selected text');
      assert.strictEqual(
        document.querySelectorAll('textarea').length,
        0,
        'the textarea is removed'
      );
    } finally {
      if (original) Object.defineProperty(clip, 'writeText', original);
      else delete (clip as { writeText?: unknown }).writeText;
    }
  });
  /* The add row's look (V03 5.2) */

  function addRowCells(): HTMLElement[] {
    return Array.from(
      document.querySelectorAll<HTMLElement>(
        '.euiSheet__addRow [role=gridcell]'
      )
    );
  }

  /** A computed colour of `var(--euiSheet-<name>)`, read from a probe in the sheet. */
  function sheetColor(name: string): string {
    const probe = document.createElement('span');
    probe.style.color = `var(--euiSheet-${name})`;
    el('[data-test-subj=euiSheet]').appendChild(probe);
    const color = getComputedStyle(probe).color;
    probe.remove();
    return color;
  }

  function isOpaque(color: string): boolean {
    const match = /^rgba?\(([^)]+)\)$/.exec(color);
    if (!match) return false;
    const parts = match[1]!.split(',').map((part) => part.trim());
    return parts.length === 3 || Number(parts[3]) === 1;
  }

  function isInvisible(width: string, style: string, color: string): boolean {
    return (
      parseFloat(width) === 0 ||
      style === 'none' ||
      color === 'rgba(0, 0, 0, 0)'
    );
  }

  /** Every cell of the add row has the same opaque background (AR3, AR4). */
  function assertOneBackground(assert: Assert, label: string): void {
    const cells = addRowCells();
    assert.true(cells.length >= 4, `${label}: the row's cells are rendered`);
    const colors = cells.map((c) => getComputedStyle(c).backgroundColor);
    const images = cells.map((c) => getComputedStyle(c).backgroundImage);
    assert.deepEqual(
      [...new Set(colors)],
      [colors[0]],
      `${label}: one background colour (${colors.join(' | ')})`
    );
    assert.deepEqual([...new Set(images)], ['none'], `${label}: no image`);
    assert.true(isOpaque(colors[0]!), `${label}: opaque (${colors[0]})`);
    assert.strictEqual(
      colors[0],
      sheetColor('plain'),
      `${label}: --euiSheet-plain`
    );
  }

  test('AR1 with row numbers: one plus, in the row-number cell; the first field has the text only', async function (assert) {
    await renderSheet(2);
    assert.dom('.euiSheet__addRow .euiIcon').exists({ count: 1 }, 'one plus');
    assert.dom('.euiIcon', rowCell(2)).exists('in the row-number cell');
    const label = el('[data-test-subj=euiSheetAddRecord]', cell(2, 0));
    assert.strictEqual(label.textContent?.trim(), 'Add record');
    assert.dom('.euiIcon', label).doesNotExist('no icon by the text');
  });

  test('AR2 the plus is centred in the row-number cell, both ways', async function (assert) {
    await renderSheet(2);
    const box = rowCell(2).getBoundingClientRect();
    const plus = el('.euiSheet__rowAdd', rowCell(2)).getBoundingClientRect();
    const dx = plus.left + plus.width / 2 - (box.left + box.width / 2);
    const dy = plus.top + plus.height / 2 - (box.top + box.height / 2);
    assert.true(Math.abs(dx) <= 1, `horizontally (${dx.toFixed(1)} px)`);
    assert.true(Math.abs(dy) <= 1, `vertically (${dy.toFixed(1)} px)`);
  });

  test('AR3 every cell of the add row has the same opaque background, frozen or not', async function (assert) {
    const state = new State();
    await renderSheet(2, state);
    assertOneBackground(assert, 'nothing frozen');
    state.frozenFields = 1;
    await settled();
    assert.dom(rowCell(2)).hasClass('euiSheet__cell--frozen');
    assertOneBackground(assert, 'one frozen field');
  });

  test('AR4 AR3 in the dark theme', async function (assert) {
    const state = new State();
    await renderSheet(2, state);
    const light = sheetColor('plain');
    const emotion = this.owner.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService;
    emotion.colorMode = 'dark';
    await settled();
    assert.notStrictEqual(sheetColor('plain'), light, 'the dark theme is on');
    assertOneBackground(assert, 'dark');
    state.frozenFields = 1;
    await settled();
    assertOneBackground(assert, 'dark, one frozen field');
  });

  test('AR5 no inner dividers in the add row; the frame keeps its outer edges', async function (assert) {
    const state = new State();
    await renderSheet(2, state);
    const check = (label: string) => {
      const cells = addRowCells();
      cells.forEach((c, i) => {
        const style = getComputedStyle(c);
        if (i < cells.length - 1) {
          assert.true(
            isInvisible(
              style.borderRightWidth,
              style.borderRightStyle,
              style.borderRightColor
            ),
            `${label}: cell ${i} has no right divider (${style.borderRightWidth} ${style.borderRightStyle} ${style.borderRightColor})`
          );
        }
        if (i > 0) {
          assert.true(
            isInvisible(
              style.borderLeftWidth,
              style.borderLeftStyle,
              style.borderLeftColor
            ),
            `${label}: cell ${i} has no left divider`
          );
        }
      });
      const last = getComputedStyle(cells[cells.length - 1]!);
      assert.false(
        isInvisible(
          last.borderRightWidth,
          last.borderRightStyle,
          last.borderRightColor
        ),
        `${label}: the grid's right edge stays`
      );
    };
    check('nothing frozen');
    state.frozenFields = 1;
    await settled();
    check('one frozen field');
  });

  test('AR6 a focused cell of the add row shows only the sheet’s ring', async function (assert) {
    await renderSheet(2);
    const primary = sheetColor('primary');
    for (const [label, target] of [
      ['the row-number cell', () => rowCell(2)],
      ['a data cell', () => cell(2, 1)]
    ] as const) {
      await focus(target());
      const style = getComputedStyle(target());
      assert.strictEqual(
        style.outlineColor,
        primary,
        `${label}: outline colour`
      );
      assert.strictEqual(style.outlineWidth, '3px', `${label}: outline width`);
      assert.strictEqual(style.outlineOffset, '-3px', `${label}: inside`);
      assert.strictEqual(style.outlineStyle, 'solid', `${label}: solid`);
      assert.strictEqual(style.boxShadow, 'none', `${label}: no box-shadow`);
      assert.strictEqual(
        getComputedStyle(target(), '::after').content,
        'none',
        `${label}: no grid outline (::after)`
      );
    }
  });

  test('AR7 @rowNumbers={{false}}: the first field shows the only plus and the text', async function (assert) {
    const state = new State();
    state.rowNumbers = false;
    await renderSheet(2, state);
    assert.dom('.euiSheet__addRow .euiIcon').exists({ count: 1 }, 'one plus');
    const label = el('.euiSheet__addRow [data-test-subj=euiSheetAddRecord]');
    assert.dom('.euiIcon', label).exists('by the text');
    assert.strictEqual(label.textContent?.trim(), 'Add record');
  });

  test('AR8 a click on the text "Add record" inserts', async function (assert) {
    const store = await renderSheet(2);
    await click(el('[data-test-subj=euiSheetAddRecord]', cell(2, 0)));
    assert.strictEqual(store.log.length, 1);
    assert.strictEqual(store.log[0]!.source, 'insert');
    assert.strictEqual(store.records.length, 3);
  });
  /* Selection marks on headers and row numbers, checked rows (V03 batch 1) */

  const marked = (element: HTMLElement) =>
    getComputedStyle(element).backgroundImage.includes('linear-gradient');

  test('HM2 a cell range marks its columns’ headers and its rows’ numbers lightly; HM3 one cell marks only its own', async function (assert) {
    await renderSheet(4);
    await focusCell(0, 1);
    await press('ArrowRight', { shiftKey: true });
    await press('ArrowDown', { shiftKey: true });
    assert.deepEqual(
      [0, 1, 2].map((col) => marked(header(col))),
      [false, true, true],
      'the range’s headers'
    );
    assert.strictEqual(
      getComputedStyle(header(1)).boxShadow,
      'none',
      'light: no bar'
    );
    assert.deepEqual(
      [0, 1, 2, 3].map((row) =>
        rowCell(row).classList.contains('euiSheet__rowCell--marked')
      ),
      [true, true, false, false],
      'the range’s row numbers'
    );
    assert.strictEqual(
      getComputedStyle(rowCell(0)).color,
      getComputedStyle(el('.euiDataGridHeaderCell__content', header(1))).color,
      'both in primary'
    );
    // HM3: collapsed to the active cell
    await press('Escape');
    assert.deepEqual(
      [0, 1, 2].map((col) => marked(header(col))),
      [false, true, false],
      'only the active cell’s header'
    );
    assert.deepEqual(
      [0, 1, 2, 3].map((row) =>
        rowCell(row).classList.contains('euiSheet__rowCell--marked')
      ),
      [true, false, false, false],
      'only its row number'
    );
  });

  test('HM4 selected rows: the tint and a 3 px bar on the row number’s inner edge', async function (assert) {
    await renderSheet(4);
    await click(rowCell(1));
    assert.dom(rowCell(1)).hasClass('euiSheet__rowCell--selected');
    assert.true(
      getComputedStyle(rowCell(1)).boxShadow.includes('-3px 0px 0px'),
      `the bar (${getComputedStyle(rowCell(1)).boxShadow})`
    );
    assert.strictEqual(getComputedStyle(rowCell(2)).boxShadow, 'none');
    assert.false(marked(header(0)), 'a row selection marks no header');
  });

  test('CK1 checking a row tints its cells and its row number; unchecking removes it; a range wins', async function (assert) {
    await renderSheet(3);
    await click(el('[data-eui-sheet-row-check]', rowCell(1)));
    assert.dom(rowCell(1)).hasClass('euiSheet__rowCell--checked');
    assert.dom(cell(1, 1)).hasClass('euiSheet__cell--checked');
    const tinted = getComputedStyle(cell(1, 1)).backgroundColor;
    assert.notStrictEqual(tinted, 'rgba(0, 0, 0, 0)', `tinted (${tinted})`);
    assert.strictEqual(
      getComputedStyle(cell(0, 1)).backgroundColor,
      'rgba(0, 0, 0, 0)',
      'not the other rows'
    );
    assert.strictEqual(
      getComputedStyle(rowCell(1)).backgroundColor,
      sheetColor('selected'),
      'the row number in the selection tint'
    );
    // a range over the checked row shows the range look
    await focusCell(1, 0);
    await press('ArrowRight', { shiftKey: true });
    assert.strictEqual(
      getComputedStyle(cell(1, 1)).backgroundColor,
      sheetColor('selected'),
      'the range wins'
    );
    assert.dom('.euiSheet__addRow .euiSheet__cell--checked').doesNotExist();
    await click(el('[data-eui-sheet-row-check]', rowCell(1)));
    assert.dom(cell(1, 1)).doesNotHaveClass('euiSheet__cell--checked');
  });
  test('VP1 the row menu: lines between its groups; the right-clicked cell is marked', async function (assert) {
    await renderSheet(4);
    await rightClick(cell(2, 1));
    const panel = menu()!;
    const order = Array.from(
      panel.querySelectorAll<HTMLElement>(
        '.euiSheet__menuSeparator, [data-test-subj^=euiSheetRowMenu-]'
      )
    ).map((element) =>
      element.matches('hr')
        ? '|'
        : element.dataset['testSubj']!.replace('euiSheetRowMenu-', '')
    );
    assert.deepEqual(order, [
      'insertAbove',
      'insertBelow',
      '|',
      'duplicate',
      'expand',
      '|',
      'copy',
      '|',
      'delete'
    ]);
    assert.deepEqual(
      selected(),
      ['2:1'],
      'the cell is selected (the range look)'
    );
    await press('ArrowDown');
    assert.strictEqual(
      document.activeElement,
      el('[data-test-subj=euiSheetRowMenu-insertBelow]'),
      'the arrows skip the lines'
    );
  });

  test('EM1 no records: a message (and the add action); loading or one record: none', async function (assert) {
    const state = new State();
    const store = await renderSheet(0, state);
    assert.dom('[data-test-subj=euiSheetEmpty]').includesText('No records');
    assert.dom('.euiSheet__addRow').exists('the add row is the action');
    await click(el('[data-test-subj=euiSheetAddRecord]'));
    assert.strictEqual(store.log[0]?.source, 'insert', 'the action inserts');
    assert
      .dom('[data-test-subj=euiSheetEmpty]')
      .doesNotExist('one record: no message');

    const readOnly = new State();
    readOnly.canInsert = false;
    await renderSheet(0, readOnly);
    assert.dom('[data-test-subj=euiSheetEmpty]').includesText('No records');
    assert.dom('.euiSheet__addRow').doesNotExist('no add row');
  });
});
