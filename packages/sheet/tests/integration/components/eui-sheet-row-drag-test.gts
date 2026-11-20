/**
 * Drag to reorder rows (V03-DESIGN.md 10.1, RD1-RD10, RD12): the grip,
 * the change set with `moves`, undo and redo, Escape, Alt+Shift+arrows,
 * groups, the insertion line with auto-scroll, and `SheetApi.moveRecords`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  focus,
  render,
  settled,
  triggerEvent
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { frames as autoScrollFrames } from '#src/-private/auto-scroll.ts';
import { localRecords } from '#src/local-records.ts';
import { cell, el, pressed, text } from '../../helpers/sheet.ts';

import type {
  ChangeSet,
  EuiSheetField,
  SheetGroupBy
} from '#src/core/index.ts';
import type { SheetApi, SheetSort } from '#src/types.ts';

interface Row {
  id: string;
  name: string;
  status: string;
}

const getId = (row: Row) => row.id;

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name', width: 120 },
  { id: 'status', label: 'Status', width: 120 }
];

function rows(count = 6): Row[] {
  return Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    name: `N${i}`,
    status: i < count / 2 ? 'Open' : 'Done'
  }));
}

/** The record ids in the store's order. */
function order(records: readonly Row[]): string {
  return records.map((record) => record.id.slice(1)).join('');
}

/** The names shown in the first column, top to bottom. */
function shown(count: number): string {
  return Array.from({ length: count }, (_, i) => text(i, 0).slice(1)).join('');
}

function rowNumberCell(row: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"]`
  );
}

function grip(row: number): HTMLElement {
  return el('[data-test-subj=euiSheetRowGrip]', rowNumberCell(row));
}

function grips(): number {
  return document.querySelectorAll('[data-test-subj=euiSheetRowGrip]').length;
}

function line(): HTMLElement | null {
  return document.querySelector<HTMLElement>(
    '[data-test-subj=euiSheetDropLine]'
  );
}

function center(element: Element): { x: number; y: number } {
  const box = element.getBoundingClientRect();
  return { x: box.left + box.width / 2, y: box.top + box.height / 2 };
}

/** A mouse event on the document at a point (the drag listens there). */
async function mouseAt(
  type: 'mousemove' | 'mouseup',
  x: number,
  y: number
): Promise<void> {
  document.dispatchEvent(
    new MouseEvent(type, {
      bubbles: true,
      cancelable: true,
      clientX: x,
      clientY: y,
      button: 0
    })
  );
  await settled();
}

/** Presses a row's grip. */
async function pressGrip(row: number): Promise<{ x: number; y: number }> {
  const at = center(grip(row));
  await triggerEvent(grip(row), 'mousedown', {
    button: 0,
    clientX: at.x,
    clientY: at.y
  });
  return at;
}

/** A point in the upper or lower quarter of a row's first data cell. */
function pointOn(
  row: number,
  half: 'upper' | 'lower'
): { x: number; y: number } {
  const box = cell(row, 0).getBoundingClientRect();
  return {
    x: box.left + box.width / 2,
    y: box.top + box.height * (half === 'upper' ? 0.25 : 0.75)
  };
}

/** Presses a row's grip, moves over `to` and releases (the click a browser sends after it too). */
async function dragRow(
  from: number,
  to: number,
  half: 'upper' | 'lower'
): Promise<void> {
  await pressGrip(from);
  const point = pointOn(to, half);
  await mouseAt('mousemove', point.x, point.y);
  await mouseAt('mouseup', point.x, point.y);
  await triggerEvent(el('.euiDataGrid__virtualized'), 'click');
}

class State {
  store = localRecords<Row>(rows(), { getRecordId: getId, fields: FIELDS });
  @tracked canMove = true;
  @tracked readOnly = false;
  @tracked sort: SheetSort[] | undefined = undefined;
  changes: ChangeSet[] = [];
  api: SheetApi | null = null;
  onChange = (changeSet: ChangeSet) => {
    this.changes.push(changeSet);
    this.store.apply(changeSet);
  };
  registerApi = (api: SheetApi) => (this.api = api);
  onSortChange = (sort: SheetSort[]) => (this.sort = sort);
}

module('Integration | Component | EuiSheet row drag', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    // elementFromPoint needs the container on screen
    document.getElementById('ember-testing-container')?.scrollIntoView();
  });

  async function renderSheet(state: State): Promise<void> {
    await render(
      <template>
        <div style="width:500px">
          <EuiSheet
            @fields={{FIELDS}}
            @records={{state.store.records}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @canMove={{state.canMove}}
            @readOnly={{state.readOnly}}
            @sort={{state.sort}}
            @onSortChange={{state.onSortChange}}
            @registerApi={{state.registerApi}}
            @height={{400}}
          />
        </div>
      </template>
    );
  }

  test('RD1 no grip by default; with @canMove; none with a @sort or @readOnly', async function (assert) {
    const state = new State();
    state.canMove = false;
    await renderSheet(state);
    assert.strictEqual(grips(), 0, 'off by default');
    state.canMove = true;
    await settled();
    assert.strictEqual(grips(), 6, 'one per record');
    assert
      .dom(grip(0))
      .hasAttribute('aria-hidden', 'true')
      .hasAttribute('title', 'Drag to move the record')
      .doesNotHaveAttribute('tabindex');
    assert
      .dom('[data-test-subj=euiSheetRowAdd]')
      .exists('the add row keeps its "+", no grip');
    state.sort = [{ field: 'name', direction: 'asc' }];
    await settled();
    assert.strictEqual(grips(), 0, 'a sort: no grip');
    state.sort = [];
    await settled();
    assert.strictEqual(grips(), 6, 'an empty sort: the grip is back');
    state.readOnly = true;
    await settled();
    assert.strictEqual(grips(), 0, 'read-only: no grip');
  });

  test('RD2 drag row 2 below row 5: one move after row 5, from row 1', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await dragRow(1, 4, 'lower');
    assert.strictEqual(state.changes.length, 1, 'one change set');
    const [set] = state.changes;
    assert.strictEqual(set!.source, 'move');
    assert.deepEqual(set!.patches, []);
    assert.deepEqual(set!.inserts, []);
    assert.deepEqual(set!.moves, [
      {
        recordId: 'r1',
        anchor: { recordId: 'r4', position: 'after' },
        from: { after: 'r0' }
      }
    ]);
    assert.strictEqual(order(state.store.records), '023415');
    assert.strictEqual(shown(6), '023415', 'drawn in the new order');
    assert.strictEqual(line(), null, 'no line after the drop');
    assert.dom(rowNumberCell(4)).hasClass('euiSheet__rowCell--selected');
    assert.dom(rowNumberCell(4)).isFocused('focus on the moved row');
  });

  test('RD3 localRecords applies it; Ctrl+Z moves it back; redo again', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await dragRow(4, 0, 'upper');
    assert.strictEqual(order(state.store.records), '401235');
    await pressed('z', { ctrlKey: true });
    assert.strictEqual(order(state.store.records), '012345', 'undone');
    assert.strictEqual(state.changes[1]!.source, 'undo');
    assert.dom(rowNumberCell(4)).isFocused('focus follows it back');
    await pressed('Z', { ctrlKey: true, shiftKey: true });
    assert.strictEqual(order(state.store.records), '401235', 'redone');
    assert.strictEqual(state.changes[2]!.source, 'redo');
    assert.strictEqual(shown(6), '401235');
  });

  test('RD4 checked rows drag together and keep their order; undo restores them', async function (assert) {
    const cases: Array<[string, number[], number, string]> = [
      ['adjacent', [1, 2, 3], 5, '045123'],
      ['not adjacent', [1, 3, 4], 5, '025134'],
      ['one is the first record', [0, 2, 3], 5, '145023']
    ];
    for (const [name, checked, to, expected] of cases) {
      const state = new State();
      await renderSheet(state);
      for (const row of checked) {
        await click(
          el('[data-test-subj=euiSheetRowCheck]', rowNumberCell(row))
        );
      }
      await dragRow(checked[1]!, to, 'lower');
      assert.strictEqual(
        order(state.store.records),
        expected,
        `${name}: moved`
      );
      assert.strictEqual(
        state.changes[0]!.moves!.length,
        3,
        `${name}: three moves in one set`
      );
      await pressed('z', { ctrlKey: true });
      assert.strictEqual(
        order(state.store.records),
        '012345',
        `${name}: undo restores the order`
      );
    }
  });

  test('RD5 a drop on its own place emits nothing; Escape cancels', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await dragRow(2, 2, 'lower');
    await dragRow(2, 1, 'lower');
    assert.deepEqual(state.changes, [], 'below itself, below the row above');
    // Escape during a drag
    await pressGrip(1);
    const point = pointOn(4, 'lower');
    await mouseAt('mousemove', point.x, point.y);
    assert.ok(line(), 'the line is drawn');
    assert.dom('.euiSheet').hasClass('euiSheet--rowDragging');
    assert.dom(rowNumberCell(1)).hasClass('euiSheet__rowCell--moving');
    assert.dom(cell(1, 1)).hasClass('euiSheet__rowCell--moving');
    document.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })
    );
    await settled();
    assert.strictEqual(line(), null, 'Escape removes the line');
    assert.dom('.euiSheet').doesNotHaveClass('euiSheet--rowDragging');
    assert.dom(rowNumberCell(1)).doesNotHaveClass('euiSheet__rowCell--moving');
    await mouseAt('mouseup', point.x, point.y);
    assert.deepEqual(
      state.changes,
      [],
      'the release after Escape emits nothing'
    );
    assert.strictEqual(order(state.store.records), '012345');
  });

  test('RD6 Alt+Shift+ArrowDown on a row number moves it one down; at the last record nothing', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await focus(rowNumberCell(1));
    assert.true(await pressed('ArrowDown', { altKey: true, shiftKey: true }));
    assert.strictEqual(order(state.store.records), '021345');
    assert.deepEqual(state.changes[0]!.moves, [
      {
        recordId: 'r1',
        anchor: { recordId: 'r2', position: 'after' },
        from: { after: 'r0' }
      }
    ]);
    assert.dom(rowNumberCell(2)).isFocused('focus moves with the record');
    await pressed('ArrowDown', { altKey: true, shiftKey: true });
    assert.strictEqual(order(state.store.records), '023145', 'again');
    await pressed('ArrowUp', { altKey: true, shiftKey: true });
    assert.strictEqual(order(state.store.records), '021345', 'and up');
    await focus(rowNumberCell(5));
    assert.true(
      await pressed('ArrowDown', { altKey: true, shiftKey: true }),
      'taken'
    );
    assert.strictEqual(state.changes.length, 3, 'the last record: nothing');
    await focus(rowNumberCell(0));
    await pressed('ArrowUp', { altKey: true, shiftKey: true });
    assert.strictEqual(state.changes.length, 3, 'the first record: nothing');
    // without @canMove the keys are not the sheet's
    state.canMove = false;
    await settled();
    await focus(rowNumberCell(2));
    await pressed('ArrowDown', { altKey: true, shiftKey: true });
    assert.strictEqual(state.changes.length, 3, 'off without @canMove');
  });

  test('RD10 the insertion line is drawn between the rows under the pointer; auto-scroll near the edge', async function (assert) {
    const queue: Array<FrameRequestCallback | null> = [];
    const original = { ...autoScrollFrames };
    autoScrollFrames.request = (callback) => {
      queue.push(callback);
      return queue.length;
    };
    autoScrollFrames.cancel = (id) => {
      queue[id - 1] = null;
    };
    try {
      const state = new State();
      state.store = localRecords<Row>(rows(200), {
        getRecordId: getId,
        fields: FIELDS
      });
      await renderSheet(state);
      await pressGrip(1);
      const point = pointOn(3, 'lower');
      await mouseAt('mousemove', point.x, point.y);
      const drawn = line()!;
      assert.ok(drawn, 'drawn');
      const rowBox = cell(3, 0).getBoundingClientRect();
      const box = drawn.getBoundingClientRect();
      assert.ok(
        Math.abs(box.top + box.height / 2 - rowBox.bottom) < 2,
        `at row 3's bottom edge (${box.top} + ${box.height} / 2 vs ${rowBox.bottom})`
      );
      const grid = el('.euiSheet__grid').getBoundingClientRect();
      assert.ok(
        Math.abs(box.left - grid.left) < 1,
        'from the grid’s left edge'
      );
      assert.ok(Math.abs(box.width - grid.width) < 1, 'as wide as the grid');
      const upper = pointOn(3, 'upper');
      await mouseAt('mousemove', upper.x, upper.y);
      assert.ok(
        Math.abs(
          line()!.getBoundingClientRect().top +
            line()!.getBoundingClientRect().height / 2 -
            rowBox.top
        ) < 2,
        'the upper half: at its top edge'
      );

      // under the grid: the loop scrolls and the line follows
      const outer = el('.euiDataGrid__virtualized');
      const bottom = outer.getBoundingClientRect().bottom;
      await mouseAt('mousemove', point.x, bottom + 30);
      assert.strictEqual(queue.filter(Boolean).length, 1, 'the loop started');
      for (let i = 0; i < 10; i++) {
        const now = queue.splice(0, queue.length);
        queue.push(...now.map(() => null));
        for (const callback of now) callback?.(performance.now());
        await settled();
      }
      assert.true(outer.scrollTop > 50, `scrolled to ${outer.scrollTop}`);
      const lineBox = line()!.getBoundingClientRect();
      assert.ok(
        lineBox.top <= outer.getBoundingClientRect().bottom,
        `the line stays in the grid (${lineBox.top} vs ${outer.getBoundingClientRect().bottom})`
      );
      await mouseAt('mouseup', point.x, bottom + 30);
      assert.strictEqual(queue.filter(Boolean).length, 0, 'stopped');
      assert.strictEqual(state.changes.length, 1, 'dropped further down');
      const moved = state.changes[0]!.moves![0]!;
      assert.strictEqual(moved.recordId, 'r1');
      assert.true(
        Number(String(moved.anchor!.recordId).slice(1)) > 5,
        `after ${moved.anchor!.recordId}`
      );
    } finally {
      autoScrollFrames.request = original.request;
      autoScrollFrames.cancel = original.cancel;
    }
  });

  test('RD12 api.moveRecords emits the same set; nothing without @canMove', async function (assert) {
    const state = new State();
    await renderSheet(state);
    state.api!.moveRecords(['r0', 'r1'], { recordId: 'r3', position: 'after' });
    await settled();
    assert.strictEqual(order(state.store.records), '230145');
    assert.deepEqual(state.changes[0]!.moves, [
      {
        recordId: 'r0',
        anchor: { recordId: 'r3', position: 'after' },
        from: {}
      },
      {
        recordId: 'r1',
        anchor: { recordId: 'r0', position: 'after' },
        from: { after: 'r0' }
      }
    ]);
    // undoable like a drag
    await focus(cell(0, 0));
    await pressed('z', { ctrlKey: true });
    assert.strictEqual(order(state.store.records), '012345');
    state.api!.moveRecords(['r0'], { recordId: 'r0', position: 'after' });
    assert.strictEqual(state.changes.length, 2, 'onto itself: nothing');
    state.canMove = false;
    await settled();
    state.api!.moveRecords(['r0'], { recordId: 'r5', position: 'after' });
    assert.strictEqual(state.changes.length, 2, 'without @canMove: nothing');
  });

  module('with groups', function () {
    /** Status groups: grid rows 0 Done header, 1-3 r3-r5, 4 add, 5 Open header, 6-8 r0-r2, 9 add. */
    class Grouped {
      store = localRecords<Row>(rows(), {
        getRecordId: getId,
        fields: FIELDS,
        groupBy: [{ field: 'status', direction: 'asc' }] as SheetGroupBy[]
      });
      @tracked fields: EuiSheetField<Row>[] = FIELDS;
      changes: ChangeSet[] = [];
      onChange = (changeSet: ChangeSet) => {
        this.changes.push(changeSet);
        this.store.apply(changeSet);
      };
    }

    async function renderGrouped(state: Grouped): Promise<void> {
      await render(
        <template>
          <div style="width:500px">
            <EuiSheet
              @fields={{state.fields}}
              @records={{state.store.view.records}}
              @groups={{state.store.view.groups}}
              @groupBy={{state.store.groupBy}}
              @onGroupToggle={{state.store.toggleGroup}}
              @getRecordId={{getId}}
              @onChange={{state.onChange}}
              @canMove={{true}}
              @height={{500}}
            />
          </div>
        </template>
      );
    }

    const statuses = (store: Grouped['store']) =>
      store.records.map((record) => `${record.id}:${record.status}`).join(' ');

    test('RD7 a drag into another group adds the patch of the group field and groupKey; undo restores both', async function (assert) {
      const state = new Grouped();
      await renderGrouped(state);
      // r4 (Done, grid row 2) below r0 (Open, grid row 6)
      await dragRow(2, 6, 'lower');
      assert.strictEqual(state.changes.length, 1);
      const set = state.changes[0]!;
      assert.strictEqual(set.source, 'move');
      assert.deepEqual(set.patches, [
        { recordId: 'r4', fieldId: 'status', from: 'Done', to: 'Open' }
      ]);
      assert.deepEqual(set.moves, [
        {
          recordId: 'r4',
          anchor: { recordId: 'r0', position: 'after' },
          groupKey: state.store.view.groups[1]!.key,
          from: { after: 'r3', groupKey: state.store.view.groups[0]!.key }
        }
      ]);
      assert.deepEqual(
        state.store.view.records.map(getId),
        ['r3', 'r5', 'r0', 'r4', 'r1', 'r2'],
        'r4 is second in Open'
      );
      await pressed('z', { ctrlKey: true });
      assert.strictEqual(state.changes[1]!.source, 'undo');
      assert.strictEqual(
        statuses(state.store),
        'r0:Open r1:Open r2:Open r3:Done r4:Done r5:Done',
        'the group field is back'
      );
      assert.deepEqual(
        state.store.view.records.map(getId),
        ['r3', 'r4', 'r5', 'r0', 'r1', 'r2'],
        'and the place'
      );
    });

    test('RD8 a drop on a collapsed header has groupKey and no anchor', async function (assert) {
      const state = new Grouped();
      await renderGrouped(state);
      const open = state.store.view.groups[1]!.key;
      state.store.toggleGroup(open, true);
      await settled();
      // 0 Done header, 1-3 r3-r5, 4 add, 5 Open header (collapsed)
      await pressGrip(1);
      const point = center(rowNumberCell(5));
      await mouseAt('mousemove', point.x, point.y);
      assert
        .dom('[data-test-subj=euiSheetDropLine]')
        .hasClass('euiSheet__dropLine--box', 'a box around the header');
      await mouseAt('mouseup', point.x, point.y);
      const set = state.changes[0]!;
      assert.deepEqual(set.moves, [
        {
          recordId: 'r3',
          groupKey: open,
          from: { groupKey: state.store.view.groups[0]!.key }
        }
      ]);
      assert.deepEqual(set.patches, [
        { recordId: 'r3', fieldId: 'status', from: 'Done', to: 'Open' }
      ]);
      assert.strictEqual(
        state.store.view.groups[1]!.count,
        4,
        'Open counts it'
      );
    });

    test('RD9 a record whose group field is read-only cannot be dropped in another group', async function (assert) {
      const state = new Grouped();
      state.fields = [
        FIELDS[0]!,
        { ...FIELDS[1]!, readOnly: (record: Row) => record.id === 'r4' }
      ];
      await renderGrouped(state);
      await pressGrip(2);
      const point = pointOn(6, 'lower');
      await mouseAt('mousemove', point.x, point.y);
      assert
        .dom('[data-test-subj=euiSheetDropLine]')
        .hasClass('euiSheet__dropLine--blocked');
      assert.dom('.euiSheet').hasClass('euiSheet--rowDragBlocked');
      await mouseAt('mouseup', point.x, point.y);
      assert.deepEqual(state.changes, [], 'no change set');
      // inside its own group it may still move
      await dragRow(2, 3, 'lower');
      assert.strictEqual(state.changes.length, 1, 'within Done');
      assert.deepEqual(state.changes[0]!.patches, []);
    });
  });
});
