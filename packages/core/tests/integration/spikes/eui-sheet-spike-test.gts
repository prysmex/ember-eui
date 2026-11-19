/**
 * EuiSheet spike integration tests (internal/spikes/sheet/DESIGN.md, 7.2).
 * Every case runs once per cursor source in SOURCES.
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
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '../../spikes/sheet/eui-sheet.gts';
import { localRecords } from '../../spikes/sheet/local-records.ts';

import type { CursorSource } from '../../spikes/sheet/eui-sheet.gts';
import type { EuiSheetField } from '../../spikes/sheet/change-set.ts';

// The cell-api hook was dropped (RESULTS.md section 7). After applying
// internal/spikes/sheet/cell-api.patch, run with ['api', 'dom'] again.
const SOURCES: readonly CursorSource[] = ['dom'];

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

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function cell(row: number, col: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="${col}"]`
  );
}

function text(row: number, col: number): string {
  return (
    cell(row, col)
      .querySelector('[data-datagrid-cellcontent]')
      ?.textContent?.trim() ?? ''
  );
}

function editor(): HTMLInputElement | null {
  return document.querySelector<HTMLInputElement>(
    '[data-test-subj=euiSheetEditor] input'
  );
}

function selected(): string[] {
  return Array.from(
    document.querySelectorAll<HTMLElement>('.euiSheetSpike__cell--selected')
  )
    .map(
      (element) =>
        `${element.dataset['gridcellVisibleRowIndex']}:${element.dataset['gridcellColumnIndex']}`
    )
    .sort();
}

async function press(
  key: string,
  modifiers: { shiftKey?: boolean; ctrlKey?: boolean } = {}
) {
  await triggerKeyEvent(
    document.activeElement as HTMLElement,
    'keydown',
    key,
    modifiers
  );
}

/** A printable key: a key code, so the event's `key` is lowercase like a real press. */
async function type(char: string) {
  await triggerKeyEvent(
    document.activeElement as HTMLElement,
    'keydown',
    char.toUpperCase().charCodeAt(0)
  );
}

/** `focus()` already waits for `settled()`. */
async function focusCell(row: number, col: number) {
  await focus(cell(row, col));
}

async function clipboard(kind: 'copy' | 'paste', value = '') {
  const clipboardData = new DataTransfer();
  if (value) clipboardData.setData('text/plain', value);
  const event = new ClipboardEvent(kind, {
    clipboardData,
    bubbles: true,
    cancelable: true
  });
  document.activeElement!.dispatchEvent(event);
  await settled();
  return {
    text: clipboardData.getData('text/plain'),
    prevented: event.defaultPrevented
  };
}

async function scrollTo(top: number) {
  const outer = el('.euiDataGrid__virtualized');
  outer.scrollTop = top;
  await triggerEvent(outer, 'scroll');
}

module('Integration | Spike | EuiSheet', function (hooks) {
  setupRenderingTest(hooks);

  for (const source of SOURCES) {
    module(`cursor source: ${source}`, function () {
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
                @cursorSource={{source}}
                @height={{height}}
              />
            </div>
          </template>
        );
        return store;
      }

      test(`T1 type-to-edit, Enter saves and moves down (${source})`, async function (assert) {
        const store = await renderSheet();
        await focusCell(1, 0);
        await type('x');
        assert.ok(editor(), 'editor exists');
        assert.strictEqual(editor()?.value, 'x');
        assert.strictEqual(
          document.activeElement,
          editor(),
          'editor is focused'
        );

        await fillIn(editor()!, 'xy');
        await press('Enter');
        assert.strictEqual(editor(), null, 'no editor');
        assert.strictEqual(text(1, 0), 'xy');
        assert.deepEqual(store.log, [
          {
            source: 'edit',
            patches: [
              { recordId: 'r1', fieldId: 'name', from: 'name1', to: 'xy' }
            ],
            inserts: []
          }
        ]);
        await waitUntil(() => document.activeElement === cell(2, 0));
        assert.strictEqual(document.activeElement, cell(2, 0));
        await settled();
        assert.deepEqual(selected(), ['2:0']);
      });

      test(`T2 Enter and F2 edit the current value, Esc cancels (${source})`, async function (assert) {
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

      test(`T3 Tab saves and moves right, Shift+Tab left, clamps (${source})`, async function (assert) {
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

      test(`T4 Shift+arrows select a range, Delete clears it (${source})`, async function (assert) {
        const store = await renderSheet();
        await focusCell(1, 0);
        await press('ArrowDown', { shiftKey: true });
        await press('ArrowRight', { shiftKey: true });
        await settled();
        assert.deepEqual(selected(), ['1:0', '1:1', '2:0', '2:1']);
        assert.strictEqual(document.activeElement, cell(2, 1));

        await press('Delete');
        await settled();
        assert.deepEqual(
          [text(1, 0), text(1, 1), text(2, 0), text(2, 1)],
          ['', '', '', '']
        );
        assert.deepEqual(store.log, [
          {
            source: 'clear',
            patches: [
              { recordId: 'r1', fieldId: 'name', from: 'name1', to: '' },
              { recordId: 'r1', fieldId: 'city', from: 'city1', to: '' },
              { recordId: 'r2', fieldId: 'name', from: 'name2', to: '' },
              { recordId: 'r2', fieldId: 'city', from: 'city2', to: '' }
            ],
            inserts: []
          }
        ]);
        assert.strictEqual(text(3, 0), 'name3', '(3, 0) unchanged');

        await press('ArrowDown');
        await settled();
        assert.deepEqual(selected(), ['3:1']);
      });

      test(`T5 copy gives the range as TSV (${source})`, async function (assert) {
        await renderSheet();
        await focusCell(1, 0);
        await press('ArrowDown', { shiftKey: true });
        await press('ArrowRight', { shiftKey: true });
        await settled();

        let result = await clipboard('copy');
        assert.strictEqual(result.text, 'name1\tcity1\nname2\tcity2');
        assert.true(result.prevented);

        // with a text selection the grid's onTabularCopy would rewrite it (F5).
        // The whole grid is selected so the selection holds the copy markers
        // that handler acts on (one cell's content holds none).
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

      test(`T6 paste a 2x3 block at the last row inserts a row (${source})`, async function (assert) {
        const store = await renderSheet();
        await focusCell(4, 0);
        const result = await clipboard('paste', 'a\tb\tc\r\nd\te\tf\r\n');
        assert.true(result.prevented);
        assert.strictEqual(store.log.length, 1);
        const changeSet = store.log[0]!;
        assert.strictEqual(changeSet.source, 'paste');
        assert.deepEqual(changeSet.patches, [
          { recordId: 'r4', fieldId: 'name', from: 'name4', to: 'a' },
          { recordId: 'r4', fieldId: 'city', from: 'city4', to: 'b' },
          { recordId: 'r4', fieldId: 'qty', from: '4', to: 'c' }
        ]);
        assert.strictEqual(changeSet.inserts.length, 1);
        assert.strictEqual(changeSet.inserts[0]!.index, 5);
        assert.deepEqual(changeSet.inserts[0]!.values, {
          name: 'd',
          city: 'e',
          qty: 'f'
        });

        await settled();
        assert.dom('[role=grid]').hasAttribute('aria-rowcount', '6');
        assert.deepEqual([text(5, 0), text(5, 1), text(5, 2)], ['d', 'e', 'f']);
        assert.deepEqual(selected(), [
          '4:0',
          '4:1',
          '4:2',
          '5:0',
          '5:1',
          '5:2'
        ]);
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

      test(`T7 the selection class survives virtualization (${source})`, async function (assert) {
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
        const renderedCells =
          document.querySelectorAll('[role=gridcell]').length;
        console.info(
          `[sheet-spike] T7 (${source}): Shift+ArrowDown -> settled() ${ms.toFixed(1)} ms, ${renderedCells} rendered cells`
        );
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

        assert.strictEqual(
          document.activeElement,
          document.body,
          'focus left with the unmounted cell'
        );

        await scrollTo(0);
        await settled();
        await waitUntil(() => document.activeElement === cell(4, 1));
        assert.strictEqual(
          document.activeElement,
          cell(4, 1),
          'the re-mounted focused cell took focus again (F6)'
        );
        assert.deepEqual(selected(), expected, 'selection is back');
      });

      test(`T8 the grid's Enter/F2 popover stays closed (${source})`, async function (assert) {
        await renderSheet({
          fields: FIELDS.map((field) => ({ ...field, isExpandable: true }))
        });
        await focusCell(1, 1);
        assert
          .dom('[data-test-subj=euiDataGridCellExpandButton]', cell(1, 1))
          .exists(
            'the cell is expandable: without the sheet Enter opens the popover'
          );
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

      test(`T9 clicking another cell commits and does not steal focus (${source})`, async function (assert) {
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

      test(`T10 scrolling while editing commits without a focus fight (${source})`, async function (assert) {
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

      test(`T11 the editor is outside the grid and tabbable (${source})`, async function (assert) {
        await renderSheet();
        await focusCell(0, 0);
        await press('Enter');
        await settled();
        const input = editor()!;
        assert.ok(input, 'editor');
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
        const close = (x: number, y: number) => Math.abs(x - y) <= 1;
        assert.true(
          close(a.top, b.top) &&
            close(a.left, b.left) &&
            close(a.width, b.width) &&
            close(a.height, b.height),
          `editor box ${JSON.stringify(a)} matches cell box ${JSON.stringify(b)}`
        );
      });

      test(`T12 arrows while editing do not move grid focus (${source})`, async function (assert) {
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

      test(`T13 header cells keep their keys (${source})`, async function (assert) {
        const store = await renderSheet();
        await focus('[role=columnheader][data-gridcell-column-index="0"]');
        await type('x');
        await press('Delete');
        const result = await clipboard('paste', 'a');
        assert.strictEqual(editor(), null, 'no editor');
        assert.strictEqual(store.log.length, 0);
        assert.false(result.prevented, 'paste not prevented');
      });

      test(`T14 read-only fields (${source})`, async function (assert) {
        const store = await renderSheet({
          fields: [
            { id: 'name' },
            { id: 'city', readOnly: true },
            { id: 'qty' }
          ]
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

      test(`T15 Enter on the last row keeps focus there (${source})`, async function (assert) {
        await renderSheet();
        await focusCell(4, 0);
        await type('z');
        await press('Enter');
        await settled();
        assert.strictEqual(text(4, 0), 'z');
        await waitUntil(() => document.activeElement === cell(4, 0));
        assert.strictEqual(document.activeElement, cell(4, 0));
      });

      // Found with trusted events in Chromium (Playwright): after a click, a
      // real copy/paste is dispatched on the cell's content element, where the
      // browser's selection is, not on the focused cell.
      test(`T16 copy and paste dispatched on the cell content (${source})`, async function (assert) {
        const store = await renderSheet();
        await focusCell(1, 0);
        const content = (row: number, col: number) =>
          cell(row, col).querySelector<HTMLElement>(
            '[data-datagrid-cellcontent]'
          )!;
        const dispatch = async (
          target: HTMLElement,
          kind: 'copy' | 'paste',
          value = ''
        ) => {
          const clipboardData = new DataTransfer();
          if (value) clipboardData.setData('text/plain', value);
          const event = new ClipboardEvent(kind, {
            clipboardData,
            bubbles: true,
            cancelable: true
          });
          target.dispatchEvent(event);
          await settled();
          return {
            text: clipboardData.getData('text/plain'),
            prevented: event.defaultPrevented
          };
        };

        const copied = await dispatch(content(1, 0), 'copy');
        assert.true(copied.prevented, 'copy handled by the sheet');
        assert.strictEqual(copied.text, 'name1');

        const pasted = await dispatch(content(1, 0), 'paste', 'a\tb\nc\td');
        assert.true(pasted.prevented, 'paste handled by the sheet');
        assert.strictEqual(store.log.length, 1);
        assert.deepEqual(
          [text(1, 0), text(1, 1), text(2, 0), text(2, 1)],
          ['a', 'b', 'c', 'd']
        );
      });
    });
  }

  // Manual check on the Mac (DESIGN.md 8.4, R12): `pnpm test:dev`, then open
  // /tests/index.html?filter=demo&sheetdemo in Chrome, Firefox and Safari.
  test('demo (manual)', async function (assert) {
    if (!location.search.includes('sheetdemo')) {
      assert.true(true, 'paused only with ?sheetdemo');
      return;
    }
    // ?sheetdemo uses the dom source (no hook); ?sheetdemo=api needs
    // internal/spikes/sheet/cell-api.patch applied
    const demoSource: CursorSource =
      new URLSearchParams(location.search).get('sheetdemo') === 'api'
        ? 'api'
        : 'dom';
    const store = localRecords(people(50), { getRecordId: getId });
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @cursorSource={{demoSource}}
            @height={{400}}
          />
        </div>
      </template>
    );
    // the manual check of DESIGN.md 8.4 pauses here, only with ?sheetdemo
    // eslint-disable-next-line ember/no-pause-test
    await this.pauseTest();
    assert.true(true);
  });
});
