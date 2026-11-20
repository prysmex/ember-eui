/**
 * Stepping through search matches (V03 11.1, SN1-SN4, SN6, SN7):
 * `@currentMatch` scrolls the owner's match into view and rings it
 * without taking focus from the search box; `api.scrollToCell`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  fillIn,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  builtInFieldTypes,
  defaultMessages,
  findMatches,
  groupRecords
} from '#src/core/index.ts';
import { cell, el, selected } from '../../helpers/sheet.ts';

import type { EuiSheetField, RecordId } from '#src/core/index.ts';
import type { SheetApi } from '#src/types.ts';

type Row = Record<string, string | number>;
type Match = { recordId: RecordId; fieldId: string };

const fieldsOf = (count: number, width = 150): EuiSheetField<Row>[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `f${i}`,
    label: `Field ${i}`,
    width
  }));

const rowsOf = (count: number, fields: number): Row[] =>
  Array.from({ length: count }, (_, r) => {
    const row: Row = { id: r };
    for (let f = 0; f < fields; f++) row[`f${f}`] = `r${r}c${f}`;
    return row;
  });

const getId = (row: Row) => row['id']!;

class State {
  @tracked records: Row[] = rowsOf(200, 12);
  @tracked fields = fieldsOf(12);
  @tracked currentMatch: Match | null = null;
  @tracked frozenFields = 0;
  api: SheetApi | null = null;
  register = (api: SheetApi) => (this.api = api);
  onChange = () => {};
}

const MATCH = 'euiSheet__cell--match';

function matched(): string[] {
  return Array.from(document.querySelectorAll<HTMLElement>(`.${MATCH}`)).map(
    (element) =>
      `${element.dataset['gridcellVisibleRowIndex']}:${Number(element.dataset['gridcellColumnIndex']) - 1}`
  );
}

function outer(): HTMLElement {
  return el('.euiDataGrid__virtualized');
}

/** The cell, when it is rendered and fully inside the grid body (below the header). */
function inView(row: number, col: number): HTMLElement | null {
  const element = document.querySelector<HTMLElement>(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="${col + 1}"]`
  );
  if (!element) return null;
  const scroller = outer();
  const box = scroller.getBoundingClientRect();
  const header = el('[data-test-subj=dataGridHeader]', scroller);
  const own = element.getBoundingClientRect();
  const inside =
    own.top >= header.getBoundingClientRect().bottom - 1 &&
    own.bottom <= box.top + scroller.clientHeight + 1 &&
    own.left >= box.left - 1 &&
    own.right <= box.left + scroller.clientWidth + 1;
  return inside ? element : null;
}

module(
  'Integration | Component | EuiSheet search navigation',
  function (hooks) {
    setupRenderingTest(hooks);

    hooks.beforeEach(function () {
      document.getElementById('ember-testing-container')?.scrollIntoView();
    });

    async function renderSheet(state: State): Promise<void> {
      await render(
        <template>
          <div style="width:600px">
            <EuiSheet
              @fields={{state.fields}}
              @records={{state.records}}
              @getRecordId={{getId}}
              @onChange={{state.onChange}}
              @currentMatch={{state.currentMatch}}
              @frozenFields={{state.frozenFields}}
              @registerApi={{state.register}}
              @height={{400}}
            >
              <:toolbar>
                <input data-test-search aria-label="Search" />
              </:toolbar>
            </EuiSheet>
          </div>
        </template>
      );
    }

    test('SN1 @currentMatch on a rendered cell: the ring; focus stays in the toolbar', async function (assert) {
      const state = new State();
      await renderSheet(state);
      const input = el('[data-test-search]');
      await focus(input);
      state.currentMatch = { recordId: 2, fieldId: 'f1' };
      await settled();
      assert.deepEqual(matched(), ['2:1']);
      assert.strictEqual(
        document.activeElement,
        input,
        'the input keeps focus'
      );
      assert.deepEqual(selected(), [], 'no selection');
      const ring = getComputedStyle(cell(2, 1), '::after');
      assert.true(
        ring.boxShadow.includes('inset') && ring.boxShadow.includes('2px'),
        `a 2 px inset ring (${ring.boxShadow})`
      );
      assert.strictEqual(ring.pointerEvents, 'none');
      state.currentMatch = { recordId: 3, fieldId: 'f0' };
      await settled();
      assert.deepEqual(matched(), ['3:0'], 'the ring moves');
      assert.strictEqual(document.activeElement, input);
    });

    test('SN2 a match far down and right is scrolled into view (10,000 records, 30 fields)', async function (assert) {
      const state = new State();
      state.records = rowsOf(10_000, 30);
      state.fields = fieldsOf(30);
      await renderSheet(state);
      const input = el('[data-test-search]');
      await focus(input);
      state.currentMatch = { recordId: 9000, fieldId: 'f25' };
      await settled();
      await waitUntil(() => inView(9000, 25), { timeout: 2000 });
      assert.ok(inView(9000, 25), 'rendered and inside the body');
      assert.true(cell(9000, 25).classList.contains(MATCH), 'ringed');
      assert.true(outer().scrollTop > 100_000, `scrolled ${outer().scrollTop}`);
      assert.strictEqual(document.activeElement, input, 'focus unchanged');
      // back near the top
      state.currentMatch = { recordId: 4, fieldId: 'f2' };
      await settled();
      await waitUntil(() => inView(4, 2), { timeout: 2000 });
      assert.ok(inView(4, 2));
      assert.strictEqual(document.activeElement, input);
    });

    test('SN3 with a frozen field the match is scrolled clear of it', async function (assert) {
      const state = new State();
      state.frozenFields = 1;
      await renderSheet(state);
      const scroller = outer();
      scroller.scrollLeft = 450;
      await triggerEvent(scroller, 'scroll');
      // field 2 is now under the frozen first field
      assert.true(
        cell(5, 2).getBoundingClientRect().left <
          cell(5, 0).getBoundingClientRect().right,
        'under the frozen field before'
      );
      state.currentMatch = { recordId: 5, fieldId: 'f2' };
      await settled();
      await waitUntil(
        () =>
          cell(5, 2).getBoundingClientRect().left >=
          cell(5, 0).getBoundingClientRect().right - 1,
        { timeout: 2000 }
      );
      assert.true(
        cell(5, 2).getBoundingClientRect().left >=
          cell(5, 0).getBoundingClientRect().right - 1,
        `its left edge is right of the frozen field (${cell(5, 2).getBoundingClientRect().left} vs ${cell(5, 0).getBoundingClientRect().right})`
      );
      assert.true(cell(5, 2).classList.contains(MATCH));
    });

    test('SN4 a record not in @records, a hidden field, null: nothing drawn', async function (assert) {
      const state = new State();
      await renderSheet(state);
      const scroller = outer();
      scroller.scrollTop = 300;
      await triggerEvent(scroller, 'scroll');
      const top = scroller.scrollTop;
      state.currentMatch = { recordId: 'nope', fieldId: 'f1' };
      await settled();
      assert.deepEqual(matched(), [], 'not in @records');
      state.currentMatch = { recordId: 12, fieldId: 'hidden' };
      await settled();
      assert.deepEqual(matched(), [], 'a field that is not shown');
      state.currentMatch = null;
      await settled();
      assert.deepEqual(matched(), [], 'null');
      assert.strictEqual(scroller.scrollTop, top, 'nothing scrolled');
      // the record arrives later (the owner changed the page): then it is shown
      state.currentMatch = { recordId: 'late', fieldId: 'f0' };
      await settled();
      state.records = [{ id: 'late', f0: 'x' }, ...state.records];
      await settled();
      assert.deepEqual(matched(), ['0:0'], 'shown once it is in @records');
    });

    test('SN7 api.scrollToCell scrolls without focus or a selection', async function (assert) {
      const state = new State();
      await renderSheet(state);
      const input = el('[data-test-search]');
      await focus(input);
      state.api!.scrollToCell({ recordId: 150, fieldId: 'f10' });
      await waitUntil(() => inView(150, 10), { timeout: 2000 });
      assert.ok(inView(150, 10), 'in view');
      assert.strictEqual(document.activeElement, input, 'focus unchanged');
      assert.deepEqual(selected(), [], 'no selection');
      assert.deepEqual(matched(), [], 'no ring: that is @currentMatch');
      // an unknown cell is a no-op
      const top = outer().scrollTop;
      state.api!.scrollToCell({ recordId: 'nope', fieldId: 'f1' });
      state.api!.scrollToCell({ recordId: 1, fieldId: 'nope' });
      await settled();
      assert.strictEqual(outer().scrollTop, top);
    });

    test('SN6 the demo wiring: Enter steps and wraps; a match in a collapsed group is expanded first', async function (assert) {
      interface Task {
        id: string;
        name: string;
        status: string;
      }
      const FIELDS: EuiSheetField<Task>[] = [
        { id: 'name', label: 'Name' },
        {
          id: 'status',
          label: 'Status',
          type: 'singleSelect',
          options: [
            { value: 'todo', label: 'To do' },
            { value: 'done', label: 'Done' }
          ]
        }
      ];
      const taskId = (task: Task) => task.id;
      const CTX = {
        types: builtInFieldTypes,
        messages: defaultMessages,
        getRecordId: taskId
      };

      class App {
        store = localRecords<Task>(
          [
            { id: 't1', name: 'Paint the fence', status: 'todo' },
            { id: 't2', name: 'Buy paint', status: 'done' },
            { id: 't3', name: 'Water the plants', status: 'todo' },
            { id: 't4', name: 'Paint the door', status: 'done' }
          ],
          {
            getRecordId: taskId,
            fields: FIELDS,
            groupBy: [{ field: 'status', direction: 'asc' }]
          }
        );
        @tracked term = '';
        @tracked index = 0;

        /** Every record in display order, collapsed groups' too. */
        get shown() {
          return groupRecords(CTX, this.store.records, {
            groupBy: this.store.groupBy,
            fields: FIELDS
          });
        }

        get matches() {
          return findMatches(CTX, this.shown.records, FIELDS, this.term);
        }

        get currentMatch() {
          return this.matches[this.index] ?? null;
        }

        /** The leaf group key of each record (the groups take their `loaded` records in order). */
        groupKeyOf(recordId: RecordId): string | undefined {
          let i = 0;
          const { records, groups } = this.shown;
          for (const group of groups) {
            for (let n = 0; n < (group.loaded ?? 0); n++) {
              if (records[i++]!.id === recordId) return group.key;
            }
          }
          return undefined;
        }

        step(by: number) {
          const count = this.matches.length;
          if (!count) return;
          this.index = (this.index + by + count) % count;
          const key = this.groupKeyOf(this.matches[this.index]!.recordId);
          if (key && this.store.collapsedGroups.has(key)) {
            this.store.toggleGroup(key, false);
          }
        }

        onInput = (event: Event) => {
          this.term = (event.target as HTMLInputElement).value;
          this.index = 0;
        };

        onKeyDown = (event: KeyboardEvent) => {
          if (event.key !== 'Enter') return;
          event.preventDefault();
          this.step(event.shiftKey ? -1 : 1);
        };
      }

      const app = new App();
      await render(
        <template>
          <EuiSheet
            @fields={{app.store.fields}}
            @records={{app.store.view.records}}
            @groups={{app.store.view.groups}}
            @groupBy={{app.store.groupBy}}
            @onGroupToggle={{app.store.toggleGroup}}
            @getRecordId={{taskId}}
            @onChange={{app.store.apply}}
            @highlight={{app.term}}
            @currentMatch={{app.currentMatch}}
            @height={{300}}
          >
            <:toolbar>
              <input
                data-test-search
                aria-label="Search"
                {{on "input" app.onInput}}
                {{on "keydown" app.onKeyDown}}
              />
            </:toolbar>
          </EuiSheet>
        </template>
      );
      // groups in option order: To do (t1, t3), then Done (t2, t4); collapse Done
      const done = app.groupKeyOf('t2')!;
      app.store.toggleGroup(done, true);
      await settled();
      const searchBox = el('[data-test-search]');
      await fillIn(searchBox, 'PAINT');
      // display order: t1 "Paint the fence", t2 "Buy paint", t4 "Paint the door"
      assert.deepEqual(
        app.matches.map((m) => m.recordId),
        ['t1', 't2', 't4']
      );
      // header To do (0), t1 (1), t3 (2), its add row (3), header Done (4)
      assert.deepEqual(matched(), ['1:0'], 'the first match');
      // an owner that does not expand: a match in a collapsed group draws nothing
      app.index = 1;
      await settled();
      assert.deepEqual(matched(), [], 't2 is in a collapsed group');
      await triggerKeyEvent(searchBox, 'keydown', 'Enter', { shiftKey: true });
      assert.deepEqual(matched(), ['1:0'], 'Shift+Enter: back to t1');
      await triggerKeyEvent(searchBox, 'keydown', 'Enter');
      assert.strictEqual(app.index, 1);
      assert.false(
        app.store.collapsedGroups.has(done),
        'the app expanded the group'
      );
      // ... header Done (4), t2 (5), t4 (6)
      assert.deepEqual(matched(), ['5:0'], 't2 is shown and ringed');
      assert.strictEqual(
        document.activeElement,
        searchBox,
        'the input keeps focus'
      );
      await triggerKeyEvent(searchBox, 'keydown', 'Enter');
      assert.deepEqual(matched(), ['6:0'], 't4');
      await triggerKeyEvent(searchBox, 'keydown', 'Enter');
      assert.strictEqual(app.index, 0, 'wraps to the first');
      assert.deepEqual(matched(), ['1:0'], 't1');
      await triggerKeyEvent(searchBox, 'keydown', 'Enter', { shiftKey: true });
      assert.deepEqual(matched(), ['6:0'], 'Shift+Enter steps back and wraps');
      assert.strictEqual(document.activeElement, searchBox);
    });
  }
);
