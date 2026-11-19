/**
 * EuiSheet: the spike's integration cases T1-T16 (PACKAGE-DESIGN.md 10.1),
 * plus the manual demo page.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
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
  changeSet,
  clipboard,
  COL_OFFSET,
  editor,
  editorFrame,
  el,
  focusCell,
  press,
  pressed,
  scrollTo,
  selected,
  text,
  type
} from '../../helpers/sheet.ts';

import type {
  ChangeSet,
  EuiSheetField,
  RecordId,
  SheetOption
} from '#src/core/index.ts';
import type { SheetApi } from '#src/types.ts';

interface Person {
  id: string;
  name: string;
  city: string;
  qty: string;
}

const FIELDS: EuiSheetField[] = [{ id: 'name' }, { id: 'city' }, { id: 'qty' }];
const people = (count = 5): Person[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    name: `name${i}`,
    city: `city${i}`,
    qty: `${i}`
  }));
const getId = (record: { id: string }) => record.id;

module('Integration | Component | EuiSheet', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(
    options: {
      count?: number;
      fields?: EuiSheetField[];
      height?: number;
    } = {}
  ) {
    const store = localRecords(people(options.count), {
      getRecordId: getId
    });
    const fields = options.fields ?? FIELDS;
    const height = options.height;
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @records={{store.records}}
            @fields={{fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @height={{height}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('T1 type-to-edit, Enter saves and moves down', async function (assert) {
    const store = await renderSheet();
    await focusCell(1, 0);
    await type('x');
    assert.ok(editor(), 'editor exists');
    assert.strictEqual(editor()?.value, 'x');
    assert.strictEqual(document.activeElement, editor(), 'editor is focused');

    await fillIn(editor()!, 'xy');
    await press('Enter');
    assert.strictEqual(editor(), null, 'no editor');
    assert.strictEqual(text(1, 0), 'xy');
    assert.deepEqual(store.log, [
      changeSet({
        source: 'edit',
        patches: [{ recordId: 'r1', fieldId: 'name', from: 'name1', to: 'xy' }]
      })
    ]);
    await waitUntil(() => document.activeElement === cell(2, 0));
    assert.strictEqual(document.activeElement, cell(2, 0));
    await settled();
    assert.deepEqual(selected(), ['2:0']);
  });

  test('T2 Enter and F2 edit the current value, Esc cancels', async function (assert) {
    const store = await renderSheet();
    const reachedDocument: string[] = [];
    const onDocumentKeyDown = (event: KeyboardEvent) =>
      reachedDocument.push(event.key);
    document.addEventListener('keydown', onDocumentKeyDown);
    try {
      await focusCell(0, 1);
      await press('Enter');
      assert.strictEqual(
        editor()?.value,
        'city0',
        'Enter opens with the current value'
      );
      await fillIn(editor()!, 'zzz');
      await press('Escape');
      assert.strictEqual(editor(), null, 'no editor after Escape');
      assert.strictEqual(text(0, 1), 'city0');
      assert.strictEqual(store.log.length, 0);
      await waitUntil(() => document.activeElement === cell(0, 1));
      assert.dom(cell(0, 1)).hasAttribute('tabindex', '0');

      await press('F2');
      assert.strictEqual(
        editor()?.value,
        'city0',
        'F2 opens with the current value'
      );
      await press('Escape');
      assert.strictEqual(editor(), null);
      assert.strictEqual(store.log.length, 0);
      await waitUntil(() => document.activeElement === cell(0, 1));
      assert.dom(cell(0, 1)).hasAttribute('tabindex', '0');
      assert.notOk(
        reachedDocument.includes('Escape'),
        'Escape did not reach the document'
      );
    } finally {
      document.removeEventListener('keydown', onDocumentKeyDown);
    }
  });

  test('T3 Tab saves and moves right, Shift+Tab left, clamps', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 1);
    await type('a');
    await press('Tab');
    await waitUntil(() => document.activeElement === cell(0, 2));
    assert.strictEqual(document.activeElement, cell(0, 2));
    await type('b');
    await press('Tab');
    await waitUntil(() => document.activeElement === cell(0, 2));
    assert.strictEqual(
      document.activeElement,
      cell(0, 2),
      'last column: stays'
    );
    await type('c');
    await press('Tab');
    await waitUntil(() => document.activeElement === cell(0, 2));
    assert.strictEqual(document.activeElement, cell(0, 2));
    await type('d');
    await press('Tab', { shiftKey: true });
    await waitUntil(() => document.activeElement === cell(0, 1));
    assert.strictEqual(document.activeElement, cell(0, 1));
    assert.strictEqual(text(0, 1), 'a');
    assert.strictEqual(text(0, 2), 'd');
    assert.strictEqual(store.log.length, 4, 'four change sets');
  });

  test('T4 Shift+arrows select a range, Delete clears it', async function (assert) {
    const store = await renderSheet();
    await focusCell(1, 0);
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowRight', { shiftKey: true });
    await settled();
    assert.deepEqual(selected(), ['1:0', '1:1', '2:0', '2:1']);
    // the active cell stays the anchor (V03 batch 1)
    assert.strictEqual(document.activeElement, cell(1, 0));

    await press('Delete');
    await settled();
    assert.deepEqual(
      [text(1, 0), text(1, 1), text(2, 0), text(2, 1)],
      ['', '', '', '']
    );
    assert.deepEqual(store.log, [
      changeSet({
        source: 'clear',
        patches: [
          { recordId: 'r1', fieldId: 'name', from: 'name1', to: '' },
          { recordId: 'r1', fieldId: 'city', from: 'city1', to: '' },
          { recordId: 'r2', fieldId: 'name', from: 'name2', to: '' },
          { recordId: 'r2', fieldId: 'city', from: 'city2', to: '' }
        ]
      })
    ]);
    assert.strictEqual(text(3, 0), 'name3', '(3, 0) unchanged');

    // a plain arrow moves from the active cell and collapses
    await press('ArrowDown');
    await settled();
    assert.deepEqual(selected(), ['2:0']);
  });

  test('T5 copy gives the range as TSV', async function (assert) {
    await renderSheet();
    await focusCell(1, 0);
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowRight', { shiftKey: true });
    await settled();

    let result = await clipboard('copy');
    assert.strictEqual(result.text, 'name1\tcity1\nname2\tcity2');
    assert.true(result.prevented);

    // with a text selection the grid's onTabularCopy would rewrite it. The
    // whole grid is selected so the selection holds the copy markers that
    // handler acts on (one cell's content holds none).
    const range = document.createRange();
    range.selectNodeContents(el('[role=grid]'));
    const selection = window.getSelection()!;
    selection.removeAllRanges();
    selection.addRange(range);
    // positive control: the same copy dispatched on document (bypassing
    // the sheet's wrapper) is rewritten by the grid's handler
    const controlData = new DataTransfer();
    const control = new ClipboardEvent('copy', {
      clipboardData: controlData,
      bubbles: true,
      cancelable: true
    });
    document.dispatchEvent(control);
    assert.true(
      control.defaultPrevented,
      'control: the grid handles a document copy'
    );
    assert.true(
      controlData.getData('text/plain').includes('name1\tcity1\t1\n'),
      `control: the grid wrote its own TSV (${JSON.stringify(controlData.getData('text/plain'))})`
    );
    result = await clipboard('copy');
    selection.removeAllRanges();
    assert.strictEqual(
      result.text,
      'name1\tcity1\nname2\tcity2',
      'with a text selection'
    );
    assert.true(result.prevented);
  });

  test('T6 paste a 2x3 block at the last row inserts a row', async function (assert) {
    const store = await renderSheet();
    await focusCell(4, 0);
    const result = await clipboard('paste', 'a\tb\tc\r\nd\te\tf\r\n');
    assert.true(result.prevented);
    assert.strictEqual(store.log.length, 1);
    const set = store.log[0]!;
    assert.strictEqual(set.source, 'paste');
    assert.deepEqual(set.patches, [
      { recordId: 'r4', fieldId: 'name', from: 'name4', to: 'a' },
      { recordId: 'r4', fieldId: 'city', from: 'city4', to: 'b' },
      { recordId: 'r4', fieldId: 'qty', from: '4', to: 'c' }
    ]);
    assert.strictEqual(set.inserts.length, 1);
    assert.strictEqual(set.inserts[0]!.index, 5);
    assert.deepEqual(set.inserts[0]!.values, {
      name: 'd',
      city: 'e',
      qty: 'f'
    });
    assert.deepEqual(set.rejected, []);
    assert.deepEqual(set.newOptions, []);

    await settled();
    // 6 records and the add row (v0.2 batch 2)
    assert.dom('[role=grid]').hasAttribute('aria-rowcount', '7');
    assert.deepEqual([text(5, 0), text(5, 1), text(5, 2)], ['d', 'e', 'f']);
    assert.deepEqual(selected(), ['4:0', '4:1', '4:2', '5:0', '5:1', '5:2']);
    assert.strictEqual(
      document.activeElement,
      cell(4, 0),
      'focus stays on the anchor'
    );

    await focusCell(0, 1);
    await clipboard('paste', 'p\tq\tr');
    assert.strictEqual(store.log.length, 2);
    assert.deepEqual(store.log[1]!.patches, [
      { recordId: 'r0', fieldId: 'city', from: 'city0', to: 'p' },
      { recordId: 'r0', fieldId: 'qty', from: '0', to: 'q' }
    ]);
    assert.deepEqual(store.log[1]!.inserts, []);
  });

  test('T7 the selection class survives virtualization', async function (assert) {
    await renderSheet({ count: 200, height: 300 });
    await focusCell(2, 0);
    const started = performance.now();
    await press('ArrowDown', { shiftKey: true });
    await settled();
    const ms = performance.now() - started;
    await press('ArrowDown', { shiftKey: true });
    await press('ArrowRight', { shiftKey: true });
    await press('Control');
    await settled();
    const expected = ['2:0', '2:1', '3:0', '3:1', '4:0', '4:1'];
    assert.deepEqual(selected(), expected, 'six selected cells');
    const renderedCells = document.querySelectorAll('[role=gridcell]').length;
    assert.ok(
      true,
      `T7 timing: ${ms.toFixed(1)} ms over ${renderedCells} rendered cells`
    );

    const rowHeight = el('.euiDataGridRow').offsetHeight;
    await scrollTo(rowHeight * 100);
    await settled();
    assert.strictEqual(
      document.querySelector('[data-gridcell-visible-row-index="2"]'),
      null,
      'row 2 is not rendered'
    );
    assert.deepEqual(selected(), [], 'no selected cell rendered');

    // V03 batch 1: the focused active cell (the anchor) unmounted while a
    // range is selected; the grid's body holds focus, so keys still work
    assert.strictEqual(
      document.activeElement,
      el('[role=grid]'),
      'focus is held by the grid'
    );

    await scrollTo(0);
    await settled();
    await waitUntil(() => document.activeElement === cell(2, 0));
    assert.strictEqual(
      document.activeElement,
      cell(2, 0),
      'the re-mounted focused cell took focus again'
    );
    assert.deepEqual(selected(), expected, 'selection is back');
  });

  test("T8 the grid's Enter/F2 popover stays closed", async function (assert) {
    await renderSheet();
    await focusCell(1, 1);
    assert
      .dom('[data-test-subj=euiDataGridCellExpandButton]', cell(1, 1))
      .doesNotExist('cells are never expandable');
    await press('Enter');
    assert.ok(editor(), 'Enter: editor');
    assert
      .dom('[data-test-subj=euiDataGridExpansionPopover]', document.body)
      .doesNotExist();
    assert.dom(cell(1, 1)).doesNotHaveClass('euiDataGridRowCell--open');
    await press('Escape');
    await waitUntil(() => document.activeElement === cell(1, 1));
    await press('F2');
    assert.ok(editor(), 'F2: editor');
    assert
      .dom('[data-test-subj=euiDataGridExpansionPopover]', document.body)
      .doesNotExist();
    assert.dom(cell(1, 1)).doesNotHaveClass('euiDataGridRowCell--open');
  });

  test('T9 clicking another cell commits and does not steal focus', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 0);
    await type('q');
    await fillIn(editor()!, 'q1');
    await click(cell(3, 2));
    assert.strictEqual(editor(), null, 'no editor');
    assert.strictEqual(text(0, 0), 'q1');
    assert.strictEqual(store.log.length, 1, 'exactly one change set');
    assert.strictEqual(
      document.activeElement,
      cell(3, 2),
      'the clicked cell keeps focus'
    );
    assert.deepEqual(selected(), ['3:2']);
  });

  test('T10 scrolling while editing commits without a focus fight', async function (assert) {
    const store = await renderSheet({ count: 200, height: 300 });
    await focusCell(1, 0);
    await type('k');
    const rowHeight = el('.euiDataGridRow').offsetHeight;
    await scrollTo(rowHeight * 100);
    await settled();
    assert.strictEqual(editor(), null, 'no editor after scrolling');
    assert.strictEqual(store.log.length, 1);
    assert.strictEqual(store.log[0]!.patches[0]!.to, 'k');

    await scrollTo(0);
    await settled();
    assert.strictEqual(text(1, 0), 'k');
    assert.strictEqual(store.log.length, 1, 'no second change set');
  });

  test('T11 the editor is outside the grid and tabbable', async function (assert) {
    await renderSheet();
    await focusCell(0, 0);
    await press('Enter');
    await settled();
    const input = editor()!;
    assert.ok(input, 'editor');
    assert.dom(input).hasClass('euiSheet__input');
    assert.false(el('.euiDataGrid').contains(input), 'not inside the grid');
    assert.true(
      el('[data-test-subj=euiSheet]').contains(input),
      'inside the sheet'
    );
    assert.dom(input).doesNotHaveAttribute('tabindex', '-1');
    assert.dom(input).doesNotHaveAttribute('data-euigrid-tab-managed');
    assert.strictEqual(document.activeElement, input);
    const a = input.getBoundingClientRect();
    const b = cell(0, 0).getBoundingClientRect();
    // V03 batch 1: the editor covers the cell, lifted up to 2 px past it
    const past = (outerEdge: number) => outerEdge >= -0.5 && outerEdge <= 2.5;
    assert.true(
      past(b.top - a.top) &&
        past(b.left - a.left) &&
        past(a.right - b.right) &&
        past(a.bottom - b.bottom),
      `editor box ${JSON.stringify(a)} covers cell box ${JSON.stringify(b)}`
    );
  });

  test('T12 arrows while editing do not move grid focus', async function (assert) {
    const store = await renderSheet();
    await focusCell(1, 1);
    await press('Enter');
    await press('ArrowDown');
    await press('ArrowRight');
    assert.strictEqual(
      document.activeElement,
      editor(),
      'editor still focused'
    );
    assert.strictEqual(el('[role=gridcell][tabindex="0"]'), cell(1, 1));
    assert.strictEqual(store.log.length, 0);
  });

  test('T13 header cells keep their keys', async function (assert) {
    const store = await renderSheet();
    // the first field's header: grid column 0 is the row-number column (C8)
    await focus(
      `[role=columnheader][data-gridcell-column-index="${COL_OFFSET}"]`
    );
    await type('x');
    await press('Delete');
    const result = await clipboard('paste', 'a');
    assert.strictEqual(editor(), null, 'no editor');
    assert.strictEqual(store.log.length, 0);
    assert.false(result.prevented, 'paste not prevented');
  });

  test('T14 read-only fields', async function (assert) {
    const store = await renderSheet({
      fields: [{ id: 'name' }, { id: 'city', readOnly: true }, { id: 'qty' }]
    });
    await focusCell(0, 1);
    await type('x');
    assert.strictEqual(editor(), null, 'typing: no editor');
    await press('Enter');
    assert.strictEqual(editor(), null, 'Enter: no editor');
    await press('Delete');
    assert.strictEqual(store.log.length, 0, 'no clear');

    await focusCell(0, 0);
    await clipboard('paste', 'a\tb\tc');
    assert.strictEqual(store.log.length, 1);
    assert.deepEqual(store.log[0]!.patches, [
      { recordId: 'r0', fieldId: 'name', from: 'name0', to: 'a' },
      { recordId: 'r0', fieldId: 'qty', from: '0', to: 'c' }
    ]);
  });

  test('T15 Enter on the last row keeps focus there', async function (assert) {
    await renderSheet();
    await focusCell(4, 0);
    await type('z');
    await press('Enter');
    await settled();
    assert.strictEqual(text(4, 0), 'z');
    await waitUntil(() => document.activeElement === cell(4, 0));
    assert.strictEqual(document.activeElement, cell(4, 0));
  });

  // Found with trusted events in Chromium (RESULTS.md D22): after a click, a
  // real copy/paste is dispatched on the cell's content element, where the
  // browser's selection is, not on the focused cell.
  test('T16 copy and paste dispatched on the cell content', async function (assert) {
    const store = await renderSheet();
    await focusCell(1, 0);
    const content = (row: number, col: number) =>
      cell(row, col).querySelector<HTMLElement>('[data-datagrid-cellcontent]')!;

    const copied = await clipboard('copy', '', content(1, 0));
    assert.true(copied.prevented, 'copy handled by the sheet');
    assert.strictEqual(copied.text, 'name1');

    const pasted = await clipboard('paste', 'a\tb\nc\td', content(1, 0));
    assert.true(pasted.prevented, 'paste handled by the sheet');
    assert.strictEqual(store.log.length, 1);
    assert.deepEqual(
      [text(1, 0), text(1, 1), text(2, 0), text(2, 1)],
      ['a', 'b', 'c', 'd']
    );
  });

  // Manual and Playwright check (PACKAGE-DESIGN.md 11.4): build the tests,
  // `vite preview --outDir dist-tests`, open
  // /tests/index.html?filter=demo&sheetdemo
  test('demo (manual)', async function (assert) {
    if (!location.search.includes('sheetdemo')) {
      assert.true(true, 'paused only with ?sheetdemo');
      return;
    }
    const STATUS: SheetOption[] = [
      { value: 'open', label: 'Open' },
      { value: 'closed', label: 'Closed', color: 'success' },
      { value: 'hold', label: 'On hold', color: 'warning' }
    ];
    const fields: EuiSheetField[] = [
      { id: 'name', label: 'Name', required: true },
      { id: 'qty', label: 'Qty', type: 'number', min: 0 },
      { id: 'done', label: 'Done', type: 'checkbox' },
      { id: 'status', label: 'Status', type: 'singleSelect', options: STATUS },
      { id: 'due', label: 'Due', type: 'date' }
    ];
    const statuses = ['open', 'closed', 'hold'];
    const store = localRecords(
      Array.from({ length: 50 }, (_, i) => ({
        id: `r${i}`,
        name: `name${i}`,
        qty: i,
        done: i % 3 === 0,
        status: statuses[i % 3],
        due: i % 2 ? null : `2026-11-${String((i % 28) + 1).padStart(2, '0')}`
      })),
      { getRecordId: getId, fields }
    );
    (window as unknown as { sheetStore: unknown }).sheetStore = store;
    await render(
      <template>
        <div style="width:900px">
          <EuiSheet
            @records={{store.records}}
            @fields={{store.fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @height={{400}}
          />
        </div>
      </template>
    );
    // the manual check pauses here, only with ?sheetdemo
    // eslint-disable-next-line ember/no-pause-test
    await this.pauseTest();
    assert.true(true);
  });
});

module('Integration | Component | EuiSheet v0.2 foundations', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(
    options: { records?: Person[]; onChange?: (set: ChangeSet) => void } = {}
  ) {
    const store = localRecords(options.records ?? people(), {
      getRecordId: getId
    });
    const state: { api: SheetApi | null; registered: number } = {
      api: null,
      registered: 0
    };
    const registerApi = (api: SheetApi) => {
      state.api = api;
      state.registered++;
    };
    const onChange = options.onChange ?? store.apply;
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{onChange}}
            @registerApi={{registerApi}}
          />
        </div>
      </template>
    );
    return { store, state };
  }

  /** The owner replaces `@records` (a re-sort, a re-query). */
  async function replace(
    store: { records: Person[] },
    next: (records: Person[]) => Person[]
  ): Promise<void> {
    store.records = next(store.records);
    await settled();
  }

  const ids = (records: { id: RecordId }[]) => records.map((r) => r.id);

  test('T17 a cell with a line break is copied quoted and pastes back as one cell', async function (assert) {
    const records = people();
    records[0] = { ...records[0]!, name: 'two\nlines', city: 'say "hi"' };
    const { store } = await renderSheet({ records });
    await focusCell(0, 0);
    await press('ArrowRight', { shiftKey: true });
    const copied = await clipboard('copy');
    assert.true(copied.prevented);
    assert.strictEqual(copied.text, '"two\nlines"\tsay "hi"');

    // a click starts a new selection (focus alone would extend the range)
    await click(cell(2, 0));
    await clipboard('paste', copied.text);
    assert.strictEqual(store.log.length, 1);
    assert.deepEqual(store.log[0]!.patches, [
      { recordId: 'r2', fieldId: 'name', from: 'name2', to: 'two\nlines' },
      { recordId: 'r2', fieldId: 'city', from: 'city2', to: 'say "hi"' }
    ]);
    assert.deepEqual(store.log[0]!.inserts, [], 'one row, no inserts');
  });

  test('T18 @registerApi gives undo, redo, focusCell and clearHistory', async function (assert) {
    const { store, state } = await renderSheet();
    assert.strictEqual(
      state.registered,
      1,
      'called once, after the first render'
    );
    const api = state.api!;

    await focusCell(1, 0);
    await type('x');
    await fillIn(editor()!, 'xy');
    await press('Enter');
    assert.strictEqual(text(1, 0), 'xy');

    api.undo();
    await settled();
    assert.strictEqual(store.log[1]!.source, 'undo');
    assert.strictEqual(text(1, 0), 'name1');
    api.redo();
    await settled();
    assert.strictEqual(store.log[2]!.source, 'redo');
    assert.strictEqual(text(1, 0), 'xy');

    api.focusCell({ recordId: 'r3', fieldId: 'city' });
    await settled();
    assert.strictEqual(document.activeElement, cell(3, 1));
    assert.deepEqual(selected(), ['3:1']);
    api.focusCell({ recordId: 'nope', fieldId: 'city' });
    api.focusCell({ recordId: 'r0', fieldId: 'nope' });
    await settled();
    assert.strictEqual(document.activeElement, cell(3, 1), 'unknown: no-op');

    api.clearHistory();
    api.undo();
    api.redo();
    await settled();
    assert.strictEqual(store.log.length, 3, 'nothing to undo or redo');

    await replace(store, (records) => [...records]);
    assert.strictEqual(state.registered, 1, 'not called again on re-render');
  });

  test('T19 remapIds, then Ctrl+Z of a paste that inserted rows removes the remapped records', async function (assert) {
    const { store, state } = await renderSheet();
    await focusCell(4, 0);
    await clipboard('paste', 'a\nb\nc');
    const paste = store.log[0]!;
    assert.strictEqual(paste.inserts.length, 2);
    assert.strictEqual(store.records.length, 7);

    // the server answers with its own ids
    const serverIds: Record<string, RecordId> = {};
    paste.inserts.forEach(
      (insert, i) => (serverIds[insert.tempId] = `srv-${i}`)
    );
    state.api!.remapIds(serverIds);
    await replace(store, (records) =>
      records.map((r) =>
        serverIds[r.id] ? { ...r, id: `${serverIds[r.id]}` } : r
      )
    );
    assert.deepEqual(ids(store.records).slice(5), ['srv-0', 'srv-1']);
    assert.strictEqual(
      document.activeElement,
      cell(4, 0),
      'carrying new ids is not a change of rows: focus stays'
    );

    assert.true(await pressed('z', { ctrlKey: true }), 'Ctrl+Z');
    const undo = store.log[1]!;
    assert.strictEqual(undo.source, 'undo');
    assert.deepEqual(undo.deletes, ['srv-0', 'srv-1']);
    assert.deepEqual(undo.patches, [
      { recordId: 'r4', fieldId: 'name', from: 'a', to: 'name4' }
    ]);
    await settled();
    assert.deepEqual(ids(store.records), ['r0', 'r1', 'r2', 'r3', 'r4']);
  });

  test('T20 the owner re-orders @records: the selection and focus follow the active cell’s record', async function (assert) {
    const { store } = await renderSheet();
    await focusCell(0, 1);
    await press('ArrowDown', { shiftKey: true });
    assert.deepEqual(selected(), ['0:1', '1:1']);
    // V03 batch 1: the active cell is the anchor, not the head
    assert.strictEqual(document.activeElement, cell(0, 1));

    await replace(store, (records) => [...records].reverse());
    assert.deepEqual(ids(store.records), ['r4', 'r3', 'r2', 'r1', 'r0']);
    assert.deepEqual(
      selected(),
      ['4:1'],
      'collapsed to the active cell, on r0'
    );
    assert.strictEqual(document.activeElement, cell(4, 1), 'focus follows');
    assert.strictEqual(store.log.length, 0);

    await press('Delete');
    assert.deepEqual(
      store.log[0]!.patches,
      [{ recordId: 'r0', fieldId: 'city', from: 'city0', to: '' }],
      'keys act on the record that moved'
    );
  });

  test('T21 the head’s record is gone: the row index is kept, clamped', async function (assert) {
    const { store } = await renderSheet();
    await focusCell(1, 0);
    await replace(store, (records) => records.filter((r) => r.id !== 'r1'));
    assert.deepEqual(selected(), ['1:0'], 'same row: now r2');
    assert.strictEqual(document.activeElement, cell(1, 0));
    assert.strictEqual(text(1, 0), 'name2');

    await focusCell(3, 2);
    await replace(store, (records) => records.slice(0, 2));
    assert.deepEqual(selected(), ['1:2'], 'clamped to the last row');
    assert.strictEqual(document.activeElement, cell(1, 2));
  });

  test('T22 @records re-ordered while an editor has a typed draft: the editor stays on its record', async function (assert) {
    const { store } = await renderSheet();
    await focusCell(1, 0);
    await type('x');
    await fillIn(editor()!, 'xyz');

    await replace(store, (records) => [...records].reverse());
    assert.ok(editor(), 'the editor is still open');
    assert.strictEqual(editor()!.value, 'xyz', 'with its draft');
    assert.strictEqual(document.activeElement, editor(), 'and focus');
    const frame = editorFrame()!.getBoundingClientRect();
    const target = cell(3, 0).getBoundingClientRect();
    assert.true(
      Math.abs(frame.top - target.top) < 2,
      `the frame moved to r1's cell (${frame.top} vs ${target.top})`
    );

    await press('Enter');
    assert.deepEqual(store.log, [
      changeSet({
        source: 'edit',
        patches: [{ recordId: 'r1', fieldId: 'name', from: 'name1', to: 'xyz' }]
      })
    ]);
    assert.strictEqual(text(3, 0), 'xyz');
    assert.strictEqual(text(1, 0), 'name3', 'not the old row index');
    await waitUntil(() => document.activeElement === cell(4, 0));
  });

  test('T23 the edited record is removed from @records: the editor closes, nothing is emitted', async function (assert) {
    const { store } = await renderSheet();
    await focusCell(1, 0);
    await type('x');
    await fillIn(editor()!, 'abc');

    await replace(store, (records) => records.filter((r) => r.id !== 'r1'));
    assert.strictEqual(editor(), null, 'closed');
    assert.strictEqual(store.log.length, 0, 'nothing emitted');
    assert.deepEqual(
      ids(store.records),
      ['r0', 'r2', 'r3', 'r4'],
      'no record written'
    );
    assert.strictEqual(text(1, 0), 'name2');
    assert.strictEqual(
      document.activeElement,
      cell(1, 0),
      'focus is back on the grid'
    );
  });

  test('T25 a redo that only inserts focuses the re-inserted row once it is rendered', async function (assert) {
    const { store } = await renderSheet();
    await focusCell(4, 0);
    // the first line is the row's own value: no patch, one insert
    await clipboard('paste', 'name4\nnew');
    const paste = store.log[0]!;
    assert.deepEqual(paste.patches, []);
    assert.strictEqual(paste.inserts.length, 1);

    assert.true(await pressed('z', { ctrlKey: true }), 'Ctrl+Z');
    assert.strictEqual(store.records.length, 5, 'undone');
    assert.strictEqual(document.activeElement, cell(4, 0));

    assert.true(await pressed('Z', { ctrlKey: true, shiftKey: true }), 'redo');
    const redo = store.log[2]!;
    assert.strictEqual(redo.source, 'redo');
    assert.deepEqual(redo.patches, [], 'insert only');
    await settled();
    assert.strictEqual(store.records.length, 6);
    assert.strictEqual(
      document.activeElement,
      cell(5, 0),
      'focus on the re-inserted row'
    );
    assert.deepEqual(selected(), ['5:0']);
    assert.strictEqual(text(5, 0), 'new');
  });

  test('T24 a select drag in progress ends when the owner replaces @records', async function (assert) {
    const { store } = await renderSheet();
    const wrapper = el('[data-test-subj=euiSheet]');
    await triggerEvent(cell(0, 0), 'mousedown', { button: 0 });
    await triggerEvent(cell(1, 1), 'mouseover');
    assert.dom(wrapper).hasClass('euiSheet--dragging');
    assert.deepEqual(selected(), ['0:0', '0:1', '1:0', '1:1']);

    await replace(store, (records) => [...records].reverse());
    assert.dom(wrapper).doesNotHaveClass('euiSheet--dragging');
    // V03 batch 1: the active cell is the anchor
    assert.deepEqual(
      selected(),
      ['4:0'],
      'no range: the active cell’s record (r0)'
    );

    await triggerEvent(cell(2, 2), 'mouseover');
    assert.deepEqual(selected(), ['4:0'], 'moving on does not drag');
    await triggerEvent(cell(2, 2), 'mouseup', { button: 0 });
    await triggerEvent(cell(2, 2), 'click', { button: 0 });
    assert.strictEqual(store.log.length, 0);
  });
});
