/**
 * The add row's "+ Add record" stays at the left edge while the grid is
 * scrolled sideways (no frozen fields): the row's first rendered cell is
 * made sticky and wide, as a group header's is (V03 9.1), and shows a
 * pinned copy; at rest the add row is unchanged (AR1-AR9).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, render, settled, triggerEvent } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { el } from '../../helpers/sheet.ts';

import type { ChangeSet, EuiSheetField } from '#src/core/index.ts';

type Row = Record<string, string | number>;

const FIELDS: EuiSheetField<Row>[] = Array.from({ length: 12 }, (_, i) => ({
  id: `f${i}`,
  label: `Field ${i}`,
  width: 150
}));

const RECORDS: Row[] = Array.from({ length: 5 }, (_, r) => {
  const row: Row = { id: r };
  for (let f = 0; f < 12; f++) row[`f${f}`] = `r${r}c${f}`;
  return row;
});

const getId = (row: Row) => row['id']!;

class State {
  @tracked frozenFields: number | undefined = undefined;
  @tracked rowNumbers: boolean | undefined = undefined;
  changes: ChangeSet[] = [];
  onChange = (changeSet: ChangeSet) => this.changes.push(changeSet);
}

function outer(): HTMLElement {
  return el('.euiDataGrid__virtualized');
}

async function scrollGrid(left: number): Promise<void> {
  const element = outer();
  element.scrollLeft = left;
  await triggerEvent(element, 'scroll');
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await settled();
}

const rect = (element: Element) => element.getBoundingClientRect();
const middleX = (element: Element) =>
  rect(element).left + rect(element).width / 2;

/** The scroll element's inner left edge, in screen px. */
function scrollLeftEdge(): number {
  const element = outer();
  const box = rect(element);
  const scale = element.offsetWidth ? box.width / element.offsetWidth : 1;
  return box.left + element.clientLeft * scale;
}

function addRow(): HTMLElement {
  return el('.euiDataGridRow.euiSheet__addRow');
}

const shown = (element: Element) =>
  getComputedStyle(element).display !== 'none' &&
  getComputedStyle(element).visibility !== 'hidden' &&
  rect(element).width > 0;

/** The pinned copies of the add row that are displayed. */
function displayedPins(): HTMLElement[] {
  return [
    ...addRow().querySelectorAll<HTMLElement>(
      '[data-test-subj=euiSheetAddPinned]'
    )
  ].filter(shown);
}

module('Integration | Component | EuiSheet add row pinned', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(state = new State()): Promise<State> {
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @records={{RECORDS}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @frozenFields={{state.frozenFields}}
            @rowNumbers={{state.rowNumbers}}
          />
        </div>
      </template>
    );
    return state;
  }

  test('AP1 at rest the add row is unchanged: its own plus and text, no pinned copy', async function (assert) {
    await renderSheet();
    assert.dom('.euiSheet').doesNotHaveClass('euiSheet--pinAddRow');
    assert.strictEqual(displayedPins().length, 0, 'no pinned copy shown');
    assert.true(
      shown(el('[data-test-subj=euiSheetRowAdd]', addRow())),
      'the plus'
    );
    assert.true(
      shown(el('[data-test-subj=euiSheetAddRecord]', addRow())),
      'the text'
    );
  });

  test('AP2 scrolled past column 0: one pinned "+ Add record" at the left edge, the cells\' own hidden', async function (assert) {
    await renderSheet();
    await scrollGrid(700);
    assert.dom('.euiSheet').hasClass('euiSheet--pinAddRow');
    const row = addRow();
    assert
      .dom('[data-gridcell-column-index="0"]', row)
      .doesNotExist('column 0 is unmounted');
    const pins = displayedPins();
    assert.strictEqual(pins.length, 1, 'exactly one pinned copy');
    const pin = pins[0]!;
    const host = pin.closest('[role=gridcell]')!;
    assert.strictEqual(host, row.firstElementChild, "in the row's first cell");
    assert.true(
      Math.abs(rect(host).left - scrollLeftEdge()) <= 1,
      `at the left edge (${rect(host).left} vs ${scrollLeftEdge()})`
    );
    const text = el('.euiSheet__addPinnedText', pin);
    assert.dom(text).hasText('Add record');
    const box = rect(text);
    const hit = document.elementFromPoint(
      box.left + 4,
      box.top + box.height / 2
    );
    assert.ok(
      hit && row.contains(hit),
      'the point over the text is in the add row'
    );
    assert.strictEqual(
      [...row.querySelectorAll('[data-test-subj=euiSheetAddRecord]')].filter(
        shown
      ).length,
      0,
      "the cells' own text is hidden"
    );
  });

  test('AP3 a small scroll: the pinned plus and text sit where the add row drew them at rest', async function (assert) {
    await renderSheet();
    const row = addRow();
    const plusAtRest = middleX(
      el(
        '[data-test-subj=euiSheetRowAdd] svg, [data-test-subj=euiSheetRowAdd]',
        row
      )
    );
    const textAtRest = el('[data-test-subj=euiSheetAddRecord]', row);
    const textLeftAtRest = rect(textAtRest).left;
    await scrollGrid(40);
    const pin = displayedPins()[0]!;
    assert.ok(pin, 'pinned');
    const plus = middleX(
      el('.euiSheet__addPinnedPlus svg, .euiSheet__addPinnedPlus', pin)
    );
    const textLeft = rect(el('.euiSheet__addPinnedText', pin)).left;
    assert.true(
      Math.abs(plus - plusAtRest) <= 1,
      `the plus (${plus} vs ${plusAtRest})`
    );
    assert.true(
      Math.abs(textLeft - textLeftAtRest) <= 2,
      `the text (${textLeft} vs ${textLeftAtRest})`
    );
  });

  test('AP4 a click on the pinned "Add record" inserts a record', async function (assert) {
    const state = await renderSheet();
    await scrollGrid(700);
    const pin = displayedPins()[0]!;
    await click(pin.closest('[role=gridcell]')!);
    assert.strictEqual(state.changes.length, 1, 'one change set');
    assert.strictEqual(state.changes[0]!.inserts?.length, 1, 'one insert');
  });

  test('AP5 with a frozen field nothing is pinned: the frozen columns stay anyway', async function (assert) {
    const state = new State();
    state.frozenFields = 1;
    await renderSheet(state);
    await scrollGrid(700);
    assert.dom('.euiSheet').doesNotHaveClass('euiSheet--pinAddRow');
    assert.strictEqual(displayedPins().length, 0);
    assert.true(
      shown(el('[data-test-subj=euiSheetAddRecord]', addRow())),
      'the text in the frozen first field'
    );
  });
});
