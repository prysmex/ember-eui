/**
 * Group by in the component, stage 3.2b (V03-DESIGN.md 8.3-8.5, 8.10):
 * inserts near a record and duplicates with the group's values, checked
 * rows, the row menu, the expanded record and history across groups, the
 * header menu's group items, the blocks' group members, the keys of a
 * row-number cell, and `localRecords` end to end.
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
  selected
} from '../../helpers/sheet.ts';

import type {
  ChangeSet,
  EuiSheetField,
  RecordId,
  SheetGroup,
  SheetGroupBy
} from '#src/core/index.ts';
import type { SheetApi, SheetBlockApi } from '#src/types.ts';

type Row = {
  id: string;
  name: string;
  status: string | null;
  owner: string;
  qty: number;
};

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name', width: 120 },
  { id: 'status', label: 'Status', width: 120 },
  { id: 'owner', label: 'Owner', width: 120 },
  { id: 'qty', label: 'Qty', type: 'number', width: 120 }
];

const getId = (row: Row) => row.id;

/** Six records, two per status, in display order. */
function rows(): Row[] {
  return [
    ['r0', 'Open', 'Ana', 1],
    ['r1', 'Open', 'Bo', 2],
    ['r2', 'Doing', 'Ana', 3],
    ['r3', 'Doing', 'Ana', 4],
    ['r4', 'Done', 'Bo', 5],
    ['r5', 'Done', 'Bo', 6]
  ].map(([id, status, owner, qty]) => ({
    id: id as string,
    name: `Name ${id as string}`,
    status: status as string,
    owner: owner as string,
    qty: qty as number
  }));
}

const BY_STATUS: SheetGroupBy[] = [{ field: 'status', direction: 'asc' }];

const group = (
  key: string,
  value: unknown,
  extra: Partial<SheetGroup> = {}
): SheetGroup => ({ key, depth: 0, value, count: 2, loaded: 2, ...extra });

/*
 * Grid rows of `State` (3 groups of 2, add rows on):
 * 0 Open header, 1 r0, 2 r1, 3 add, 4 Doing header, 5 r2, 6 r3, 7 add,
 * 8 Done header, 9 r4, 10 r5, 11 add.
 */
class State {
  @tracked records: Row[] = rows();
  @tracked groups: SheetGroup[] = [
    group('status:Open', 'Open'),
    group('status:Doing', 'Doing'),
    group('status:Done', 'Done')
  ];
  @tracked groupBy: SheetGroupBy[] = BY_STATUS;
  @tracked checked: RecordId[] = [];
  changes: ChangeSet[] = [];
  toggles: [string, boolean][] = [];
  groupByCalls: SheetGroupBy[][] = [];
  block: SheetBlockApi<Row> | null = null;
  api: SheetApi | null = null;
  onChange = (changeSet: ChangeSet) => this.changes.push(changeSet);
  onGroupToggle = (key: string, collapsed: boolean) =>
    this.toggles.push([key, collapsed]);
  onGroupByChange = (groupBy: SheetGroupBy[]) =>
    this.groupByCalls.push(groupBy);
  onCheckedChange = (ids: RecordId[]) => (this.checked = ids);
}

/** The last item of a list (the tests' lib has no `Array.prototype.at`). */
function last<T>(list: readonly T[]): T | undefined {
  return list[list.length - 1];
}

/** Waits a frame: layers and the grid's measuring settle after it. */
async function frames(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

function gridRow(row: number): HTMLElement {
  return el(`.euiDataGridRow[data-grid-row-index="${row}"]`);
}

/** The row-number cell of a grid row (grid column 0). */
function rowNumberCell(row: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"]`
  );
}

/** The header row's first cell, the one that shows the label (V03 9.1). */
function labelCell(row: number): HTMLElement {
  return el(':scope > [role=gridcell]', gridRow(row));
}

function menu(): HTMLElement | null {
  return document.querySelector<HTMLElement>(
    '[data-test-subj=euiSheetRowMenu]'
  );
}

async function pick(id: string): Promise<void> {
  await click(el(`[data-test-subj=euiSheetRowMenu-${id}]`, document.body));
}

/** A right-click on an element: the press, then the contextmenu event. */
async function rightClick(element: HTMLElement): Promise<boolean> {
  const box = element.getBoundingClientRect();
  const point = { clientX: box.left + 5, clientY: box.top + 5 };
  await triggerEvent(element, 'mousedown', { button: 2, ...point });
  const event = new MouseEvent('contextmenu', {
    bubbles: true,
    cancelable: true,
    button: 2,
    ...point
  });
  element.dispatchEvent(event);
  await settled();
  return event.defaultPrevented;
}

/** The grid row and column of the focused cell (grid column index). */
function active(): { row: number; col: number } {
  const cellElement = (
    document.activeElement as HTMLElement | null
  )?.closest<HTMLElement>('[role=gridcell]');
  return cellElement
    ? {
        row: Number(cellElement.dataset['gridcellVisibleRowIndex']),
        col: Number(cellElement.dataset['gridcellColumnIndex'])
      }
    : { row: -1, col: -1 };
}

/** The text of the focused cell. */
function activeText(): string {
  return (
    (document.activeElement as HTMLElement | null)
      ?.closest('[role=gridcell]')
      ?.querySelector('[data-datagrid-cellcontent]')
      ?.textContent?.trim() ?? ''
  );
}

/** The grid row whose first field shows `name`. */
function rowOfName(name: string): number {
  const found = [
    ...document.querySelectorAll<HTMLElement>(
      '[role=gridcell][data-gridcell-column-index="1"]'
    )
  ].find(
    (element) =>
      element
        .querySelector('[data-datagrid-cellcontent]')
        ?.textContent?.trim() === name
  );
  return found ? Number(found.dataset['gridcellVisibleRowIndex']) : -1;
}

/** The titles of the rendered header rows, in grid order. */
function headerTitles(): string[] {
  return [...document.querySelectorAll<HTMLElement>('.euiSheet__groupRow')]
    .sort(
      (a, b) =>
        Number(a.dataset['gridRowIndex']) - Number(b.dataset['gridRowIndex'])
    )
    .map(
      (row) =>
        row
          .querySelector('[data-test-subj=euiSheetGroupTitle]')
          ?.textContent?.trim() ?? ''
    );
}

/** The grid rows by kind, in order, short: `g` a header, `r` a record, `a` an add row. */
function kinds(): string {
  return [...document.querySelectorAll<HTMLElement>('.euiDataGridRow')]
    .sort(
      (a, b) =>
        Number(a.dataset['gridRowIndex']) - Number(b.dataset['gridRowIndex'])
    )
    .map((row) =>
      row.classList.contains('euiSheet__groupRow')
        ? 'g'
        : row.classList.contains('euiSheet__addRow')
          ? 'a'
          : 'r'
    )
    .join('');
}

async function openHeaderMenu(fieldId: string): Promise<void> {
  await click(el(`[data-test-subj=dataGridHeaderCellActionButton-${fieldId}]`));
  await waitUntil(() =>
    document.querySelector(
      `[data-test-subj=dataGridHeaderCellActionGroup-${fieldId}]`
    )
  );
}

async function closeHeaderMenu(): Promise<void> {
  await triggerEvent(document.activeElement ?? document.body, 'keydown', {
    key: 'Escape'
  });
  await frames();
}

function headerMenuHas(fieldId: string, item: string): boolean {
  return !!document.querySelector(
    `[data-test-subj=euiSheet${item}-${fieldId}]`
  );
}

module('Integration | Component | EuiSheet groups, intents', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(
    state: State,
    options: {
      newRecordValues?: () => Record<string, unknown>;
      groupBy?: boolean;
      checked?: boolean;
      fields?: EuiSheetField<Row>[];
      height?: number;
    } = {}
  ): Promise<void> {
    const onGroupByChange =
      options.groupBy === false ? undefined : state.onGroupByChange;
    const checked = options.checked ? state : undefined;
    const fields = options.fields ?? FIELDS;
    const keep = (block: SheetBlockApi<Row>) => {
      state.block = block;
      return '';
    };
    const register = (api: SheetApi) => (state.api = api);
    await render(
      <template>
        <EuiSheet
          @fields={{fields}}
          @records={{state.records}}
          @groups={{state.groups}}
          @groupBy={{state.groupBy}}
          @onGroupToggle={{state.onGroupToggle}}
          @onGroupByChange={{onGroupByChange}}
          @getRecordId={{getId}}
          @onChange={{state.onChange}}
          @newRecordValues={{options.newRecordValues}}
          @checkedRecordIds={{checked.checked}}
          @onCheckedChange={{checked.onCheckedChange}}
          @registerApi={{register}}
          @height={{if options.height options.height 600}}
        >
          <:toolbar as |sheet|><span>{{keep sheet}}</span></:toolbar>
        </EuiSheet>
      </template>
    );
  }

  /* Inserts (V03 8.4) */

  test('GR14a Shift+Enter and the menu insert into the record group, with its values and groupKey', async function (assert) {
    const state = new State();
    await renderSheet(state, {
      newRecordValues: () => ({ owner: 'New', status: 'Open' })
    });
    // Shift+Enter on r2 (Doing, row 5): below it, in Doing
    await focusCell(5, 2);
    await press('Enter', { shiftKey: true });
    let insert = last(state.changes)!.inserts[0]!;
    assert.deepEqual(
      insert.values,
      { owner: 'New', status: 'Doing' },
      'the group value wins over @newRecordValues'
    );
    assert.strictEqual(insert.groupKey, 'status:Doing');
    assert.deepEqual(insert.anchor, { recordId: 'r2', position: 'after' });
    assert.strictEqual(insert.index, 3, 'record row after r2');

    // the menu on r4 (Done, row 9): insert above and below
    assert.true(await rightClick(cell(9, 1)), 'the menu takes the event');
    assert.ok(menu(), 'the menu opens on a record (control)');
    await pick('insertBelow');
    insert = last(state.changes)!.inserts[0]!;
    assert.strictEqual(insert.values['status'], 'Done', 'insert below');
    assert.strictEqual(insert.groupKey, 'status:Done');
    assert.deepEqual(insert.anchor, { recordId: 'r4', position: 'after' });
    await rightClick(cell(9, 1));
    await pick('insertAbove');
    insert = last(state.changes)!.inserts[0]!;
    assert.strictEqual(insert.values['status'], 'Done', 'insert above');
    assert.strictEqual(insert.groupKey, 'status:Done');
    assert.deepEqual(insert.anchor, { recordId: 'r4', position: 'before' });
    assert.strictEqual(insert.index, 4);
  });

  test('GR14b duplicate: each copy goes into its record group', async function (assert) {
    const state = new State();
    state.groups = [
      group('status:Open', 'Open'),
      group('status:Doing', 'Doing'),
      group('status:Done', 'Done')
    ];
    await renderSheet(state, { checked: true });
    // one record from the menu
    await rightClick(cell(5, 0));
    await pick('duplicate');
    let inserts = last(state.changes)!.inserts;
    assert.strictEqual(inserts.length, 1);
    assert.strictEqual(inserts[0]!.values['name'], 'Name r2', 'a copy');
    assert.strictEqual(inserts[0]!.values['status'], 'Doing');
    assert.strictEqual(inserts[0]!.groupKey, 'status:Doing');
    // two checked records in two groups
    state.checked = ['r1', 'r4'];
    await settled();
    await rightClick(rowNumberCell(2));
    await pick('duplicate');
    inserts = last(state.changes)!.inserts;
    assert.deepEqual(
      inserts.map((insert) => [
        insert.values['name'],
        insert.values['status'],
        insert.groupKey,
        insert.anchor?.recordId
      ]),
      [
        ['Name r1', 'Open', 'status:Open', 'r1'],
        ['Name r4', 'Done', 'status:Done', 'r4']
      ]
    );
  });

  test('GR14c without @groups: insert and duplicate carry no groupKey', async function (assert) {
    const state = new State();
    state.groups = [];
    await renderSheet(state);
    await focusCell(2, 0);
    await press('Enter', { shiftKey: true });
    const insert = last(state.changes)!.inserts[0]!;
    assert.false('groupKey' in insert);
    assert.deepEqual(insert.values, {});
    await rightClick(cell(2, 0));
    await pick('duplicate');
    assert.false('groupKey' in last(state.changes)!.inserts[0]!);
  });

  /* Checked rows (GR13) */

  test('GR13 Shift+click across a header checks the records between; select-all checks the loaded records', async function (assert) {
    const state = new State();
    await renderSheet(state, { checked: true });
    const check = (row: number) =>
      el('[data-test-subj=euiSheetRowCheck]', rowNumberCell(row));
    assert
      .dom('[data-test-subj=euiSheetRowCheck]', rowNumberCell(0))
      .doesNotExist('no checkbox on a header');
    await click(check(2));
    assert.deepEqual(state.checked, ['r1']);
    await click(check(9), { shiftKey: true });
    assert.deepEqual(
      [...state.checked].sort(),
      ['r1', 'r2', 'r3', 'r4'],
      'from Open over two headers to Done'
    );
    await click(check(5), { shiftKey: true });
    assert.deepEqual(
      [...state.checked].sort(),
      ['r1'],
      'Shift+click from Done back to r2 unchecks r2 to r4'
    );

    // Doing collapsed: its records are not in @records
    state.checked = [];
    state.records = rows().filter((row) => row.status !== 'Doing');
    state.groups = [
      group('status:Open', 'Open'),
      group('status:Doing', 'Doing', { collapsed: true, loaded: 0 }),
      group('status:Done', 'Done')
    ];
    await settled();
    await click(el('[data-test-subj=euiSheetRowCheckAll]'));
    assert.deepEqual(
      [...state.checked].sort(),
      ['r0', 'r1', 'r4', 'r5'],
      'select-all: the loaded records'
    );
  });

  /* The row menu (GR14) */

  test('GR14d delete from the menu focuses the neighbour record, also across a header', async function (assert) {
    const store = localRecords(rows(), {
      getRecordId: getId,
      fields: FIELDS,
      groupBy: BY_STATUS
    });
    await render(
      <template>
        <EuiSheet
          @fields={{FIELDS}}
          @records={{store.view.records}}
          @groups={{store.view.groups}}
          @groupBy={{store.groupBy}}
          @onGroupToggle={{store.toggleGroup}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
          @height={{600}}
        />
      </template>
    );
    // by text: Doing (r2, r3), Done (r4, r5), Open (r0, r1)
    assert.deepEqual(headerTitles(), ['Doing', 'Done', 'Open']);
    const r4 = rowOfName('Name r4');
    await rightClick(cell(r4, 0));
    assert.ok(menu(), 'the menu opens on a record of the second group');
    await pick('delete');
    await frames();
    assert.strictEqual(activeText(), 'Name r5', 'focus on the next record');
    assert.strictEqual(active().row, r4, 'in its row now');

    // the group's last record: the next is the next group's first
    await rightClick(cell(r4, 0));
    await pick('delete');
    await frames();
    assert.strictEqual(activeText(), 'Name r0', 'over the header, r0');
    assert.deepEqual(headerTitles(), ['Doing', 'Open'], 'Done is gone');
  });

  test('GR14e no menu on a header row: right-click, Shift+F10 and the ContextMenu key', async function (assert) {
    const state = new State();
    await renderSheet(state);
    // control: a record row opens it
    assert.true(await rightClick(cell(5, 1)), 'a record: taken');
    assert.ok(menu(), 'a record: open');
    await triggerEvent(document.body, 'mousedown');
    await frames();
    assert.notOk(menu(), 'closed');

    // the header's label cell and one of its field cells
    assert.false(await rightClick(labelCell(4)), 'label cell: not taken');
    assert.notOk(menu(), 'label cell: no menu');
    assert.false(await rightClick(cell(4, 2)), 'field cell: not taken');
    assert.notOk(menu(), 'field cell: no menu');

    await focus(rowNumberCell(4));
    await pressed('F10', { shiftKey: true });
    assert.notOk(menu(), 'Shift+F10 on its row number: no menu');
    await pressed('ContextMenu');
    assert.notOk(menu(), 'ContextMenu on its row number: no menu');
    await focus(cell(4, 2));
    await pressed('F10', { shiftKey: true });
    assert.notOk(menu(), 'Shift+F10 on a field cell: no menu');
    await pressed('ContextMenu');
    assert.notOk(menu(), 'ContextMenu on a field cell: no menu');

    // control: the same keys on a record
    await focusCell(5, 2);
    await pressed('F10', { shiftKey: true });
    assert.ok(menu(), 'Shift+F10 on a record: open');
  });

  /* The expanded record (GR15) */

  test('GR15 expanded record: next from a group last record opens the next group first', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const shell = () =>
      document.querySelector<HTMLElement>('[data-test-subj=euiSheetRecord]');
    const title = () =>
      shell()
        ?.querySelector('[data-test-subj=euiSheetRecordTitle]')
        ?.textContent?.trim() ?? '';
    await focusCell(2, 0);
    await pressed(' ');
    await waitUntil(() => shell());
    assert.strictEqual(title(), 'Name r1', 'Open group last record');
    const next = el('[data-test-subj=euiSheetRecordNext]', document.body);
    const previous = el(
      '[data-test-subj=euiSheetRecordPrevious]',
      document.body
    );
    await click(next);
    assert.strictEqual(title(), 'Name r2', 'Doing group first record');
    await click(previous);
    assert.strictEqual(title(), 'Name r1', 'and back');
  });

  /* History (GR16) */

  test('GR16 undo of an edit in a group collapsed since: the change set is emitted, no error', async function (assert) {
    const store = localRecords(rows(), {
      getRecordId: getId,
      fields: FIELDS,
      groupBy: BY_STATUS
    });
    const held: { api: SheetApi | null } = { api: null };
    const register = (sheetApi: SheetApi) => (held.api = sheetApi);
    await render(
      <template>
        <EuiSheet
          @fields={{FIELDS}}
          @records={{store.view.records}}
          @groups={{store.view.groups}}
          @groupBy={{store.groupBy}}
          @onGroupToggle={{store.toggleGroup}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
          @registerApi={{register}}
          @height={{600}}
        />
      </template>
    );
    const owner = (id: string) =>
      store.records.find((row) => row.id === id)!.owner;
    // Doing (r2, r3) first: clear r2's owner
    const r2 = rowOfName('Name r2');
    await focusCell(r2, 2);
    await press('Delete');
    assert.notOk(owner('r2'), 'cleared');
    // collapse Doing
    await click(el('[data-test-subj=euiSheetGroupToggle]', labelCell(0)));
    await frames();
    assert.strictEqual(rowOfName('Name r2'), -1, 'r2 is not in @records');

    const before = store.log.length;
    held.api!.undo();
    await settled();
    assert.strictEqual(store.log.length, before + 1, 'emitted');
    const undo = last(store.log)!;
    assert.strictEqual(undo.source, 'undo');
    assert.deepEqual(
      undo.patches.map((patch) => [patch.recordId, patch.fieldId, patch.to]),
      [['r2', 'owner', 'Ana']]
    );
    assert.strictEqual(owner('r2'), 'Ana', 'the owner applied it');
    assert.deepEqual(selected(), [], 'nothing is selected');

    held.api!.redo();
    await settled();
    assert.strictEqual(last(store.log)!.source, 'redo', 'redo emitted too');
    assert.notOk(owner('r2'));

    // expanded again: the cell shows it
    await click(el('[data-test-subj=euiSheetGroupToggle]', labelCell(0)));
    await frames();
    held.api!.undo();
    await settled();
    assert.strictEqual(owner('r2'), 'Ana');
    const row = rowOfName('Name r2');
    assert.strictEqual(
      cell(row, 2)
        .querySelector('[data-datagrid-cellcontent]')
        ?.textContent?.trim(),
      'Ana'
    );
  });

  /* The header menu (GR18, V03 8.3) */

  test('GR18 header menu: Group by this field, Remove grouping; none without the handler or with groupable: false', async function (assert) {
    const state = new State();
    const fields: EuiSheetField<Row>[] = [
      ...FIELDS.slice(0, 3),
      { ...FIELDS[3]!, groupable: false }
    ];
    await renderSheet(state, { fields });
    await openHeaderMenu('owner');
    assert.true(headerMenuHas('owner', 'GroupByField'), 'on another field');
    assert.false(headerMenuHas('owner', 'RemoveGrouping'));
    assert
      .dom('[data-test-subj=euiSheetGroupByField-owner]', document.body)
      .hasText('Group by this field');
    await click(el('[data-test-subj=euiSheetGroupByField-owner]'));
    await frames();
    assert.deepEqual(state.groupByCalls, [
      [{ field: 'owner', direction: 'asc' }]
    ]);

    await openHeaderMenu('status');
    assert.true(headerMenuHas('status', 'RemoveGrouping'), 'grouped field');
    assert.false(headerMenuHas('status', 'GroupByField'));
    await click(el('[data-test-subj=euiSheetRemoveGrouping-status]'));
    await frames();
    assert.deepEqual(last(state.groupByCalls), [], 'Remove grouping: []');

    await openHeaderMenu('qty');
    assert.false(headerMenuHas('qty', 'GroupByField'), 'groupable: false');
    assert.false(headerMenuHas('qty', 'RemoveGrouping'));
    assert.true(
      !!document.querySelector(
        '[data-test-subj=dataGridHeaderCellActionGroup-qty]'
      ),
      'its menu is open (control)'
    );
    await closeHeaderMenu();
  });

  test('GR18 without @onGroupByChange: no group items', async function (assert) {
    const state = new State();
    await renderSheet(state, { groupBy: false });
    await openHeaderMenu('owner');
    assert.false(headerMenuHas('owner', 'GroupByField'));
    await closeHeaderMenu();
    await openHeaderMenu('status');
    assert.false(headerMenuHas('status', 'RemoveGrouping'));
  });

  /* The blocks (V03 4.5) */

  test('GR24 the blocks: groupBy, groups, setGroupBy and toggleGroup', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const block = state.block!;
    assert.deepEqual(block.groupBy, BY_STATUS);
    assert.deepEqual(
      block.groups.map((entry) => entry.key),
      ['status:Open', 'status:Doing', 'status:Done']
    );
    block.setGroupBy([{ field: 'owner', direction: 'desc' }]);
    assert.deepEqual(state.groupByCalls, [
      [{ field: 'owner', direction: 'desc' }]
    ]);
    block.toggleGroup('status:Doing');
    assert.deepEqual(state.toggles, [['status:Doing', true]]);
    block.toggleGroup('status:Nope');
    assert.strictEqual(state.toggles.length, 1, 'an unknown key: nothing');

    // new groups: a new block object with them
    state.groups = [
      group('status:Open', 'Open', { collapsed: true, loaded: 0 })
    ];
    state.records = [];
    await settled();
    assert.deepEqual(
      state.block!.groups.map((entry) => entry.key),
      ['status:Open']
    );
    state.block!.toggleGroup('status:Open');
    assert.deepEqual(last(state.toggles), ['status:Open', false], 'expand');
  });

  test('GR24 the blocks without groups or handlers', async function (assert) {
    const state = new State();
    state.groups = [];
    state.groupBy = [];
    await render(
      <template>
        <EuiSheet
          @fields={{FIELDS}}
          @records={{state.records}}
          @getRecordId={{getId}}
          @onChange={{state.onChange}}
        >
          <:toolbar as |sheet|>{{keepBlock state sheet}}</:toolbar>
        </EuiSheet>
      </template>
    );
    const block = state.block!;
    assert.deepEqual(block.groupBy, []);
    assert.deepEqual(block.groups, []);
    block.setGroupBy(BY_STATUS);
    block.toggleGroup('status:Open');
    assert.deepEqual(state.groupByCalls, [], 'nothing without the handler');
    assert.deepEqual(state.toggles, []);
  });

  /* Keys of a row-number cell (3.2a's open item) */

  test('GR11 row-number cells: PageUp, PageDown and Ctrl+Home/End never land on a header', async function (assert) {
    const state = new State();
    // Done collapsed and last: the grid's own Ctrl+End and PageDown would
    // reach its header
    state.records = rows().filter((row) => row.status !== 'Done');
    state.groups = [
      group('status:Open', 'Open'),
      group('status:Doing', 'Doing'),
      group('status:Done', 'Done', { collapsed: true, loaded: 0 })
    ];
    await renderSheet(state);
    // 0 g, 1 r0, 2 r1, 3 a, 4 g, 5 r2, 6 r3, 7 a, 8 g (collapsed)
    await focus(rowNumberCell(1));
    assert.true(await pressed('PageDown'), 'PageDown taken');
    assert.deepEqual(active(), { row: 7, col: 0 }, 'not the last header');
    assert.true(await pressed('PageUp'), 'PageUp taken');
    assert.deepEqual(active(), { row: 1, col: 0 }, 'not the first header');
    await focus(rowNumberCell(6));
    assert.true(await pressed('Home', { ctrlKey: true }), 'Ctrl+Home taken');
    assert.deepEqual(active(), { row: 1, col: 0 }, 'the first record');
    assert.true(await pressed('End', { ctrlKey: true }), 'Ctrl+End taken');
    assert.deepEqual(
      active(),
      { row: 7, col: FIELDS.length },
      'the last row that is not a header, last field'
    );

    // Shift+PageDown: whole rows onto the last record
    await focus(rowNumberCell(1));
    assert.true(await pressed('PageDown', { shiftKey: true }));
    assert.deepEqual(active(), { row: 6, col: 0 }, 'a record');
    assert.deepEqual(
      selected().filter((pos) => pos.endsWith(':0')),
      ['1:0', '2:0', '5:0', '6:0'],
      'the records from r0 to r3'
    );
  });

  test('GR11 row-number cells without groups: the page keys are not taken', async function (assert) {
    const state = new State();
    state.groups = [];
    await renderSheet(state);
    await focus(rowNumberCell(1));
    assert.false(await pressed('PageDown'), 'the grid and the browser');
  });

  test('GR6 a Shift+click on a header row focuses it and drops the range (8.6)', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await focusCell(1, 1);
    await click(cell(2, 2), { shiftKey: true });
    assert.deepEqual(selected(), ['1:1', '1:2', '2:1', '2:2'], 'a range');
    await click(labelCell(4), { shiftKey: true });
    assert.strictEqual(active().row, 4, 'the header has focus');
    assert.deepEqual(selected(), [], 'no range');
    await clipboard('paste', 'x');
    assert.strictEqual(state.changes.length, 0, 'a paste writes nothing');
  });

  /* localRecords end to end (GR22) */

  test('GR22 localRecords: group by a select field, collapse, add in a group, edit the group field, ungroup', async function (assert) {
    type Task = { id: string; name: string; status: string | null };
    const fields: EuiSheetField<Task>[] = [
      { id: 'name', label: 'Name', width: 140 },
      {
        id: 'status',
        label: 'Status',
        type: 'singleSelect',
        width: 140,
        options: [
          { value: 'todo', label: 'To do' },
          { value: 'doing', label: 'Doing' },
          { value: 'done', label: 'Done' }
        ]
      }
    ];
    const store = localRecords<Task>(
      [
        { id: 't1', name: 'A', status: 'todo' },
        { id: 't2', name: 'B', status: 'doing' },
        { id: 't3', name: 'C', status: 'todo' },
        { id: 't4', name: 'D', status: 'done' }
      ],
      { getRecordId: (task) => task.id, fields }
    );
    const getTaskId = (task: Task) => task.id;
    await render(
      <template>
        <EuiSheet
          @fields={{store.fields}}
          @records={{store.view.records}}
          @groups={{store.view.groups}}
          @groupBy={{store.groupBy}}
          @onGroupByChange={{store.setGroupBy}}
          @onGroupToggle={{store.toggleGroup}}
          @getRecordId={{getTaskId}}
          @onChange={{store.apply}}
          @height={{600}}
        />
      </template>
    );
    assert.strictEqual(kinds(), 'rrrra', 'not grouped');

    // group by Status from its header menu
    await openHeaderMenu('status');
    await click(el('[data-test-subj=euiSheetGroupByField-status]'));
    await frames();
    assert.deepEqual(store.groupBy, [{ field: 'status', direction: 'asc' }]);
    assert.deepEqual(headerTitles(), ['To do', 'Doing', 'Done']);
    assert.strictEqual(kinds(), 'grragragra');

    // collapse To do
    await click(el('[data-test-subj=euiSheetGroupToggle]', labelCell(0)));
    await frames();
    assert.strictEqual(kinds(), 'ggragra', 'To do collapsed');
    assert.strictEqual(rowOfName('A'), -1);

    // add a record in Doing from its add row (row 3)
    await click(cell(3, 0));
    await frames();
    const added = store.records.find(
      (task) => !['t1', 't2', 't3', 't4'].includes(task.id)
    )!;
    assert.strictEqual(store.records.length, 5);
    assert.strictEqual(added.status, 'doing', 'the group value');
    const doing = store.view.groups.find((entry) => entry.value === 'doing')!;
    assert.strictEqual(last(store.log)!.inserts[0]!.groupKey, doing.key);
    assert.strictEqual(kinds(), 'ggrragra', 'it is in Doing');

    // edit B's group field: it moves to Done on the next view
    const b = rowOfName('B');
    await focusCell(b, 1);
    await clipboard('paste', 'Done');
    await frames();
    assert.strictEqual(
      store.records.find((task) => task.id === 't2')!.status,
      'done'
    );
    assert.strictEqual(kinds(), 'ggragrra', 'Doing 1, Done 2');
    const doneHeader = [
      ...document.querySelectorAll<HTMLElement>('.euiSheet__groupRow')
    ].find(
      (row) =>
        row
          .querySelector('[data-test-subj=euiSheetGroupTitle]')
          ?.textContent?.trim() === 'Done'
    )!;
    const doneRow = Number(doneHeader.dataset['gridRowIndex']);
    assert.true(rowOfName('B') > doneRow, 'B is under Done now');

    // ungroup from the grouped field's header menu
    await openHeaderMenu('status');
    await click(el('[data-test-subj=euiSheetRemoveGrouping-status]'));
    await frames();
    assert.deepEqual(store.groupBy, []);
    assert.strictEqual(kinds(), 'rrrrra', 'every record, one add row');
  });
});

/** A helper that keeps the block's API on the state (GR24). */
function keepBlock(state: State, block: SheetBlockApi<Row>): string {
  state.block = block;
  return '';
}
