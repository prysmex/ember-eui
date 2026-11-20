/**
 * Group by in the component (V03-DESIGN.md 8.4, 8.10), stage 3.1: header
 * rows with their label, count, toggle and summaries, the groups' add
 * rows, row numbers, and the sheet following a changing `@groups`. The
 * behaviour inside groups (keys, clipboard, fill, menus) is stage 3.2's.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { registerWarnHandler } from '@ember/debug';
import { click, focus, render, settled } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  el,
  focusCell,
  press,
  selected,
  text
} from '../../helpers/sheet.ts';

import type {
  ChangeSet,
  EuiSheetField,
  SheetGroup,
  SheetGroupBy
} from '#src/core/index.ts';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';

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

/** Waits a frame: layers and the grid's measuring settle after it. */
async function frames(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

/** Warnings by id, while a test collects them (GR21). */
let warnings: string[] | null = null;
registerWarnHandler((message, options, next) => {
  if (warnings && options?.id) warnings.push(options.id);
  next(message, options);
});

class State {
  @tracked records: Row[] = rows();
  @tracked groups: SheetGroup[] | undefined = [
    group('status:Open', 'Open'),
    group('status:Doing', 'Doing'),
    group('status:Done', 'Done')
  ];
  @tracked groupBy: SheetGroupBy[] | undefined = BY_STATUS;
  changes: ChangeSet[] = [];
  toggles: [string, boolean][] = [];
  onChange = (changeSet: ChangeSet) => this.changes.push(changeSet);
  onGroupToggle = (key: string, collapsed: boolean) =>
    this.toggles.push([key, collapsed]);
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

function gridRow(row: number): HTMLElement {
  return el(`.euiDataGridRow[data-grid-row-index="${row}"]`);
}

/** The header row's first cell, the one that shows the label (V03 9.1). */
function labelCell(row: number): HTMLElement {
  return el(':scope > [role=gridcell]', gridRow(row));
}

function shown(element: Element | null | undefined): boolean {
  return !!element && getComputedStyle(element).display !== 'none';
}

/** The displayed text of a part of a header's label. */
function labelPart(row: number, part: string): string {
  return (
    labelCell(row)
      .querySelector(`[data-test-subj=euiSheetGroup${part}]`)
      ?.textContent?.trim() ?? ''
  );
}

function rowLabel(row: number): string {
  return (
    gridRow(row)
      .querySelector('[data-test-subj=euiSheetRowLabel]')
      ?.textContent?.trim() ?? ''
  );
}

function activeRow(): number {
  const active = (document.activeElement as HTMLElement).closest<HTMLElement>(
    '[role=gridcell]'
  );
  return active ? Number(active.dataset['gridcellVisibleRowIndex']) : -1;
}

module('Integration | Component | EuiSheet groups', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(
    state: State,
    options: {
      toggle?: boolean;
      summary?: Record<string, string>;
      newRecordValues?: () => Record<string, unknown>;
      rowLabel?: (record: Row, position: number) => string;
      rowNumberOffset?: number;
    } = {}
  ): Promise<void> {
    const toggle = options.toggle === false ? undefined : state.onGroupToggle;
    await render(
      <template>
        <EuiSheet
          @fields={{FIELDS}}
          @records={{state.records}}
          @groups={{state.groups}}
          @groupBy={{state.groupBy}}
          @onGroupToggle={{toggle}}
          @getRecordId={{getId}}
          @onChange={{state.onChange}}
          @summary={{options.summary}}
          @newRecordValues={{options.newRecordValues}}
          @rowLabel={{options.rowLabel}}
          @rowNumberOffset={{options.rowNumberOffset}}
          @height={{600}}
        />
      </template>
    );
  }

  test('GR1 three groups: three header rows with label and count, records under each, one add row per group, none at the end', async function (assert) {
    const state = new State();
    state.groups = [
      group('status:Open', 'Open'),
      group('status:Doing', 'Doing', { continued: true, count: 9 }),
      group('status:', null, { label: undefined })
    ];
    await renderSheet(state);
    assert.strictEqual(kinds(), 'grragrragrra', 'header, records, add row, x3');
    assert.dom('.euiDataGridRow[data-grid-row-index="12"]').doesNotExist();
    // the label: format(value) of the group's field, "(Empty)" for no value
    assert.strictEqual(labelPart(0, 'Title'), 'Open');
    assert.strictEqual(labelPart(4, 'Title'), 'Doing');
    assert.strictEqual(labelPart(8, 'Title'), '(Empty)');
    assert.strictEqual(labelPart(0, 'Count'), '2');
    assert.strictEqual(labelPart(4, 'Count'), '9');
    assert.strictEqual(labelPart(4, 'Continued'), '(continued)');
    assert.strictEqual(labelPart(0, 'Continued'), '', 'not continued');
    assert.strictEqual(
      labelCell(0).getAttribute('aria-label'),
      'Status: Open, 2',
      'every cell announces the group'
    );
    // records under each header
    assert.strictEqual(text(1, 0), 'Name r0');
    assert.strictEqual(text(6, 0), 'Name r3');
    assert.strictEqual(text(10, 0), 'Name r5');
    // each add row like the sheet's: text in the first field, plus in the row number
    for (const row of [3, 7, 11]) {
      assert
        .dom('[data-test-subj=euiSheetAddRecord]', gridRow(row))
        .hasText('Add record', `row ${row}: the text`);
      assert
        .dom('[data-test-subj=euiSheetRowAdd]', gridRow(row))
        .exists(`row ${row}: the plus`);
      assert.strictEqual(
        getComputedStyle(cell(row, 1)).cursor,
        'pointer',
        `row ${row}: the add row's look`
      );
    }
    // the label of an owner's own `label` wins
    state.groups = [
      group('status:Open', 'Open', { label: 'Open ones' }),
      ...state.groups.slice(1)
    ];
    await settled();
    assert.strictEqual(labelPart(0, 'Title'), 'Open ones');
  });

  test('GR2 without @groups and with an empty array: the v0.2 rows', async function (assert) {
    const state = new State();
    state.groups = undefined;
    await renderSheet(state);
    assert.strictEqual(kinds(), 'rrrrrra', 'records, then one add row');
    assert.dom('.euiSheet__groupRow').doesNotExist();
    assert.strictEqual(rowLabel(0), '1');
    assert.strictEqual(rowLabel(5), '6');
    state.groups = [];
    await settled();
    assert.strictEqual(kinds(), 'rrrrrra', 'an empty array: the same');
    assert.dom('[data-test-subj=euiSheetGroupLabel]').doesNotExist();
    await click(cell(6, 0));
    assert.deepEqual(
      state.changes.map((c) => [c.inserts[0]?.index, c.inserts[0]?.groupKey]),
      [[6, undefined]],
      'the add row inserts at the end, no group'
    );
  });

  test('GR3 the toggle: click collapses, the owner drops the records, focus stays on the header; Enter expands; focus follows a header that moves', async function (assert) {
    const store = localRecords<Row>(rows(), {
      getRecordId: getId,
      fields: FIELDS,
      groupBy: BY_STATUS
    });
    const calls: [string, boolean][] = [];
    const toggle = (key: string, collapsed: boolean) => {
      calls.push([key, collapsed]);
      store.toggleGroup(key, collapsed);
    };
    await render(
      <template>
        <EuiSheet
          @fields={{FIELDS}}
          @records={{store.view.records}}
          @groups={{store.view.groups}}
          @groupBy={{store.groupBy}}
          @onGroupToggle={{toggle}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
          @height={{600}}
        />
      </template>
    );
    // groups by text: Doing, Done, Open
    assert.strictEqual(kinds(), 'grragrragrra');
    assert.strictEqual(labelPart(0, 'Title'), 'Doing');
    assert.strictEqual(labelCell(0).getAttribute('aria-expanded'), 'true');
    const toggleOf = (row: number) =>
      el('[data-test-subj=euiSheetGroupToggle]', labelCell(row));
    assert.strictEqual(toggleOf(0).getAttribute('title'), 'Collapse group');
    // a press on the chevron focuses its cell, then the click
    await focus(labelCell(0));
    await click(toggleOf(0));
    assert.deepEqual(calls, [['status:Doing', true]]);
    assert.strictEqual(kinds(), 'ggrragrra', 'the group has no rows now');
    assert.strictEqual(labelCell(0).getAttribute('aria-expanded'), 'false');
    assert.strictEqual(toggleOf(0).getAttribute('title'), 'Expand group');
    assert.strictEqual(labelPart(0, 'Count'), '2', 'the count stays');
    assert.strictEqual(activeRow(), 0, 'focus is on the header');

    await press('Enter');
    assert.deepEqual(calls[1], ['status:Doing', false], 'Enter expands');
    assert.strictEqual(kinds(), 'grragrragrra');
    assert.strictEqual(activeRow(), 0, 'focus stays');

    // Space on the second header collapses it; the title toggles too
    await focus(labelCell(4));
    await press(' ');
    assert.deepEqual(calls[2], ['status:Done', true]);
    assert.strictEqual(activeRow(), 4);
    await click(el('[data-test-subj=euiSheetGroupTitle]', labelCell(4)));
    assert.deepEqual(calls[3], ['status:Done', false], 'a click on the title');

    // the owner collapses the first group while the third header has focus:
    // the header moves up three rows, focus goes with it
    await focus(labelCell(8));
    store.toggleGroup('status:Doing', true);
    await settled();
    assert.strictEqual(kinds(), 'ggrragrra');
    assert.strictEqual(labelPart(5, 'Title'), 'Open');
    assert.strictEqual(activeRow(), 5, 'focus followed the header by its key');
    // Ctrl+Enter is not the toggle
    await press('Enter', { ctrlKey: true });
    assert.strictEqual(calls.length, 4);
  });

  test('GR4 without @onGroupToggle: no chevron, Enter and Space do nothing', async function (assert) {
    const state = new State();
    await renderSheet(state, { toggle: false });
    assert.dom('[data-test-subj=euiSheetGroupToggle]').doesNotExist();
    assert.dom('[data-eui-sheet-group-toggle]').doesNotExist();
    assert.false(labelCell(0).hasAttribute('aria-expanded'));
    await focus(labelCell(0));
    await press('Enter');
    await press(' ');
    await click(el('[data-test-subj=euiSheetGroupTitle]', labelCell(0)));
    assert.strictEqual(kinds(), 'grragrragrra', 'nothing collapsed');
    assert.deepEqual(state.toggles, []);
    assert.deepEqual(state.changes, [], 'no change set');
    assert.strictEqual(activeRow(), 0, 'focus stays on the header');
  });

  test('GR9 a group add row inserts one record with the group values over @newRecordValues', async function (assert) {
    const state = new State();
    await renderSheet(state, {
      newRecordValues: () => ({ status: 'Elsewhere', owner: 'Cy', qty: 7 })
    });
    // Enter on the second group's add row (grid row 7)
    await focusCell(7, 0);
    await press('Enter');
    const insert = state.changes[0]!.inserts[0]!;
    assert.deepEqual(
      insert.values,
      { status: 'Doing', owner: 'Cy', qty: 7 },
      'the group value wins'
    );
    assert.strictEqual(insert.groupKey, 'status:Doing');
    assert.deepEqual(insert.anchor, { recordId: 'r3', position: 'after' });
    assert.strictEqual(insert.index, 4, 'after the group last record');
    assert.strictEqual(state.changes[0]!.inserts.length, 1);
    // a click on the first group's add row
    await click(cell(3, 1));
    const second = state.changes[1]!.inserts[0]!;
    assert.strictEqual(second.groupKey, 'status:Open');
    assert.strictEqual(second.values['status'], 'Open');
    assert.deepEqual(second.anchor, { recordId: 'r1', position: 'after' });

    // two levels: both fields; an empty group has no anchor
    state.groupBy = [...BY_STATUS, { field: 'owner', direction: 'asc' }];
    state.groups = [
      group('status:Open', 'Open', { loaded: undefined }),
      group('status:Open/owner:Ana', 'Ana', { depth: 1, count: 0, loaded: 0 }),
      group('status:Open/owner:Bo', 'Bo', { depth: 1 }),
      group('status:Doing', 'Doing', { loaded: undefined }),
      group('status:Doing/owner:Ana', 'Ana', { depth: 1, loaded: 4 })
    ];
    await settled();
    assert.strictEqual(kinds(), 'ggagrraggrrrra');
    await focusCell(2, 0);
    await press('Enter');
    const empty = state.changes[2]!.inserts[0]!;
    assert.deepEqual(empty.values, {
      status: 'Open',
      owner: 'Ana',
      qty: 7
    });
    assert.strictEqual(empty.groupKey, 'status:Open/owner:Ana');
    assert.strictEqual(empty.anchor, undefined, 'an empty group: no anchor');
    assert.strictEqual(empty.index, 0, 'the records above it: none');
    await focusCell(13, 2);
    await press('Enter');
    const nested = state.changes[3]!.inserts[0]!;
    assert.deepEqual(nested.values, { status: 'Doing', owner: 'Ana', qty: 7 });
    assert.deepEqual(nested.anchor, { recordId: 'r5', position: 'after' });
    assert.strictEqual(nested.index, 6);
  });

  test('GR12 row numbers: continuous across groups; rowNumberStart after a collapsed group; @rowLabel gets the position', async function (assert) {
    const state = new State();
    const seen: number[] = [];
    await renderSheet(state, {
      rowLabel: (record, position) => {
        seen.push(position);
        return `#${position} ${record.id}`;
      }
    });
    assert.deepEqual(
      [1, 2, 5, 6, 9, 10].map(rowLabel),
      ['#1 r0', '#2 r1', '#3 r2', '#4 r3', '#5 r4', '#6 r5'],
      'continuous across headers and add rows'
    );
    assert.dom('[data-test-subj=euiSheetRowLabel]', gridRow(0)).doesNotExist();
    assert.dom('[data-test-subj=euiSheetRowLabel]', gridRow(3)).doesNotExist();

    // the owner's collapsed group of 5 between the two others, as
    // `groupRecords` gives it, and @rowNumberOffset
    seen.length = 0;
    state.records = rows().slice(0, 4);
    state.groups = [
      group('a', 'Open', { rowNumberStart: 11 }),
      group('b', 'Late', {
        count: 5,
        loaded: 0,
        collapsed: true,
        rowNumberStart: 13
      }),
      group('c', 'Doing', { rowNumberStart: 18 })
    ];
    await settled();
    assert.strictEqual(kinds(), 'grraggrra');
    assert.deepEqual(
      [1, 2, 6, 7].map(rowLabel),
      ['#11 r0', '#12 r1', '#18 r2', '#19 r3'],
      'the next group starts after the collapsed one'
    );
    assert.true(seen.includes(18), '@rowLabel got the position');

    // without rowNumberStart: @rowNumberOffset + 1, continuous
    await renderSheet(state, { rowNumberOffset: 10 });
    state.groups = [group('a', 'Open'), group('c', 'Doing')];
    await settled();
    assert.deepEqual([1, 2, 5, 6].map(rowLabel), ['11', '12', '13', '14']);

    // a parent's start goes to its first child's first record
    state.groupBy = [...BY_STATUS, { field: 'owner', direction: 'asc' }];
    state.groups = [
      group('p', 'Open', { loaded: undefined, rowNumberStart: 31 }),
      group('p/x', 'Ana', { depth: 1, loaded: 1 }),
      group('p/y', 'Bo', { depth: 1, loaded: 3 })
    ];
    await settled();
    assert.strictEqual(kinds(), 'ggragrrra');
    assert.deepEqual(
      [2, 5, 6, 7].map(rowLabel),
      ['31', '32', '33', '34'],
      'the parent start, then continuous'
    );
  });

  test('GR19 a group summary in its header row under its column, the footer @summary beside it', async function (assert) {
    const state = new State();
    state.groups = [
      group('status:Open', 'Open', {
        summary: { qty: 'Sum 3', owner: '2 owners' }
      }),
      group('status:Doing', 'Doing', { summary: { qty: 'Sum 7' } }),
      group('status:Done', 'Done')
    ];
    await renderSheet(state, { summary: { qty: 'Sum 21' } });
    const summaryOf = (row: number, col: number) =>
      cell(row, col).querySelector('[data-test-subj=euiSheetGroupSummary]');
    assert.true(shown(summaryOf(0, 3)), 'qty: shown');
    assert.strictEqual(summaryOf(0, 3)?.textContent?.trim(), 'Sum 3');
    assert.strictEqual(summaryOf(0, 2)?.textContent?.trim(), '2 owners');
    assert.strictEqual(summaryOf(4, 3)?.textContent?.trim(), 'Sum 7');
    assert.strictEqual(summaryOf(4, 2), null, 'no text: nothing');
    assert.strictEqual(summaryOf(8, 3), null, 'no summary: nothing');
    assert.strictEqual(
      getComputedStyle(summaryOf(0, 3)!).textAlign,
      'end',
      'right-aligned'
    );
    assert
      .dom(
        '.euiDataGridFooterCell[data-gridcell-column-id="qty"] [data-test-subj=euiSheetSummary]'
      )
      .hasText('Sum 21', 'the footer is the whole view');
    assert
      .dom(
        '.euiDataGridFooterCell[data-gridcell-column-id="owner"] [data-test-subj=euiSheetSummary]'
      )
      .hasText('', 'a group summary is not in the footer');
  });

  test('GR20 two levels: indentation, a collapsed parent, add rows only under leaves', async function (assert) {
    const state = new State();
    state.groupBy = [...BY_STATUS, { field: 'owner', direction: 'asc' }];
    state.records = rows().slice(0, 3);
    state.groups = [
      group('o', 'Open', { loaded: undefined, count: 3 }),
      group('o/a', 'Ana', { depth: 1, count: 1, loaded: 1 }),
      group('o/b', 'Bo', { depth: 1, count: 2, loaded: 2 }),
      group('d', 'Done', { collapsed: true, loaded: undefined, count: 4 })
    ];
    await renderSheet(state);
    assert.strictEqual(
      kinds(),
      'ggragrrag',
      'no add row under a parent or a collapsed group'
    );
    assert.dom(gridRow(0)).hasClass('euiSheet__groupRow--depth0');
    assert.dom(gridRow(1)).hasClass('euiSheet__groupRow--depth1');
    assert.dom(gridRow(4)).hasClass('euiSheet__groupRow--depth1');
    const indent = (row: number) =>
      getComputedStyle(
        el('[data-test-subj=euiSheetGroupLabel]', labelCell(row))
      ).paddingInlineStart;
    assert.strictEqual(indent(0), '0px');
    assert.strictEqual(indent(1), '16px');
    assert.true(
      el(
        '[data-test-subj=euiSheetGroupTitle]',
        labelCell(1)
      ).getBoundingClientRect().left >
        el(
          '[data-test-subj=euiSheetGroupTitle]',
          labelCell(0)
        ).getBoundingClientRect().left,
      'the child label starts further right'
    );
    assert.strictEqual(labelPart(1, 'Title'), 'Ana');
    assert.strictEqual(
      labelCell(1).getAttribute('aria-label'),
      'Owner: Ana, 1'
    );
    assert.strictEqual(labelCell(8).getAttribute('aria-expanded'), 'false');
    assert.strictEqual(labelPart(8, 'Count'), '4');
    // a toggle on the child names the child
    await focus(labelCell(4));
    await press('Enter');
    assert.deepEqual(state.toggles, [['o/b', true]]);
  });

  test('GR21 Σ loaded smaller than the records: every record is drawn, in the last group, and a warning is logged', async function (assert) {
    warnings = [];
    try {
      const state = new State();
      state.groups = [
        group('status:Open', 'Open', { loaded: 2 }),
        group('status:Doing', 'Doing', { loaded: 1 })
      ];
      await renderSheet(state);
      assert.strictEqual(kinds(), 'grragrrrra', 'all six records');
      assert.strictEqual(text(8, 0), 'Name r5', 'the last one');
      assert.true(
        warnings.includes('ember-eui.sheet.groups-loaded-mismatch'),
        'the warning'
      );
      warnings.length = 0;
      state.groups = [
        group('status:Open', 'Open', { loaded: 2 }),
        group('status:Doing', 'Doing', { loaded: 4 })
      ];
      await settled();
      assert.false(
        warnings.includes('ember-eui.sheet.groups-loaded-mismatch'),
        'no warning when they add up'
      );
    } finally {
      warnings = null;
    }
  });

  test('GR23 a re-query that reorders groups, or new @groups alone: focus and the range follow the record; a menu closes', async function (assert) {
    const state = new State();
    await renderSheet(state);
    // r1, owner (grid row 2)
    await focusCell(2, 2);
    assert.deepEqual(selected(), ['2:2']);
    // the owner re-queries: Done first, then Doing, then Open
    const byId = new Map(rows().map((row) => [row.id, row]));
    state.records = ['r4', 'r5', 'r2', 'r3', 'r0', 'r1'].map((id) =>
      byId.get(id)!
    );
    state.groups = [
      group('status:Done', 'Done'),
      group('status:Doing', 'Doing'),
      group('status:Open', 'Open')
    ];
    await settled();
    assert.strictEqual(text(10, 0), 'Name r1');
    assert.strictEqual(activeRow(), 10, 'focus followed r1 to row 10');
    // the same records, new groups: an empty group above them
    state.groups = [
      group('status:New', 'New', { count: 0, loaded: 0 }),
      ...state.groups
    ];
    await settled();
    assert.strictEqual(kinds(), 'gagrragrragrra');
    assert.strictEqual(text(12, 0), 'Name r1');
    assert.strictEqual(activeRow(), 12, 'focus followed r1 down two rows');
    assert.deepEqual(selected(), ['12:2'], 'the range too');
    assert.strictEqual(
      Number(
        (document.activeElement as HTMLElement).dataset['gridcellColumnIndex']
      ),
      3,
      'the same column'
    );
    // a row menu open on r1 closes when the groups move the rows
    await press('F10', { shiftKey: true });
    await frames();
    assert
      .dom('[data-test-subj=euiSheetRowMenu]', document.body)
      .exists('menu open');
    state.groups = state.groups.slice(1);
    await settled();
    assert
      .dom('[data-test-subj=euiSheetRowMenu]', document.body)
      .doesNotExist('menu closed');
    assert.strictEqual(activeRow(), 10, 'and focus is on r1 again');
    // a group's add row keeps focus by its key
    await focusCell(7, 0);
    state.groups = [
      group('status:New', 'New', { count: 0, loaded: 0 }),
      ...state.groups
    ];
    await settled();
    assert.strictEqual(
      activeRow(),
      9,
      "the Doing group's add row, two rows down"
    );
    assert.dom(gridRow(9)).hasClass('euiSheet__addRow');
    // a new array of the same records with new groups (a re-query with
    // new headers): focus follows the record
    await focusCell(12, 1);
    state.records = [...state.records];
    state.groups = state.groups.slice(1);
    await settled();
    assert.strictEqual(text(10, 0), 'Name r1');
    assert.strictEqual(activeRow(), 10, 'r1, two rows up');
    assert.deepEqual(selected(), ['10:1']);
  });

  test('GRF1 the "+" column: the group colour on a header row, the add-row look on a group add row, the frame edge kept', async function (assert) {
    const state = new State();
    const onFieldCreate = () => {};
    await render(
      <template>
        <div style="width:900px">
          <EuiSheet
            @fields={{FIELDS}}
            @records={{state.records}}
            @groups={{state.groups}}
            @groupBy={{state.groupBy}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @onFieldCreate={{onFieldCreate}}
            @height={{600}}
          />
        </div>
      </template>
    );
    await frames();
    const plusCell = (row: number) =>
      el(
        '[role=gridcell][data-gridcell-column-id="euiSheet-addField"]',
        gridRow(row)
      );
    const background = (element: Element) =>
      getComputedStyle(element).backgroundColor;
    // header row 0, group add row 3, record row 1
    assert.strictEqual(
      background(plusCell(0)),
      background(cell(0, 1)),
      `header: the group colour (${background(plusCell(0))})`
    );
    assert.strictEqual(
      background(plusCell(3)),
      background(cell(3, 1)),
      `add row: the add-row colour (${background(plusCell(3))})`
    );
    for (const row of [0, 3]) {
      const style = getComputedStyle(plusCell(row));
      assert.true(
        plusCell(row).classList.contains('euiDataGridRowCell--lastColumn'),
        `row ${row}: the "+" cell is the last column`
      );
      assert.true(
        parseFloat(style.borderRightWidth) > 0 &&
          !/rgba\([^)]*,\s*0\)$/.test(style.borderRightColor) &&
          style.borderRightColor !== 'transparent',
        `row ${row}: the frame's right edge (${style.borderRightWidth} ${style.borderRightColor})`
      );
    }
    // a focus on the "+" cell of a header row lands on that row, no error
    await focus(plusCell(0));
    assert.strictEqual(activeRow(), 0, 'still the header row');
    assert.deepEqual(state.changes, []);
    await focus(plusCell(3));
    assert.strictEqual(activeRow(), 3, 'the add row');
    await press('Enter');
    assert.strictEqual(
      state.changes[0]?.inserts[0]?.groupKey,
      'status:Open',
      'Enter there adds to the group'
    );
  });

  test('GRF2 --euiSheetGroupMin with a first field the grid sizes: row numbers + that column', async function (assert) {
    const state = new State();
    const fields: EuiSheetField<Row>[] = [
      { id: 'name', label: 'Name' },
      ...FIELDS.slice(1)
    ];
    await render(
      <template>
        <div style="width:900px">
          <EuiSheet
            @fields={{fields}}
            @records={{state.records}}
            @groups={{state.groups}}
            @groupBy={{state.groupBy}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @height={{600}}
          />
        </div>
      </template>
    );
    await frames();
    const header = (index: number) =>
      el(`[role=columnheader][data-gridcell-column-index="${index}"]`);
    const expected = header(0).offsetWidth + header(1).offsetWidth;
    const min = parseFloat(getComputedStyle(labelCell(0)).minWidth);
    assert.true(
      header(1).offsetWidth > 120,
      `the grid widened the first field (${header(1).offsetWidth}px)`
    );
    assert.true(
      Math.abs(min - expected) <= 1,
      `min-width ${min}px is row numbers + first field ${expected}px`
    );
  });

  test('GRV1 a header row stands apart from the records and the row numbers, light and dark', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const colours = () => ({
      header: getComputedStyle(cell(0, 1)).backgroundColor,
      record: getComputedStyle(cell(1, 1)).backgroundColor,
      rowNumber: getComputedStyle(
        el('[data-gridcell-column-id="euiSheetRow"]', gridRow(1))
      ).backgroundColor
    });
    const light = colours();
    const emotion = this.owner.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService;
    emotion.colorMode = 'dark';
    await settled();
    const dark = colours();
    console.log(
      `GRV1 light ${JSON.stringify(light)} dark ${JSON.stringify(dark)}`
    );
    for (const [mode, c] of [
      ['light', light],
      ['dark', dark]
    ] as const) {
      assert.notStrictEqual(
        c.header,
        c.record,
        `${mode}: header ${c.header}, record ${c.record}`
      );
      assert.notStrictEqual(
        c.header,
        c.rowNumber,
        `${mode}: header ${c.header}, row number ${c.rowNumber}`
      );
    }
    assert.notStrictEqual(dark.header, light.header);
  });
});
