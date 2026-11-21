/**
 * Keys of the row-number column found by the accessibility stage
 * (READINESS-RESULTS.md, "Accessibility", "Left, and why"): PageUp and
 * PageDown on a row-number cell of a sheet without groups kept focus only
 * while nothing scrolled (the browser's page scroll took the focused row
 * out of the rendered rows, and focus went to `<body>`); the header's
 * "check all" worked only with the mouse. RNK1-RNK4.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { focus, render, settled, waitUntil } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { el, pressed, selected } from '../../helpers/sheet.ts';

import type { EuiSheetField, RecordId } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
}

const FIELDS: EuiSheetField<Row>[] = [{ id: 'name', label: 'Name' }];

const rows = (count: number): Row[] =>
  Array.from({ length: count }, (_, i) => ({ id: `r${i}`, name: `name${i}` }));

const getId = (row: Row) => row.id;

class State {
  @tracked records: Row[] = rows(100);
  @tracked checked: RecordId[] | undefined = undefined;
  onCheckedChange: ((ids: RecordId[]) => void) | undefined = undefined;
  onChange = () => {};
}

function rowNumberCell(row: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-column-id=euiSheetRow][data-gridcell-visible-row-index="${row}"]`
  );
}

function header(): HTMLElement {
  return el('[role=columnheader][data-gridcell-column-id=euiSheetRow]');
}

/** The focused row-number cell's row, or null when focus is elsewhere. */
function focusedRow(): number | null {
  const active = document.activeElement;
  if (!(active instanceof HTMLElement)) return null;
  if (active.dataset['gridcellColumnId'] !== 'euiSheetRow') return null;
  const row = active.dataset['gridcellVisibleRowIndex'];
  return row === undefined ? null : Number(row);
}

/**
 * A page key on the focused row number; true when the sheet took it. Then
 * waits (up to 1 s) for focus to move off `from` (the grid focuses the
 * new cell after it renders); at an end it stays.
 */
async function page(
  key: 'PageDown' | 'PageUp',
  modifiers: { shiftKey?: boolean } = {}
): Promise<boolean> {
  const from = focusedRow();
  const taken = await pressed(key, modifiers);
  try {
    await waitUntil(() => focusedRow() !== from, { timeout: 1000 });
  } catch {
    // at an end (or not taken): the assertions say what is off
  }
  await settled();
  return taken;
}

function scrollTop(): number {
  return el('.euiDataGrid__virtualized').scrollTop;
}

function stateText(): string {
  return (
    el('[data-test-subj=euiSheetRowCheckAllState]').textContent?.trim() ?? ''
  );
}

function checkedLabels(): string[] {
  return Array.from(
    document.querySelectorAll<HTMLElement>(
      '[role=gridcell][data-gridcell-column-id=euiSheetRow]'
    )
  )
    .map((cell) => cell.getAttribute('aria-label') ?? '')
    .filter((label) => label.endsWith('checked'));
}

module('Integration | Component | EuiSheet row-number keys', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(state: State, height = 300): Promise<void> {
    await render(
      <template>
        <div style="width:500px">
          <EuiSheet
            @records={{state.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @checkedRecordIds={{state.checked}}
            @onCheckedChange={{state.onCheckedChange}}
            @height={{height}}
          />
        </div>
      </template>
    );
  }

  test('RNK1 without groups, a grid that scrolls: PageDown and PageUp on a row number keep focus in the row-number column', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await focus(rowNumberCell(1));
    assert.strictEqual(focusedRow(), 1);
    assert.true(await page('PageDown'), 'PageDown taken');
    const down = focusedRow();
    assert.notStrictEqual(down, null, 'focus is on a row number, not <body>');
    assert.true(down! > 1, `a page down (row ${down})`);
    assert.true(scrollTop() > 0, 'the grid scrolled');
    assert.true(await page('PageDown'), 'again');
    const again = focusedRow();
    assert.true(again !== null && again > down!, `row ${again}`);
    assert.true(await page('PageUp'), 'PageUp taken');
    assert.strictEqual(focusedRow(), down, 'a page up');
    assert.true(await page('PageUp'));
    assert.strictEqual(focusedRow(), 1, 'back on the first row number');
  });

  test('RNK2 Shift+PageDown on a row number selects whole rows; at the end PageDown stays; Ctrl+PageDown is not taken', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await focus(rowNumberCell(0));
    assert.true(await page('PageDown', { shiftKey: true }));
    const to = focusedRow()!;
    assert.true(to > 0, `on row ${to}`);
    const rowsSelected = new Set(
      selected().map((pos) => Number(pos.split(':')[0]))
    );
    assert.true(
      rowsSelected.has(0) && rowsSelected.has(to),
      'the rows from the first to the focused one are selected'
    );
    assert.false(
      await pressed('PageDown', { ctrlKey: true }),
      'Ctrl+PageDown: the browser’s'
    );

    // the last rows: PageDown stays on the last row, focus kept
    state.records = rows(30);
    await settled();
    await focus(rowNumberCell(0));
    for (let i = 0; i < 8; i++) await page('PageDown');
    const last = focusedRow();
    assert.notStrictEqual(last, null, 'focus kept at the end');
    assert.true(await page('PageDown'), 'still taken');
    assert.strictEqual(focusedRow(), last, 'no further');
  });

  test('RNK3 the row-number header: Space and Enter check every record, then none; its hidden text says the state', async function (assert) {
    const state = new State();
    state.records = rows(4);
    await renderSheet(state);
    assert.strictEqual(
      header().querySelector('.euiSheet__srOnly')?.textContent?.trim(),
      'Row number',
      'the name first'
    );
    assert.strictEqual(stateText(), 'Select all rows', 'none checked');
    await focus(header());
    assert.true(await pressed(' '), 'Space taken');
    assert.strictEqual(checkedLabels().length, 4, 'every record checked');
    assert.strictEqual(stateText(), 'All rows checked');
    assert.strictEqual(document.activeElement, header(), 'focus stays');
    assert.true(await pressed('Enter'), 'Enter taken');
    assert.deepEqual(checkedLabels(), [], 'none checked');
    assert.strictEqual(stateText(), 'Select all rows');

    // some checked (Space on a row number): Space on the header checks all
    await focus(rowNumberCell(1));
    await pressed(' ');
    await focus(header());
    assert.strictEqual(stateText(), 'Some rows checked');
    await pressed(' ');
    assert.strictEqual(stateText(), 'All rows checked', 'all from some');

    // modifiers are not taken
    assert.false(await pressed(' ', { ctrlKey: true }), 'Ctrl+Space');
    assert.false(await pressed('Enter', { shiftKey: true }), 'Shift+Enter');
    assert.strictEqual(stateText(), 'All rows checked', 'unchanged');
  });

  test('RNK4 the header keys go through @onCheckedChange; the texts are messages', async function (assert) {
    const state = new State();
    state.records = rows(3);
    state.checked = [];
    const calls: RecordId[][] = [];
    state.onCheckedChange = (ids) => {
      calls.push(ids);
      state.checked = ids;
    };
    await renderSheet(state);
    await focus(header());
    await pressed('Enter');
    assert.deepEqual(calls, [['r0', 'r1', 'r2']], 'one call with every id');
    assert.strictEqual(stateText(), 'All rows checked');
    await pressed(' ');
    assert.deepEqual(calls[1], [], 'then none');

    const messages = {
      selectAllRows: () => 'Seleccionar todo',
      allRowsChecked: () => 'Todo marcado'
    };
    await render(
      <template>
        <EuiSheet
          @records={{state.records}}
          @fields={{FIELDS}}
          @getRecordId={{getId}}
          @onChange={{state.onChange}}
          @messages={{messages}}
        />
      </template>
    );
    assert.strictEqual(stateText(), 'Seleccionar todo', '@messages');
    await focus(header());
    await pressed(' ');
    assert.strictEqual(stateText(), 'Todo marcado');
  });
});
