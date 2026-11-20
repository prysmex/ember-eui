/**
 * Full screen (v0.4 02, FS1-FS7): `@fullScreen`, `@onFullScreenChange`,
 * the block API's `isFullScreen` / `setFullScreen` and
 * `api.setFullScreen`. The test container and its content have a
 * transform, which makes them the box `position: fixed` fills; these
 * tests lift both, so the full-screen sheet fills the window as on a
 * page.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { click, render, settled, waitUntil } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  clipboard,
  editor,
  el,
  focusCell,
  press,
  type
} from '../../helpers/sheet.ts';

import type { EuiSheetField, SheetFieldDraft } from '#src/core/index.ts';
import type { SheetApi } from '#src/types.ts';

interface Row {
  id: string;
  name: string;
  status: string | null;
  qty: number;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name', width: 160 },
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    width: 140,
    options: [
      { value: 'o', label: 'Open' },
      { value: 'c', label: 'Closed' }
    ]
  },
  { id: 'qty', label: 'Qty', type: 'number', width: 100 }
];

const rows = (): Row[] =>
  Array.from({ length: 30 }, (_, i) => ({
    id: `r${i}`,
    name: `Name ${i}`,
    status: i % 2 ? 'o' : 'c',
    qty: i
  }));

const getId = (row: Row) => row.id;

class State {
  @tracked show = true;
  @tracked fullScreen: boolean | undefined = undefined;
  onFullScreenChange: ((on: boolean) => void) | undefined = undefined;
  onFieldUpdate: ((id: string, draft: SheetFieldDraft) => void) | undefined =
    undefined;
  api: SheetApi | null = null;
  registerApi = (api: SheetApi) => (this.api = api);
}

async function renderSheet(state: State) {
  const store = localRecords(rows(), { getRecordId: getId });
  await render(
    <template>
      <p data-test-before style="height: 40px">Page content</p>
      {{#if state.show}}
        <EuiSheet
          @fields={{FIELDS}}
          @records={{store.records}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
          @height={{200}}
          @fullScreen={{state.fullScreen}}
          @onFullScreenChange={{state.onFullScreenChange}}
          @onFieldUpdate={{state.onFieldUpdate}}
          @registerApi={{state.registerApi}}
        >
          <:toolbar as |sheet|>
            <button
              type="button"
              data-test-toggle
              aria-pressed={{if sheet.isFullScreen "true" "false"}}
              {{on
                "click"
                (fn sheet.setFullScreen (if sheet.isFullScreen false true))
              }}
            >Full screen</button>
          </:toolbar>
          <:footer>
            <span data-test-footer-text>30 records</span>
          </:footer>
        </EuiSheet>
      {{/if}}
    </template>
  );
  return store;
}

const wrapper = () => el('[data-test-subj=euiSheet]');
const isFull = () => wrapper().classList.contains('euiSheet--fullScreen');

async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

/** Whether the point at an element's centre is inside it (nothing covers it). */
function onTop(element: Element): boolean {
  const box = element.getBoundingClientRect();
  const hit = document.elementFromPoint(
    box.left + box.width / 2,
    box.top + box.height / 2
  );
  return !!hit && element.contains(hit);
}

module('Integration | Component | EuiSheet full screen', function (hooks) {
  setupRenderingTest(hooks);

  let saved: Array<[HTMLElement, string | null]> = [];
  hooks.beforeEach(function () {
    // the test container's transforms make it the box `position: fixed`
    // would fill
    saved = ['ember-testing-container', 'ember-testing'].map((id) => {
      const element = document.getElementById(id)!;
      const style = element.getAttribute('style');
      element.style.transform = 'none';
      return [element, style];
    });
    document.body.style.overflow = '';
  });
  hooks.afterEach(function () {
    for (const [element, style] of saved) {
      if (style === null) element.removeAttribute('style');
      else element.setAttribute('style', style);
    }
    document.body.style.overflow = '';
  });

  test('FS1 setFullScreen(true) from the toolbar: the sheet fills the window, the grid ends where the footer starts', async function (assert) {
    await renderSheet(new State());
    assert.false(isFull());
    const pageHeight = wrapper().offsetHeight;
    await click('[data-test-toggle]');
    await frame();
    assert.true(isFull());
    assert.dom('[data-test-toggle]').hasAttribute('aria-pressed', 'true');
    const box = wrapper().getBoundingClientRect();
    const view = document.documentElement;
    assert.deepEqual(
      [box.left, box.top, box.width, box.height].map(Math.round),
      [0, 0, view.clientWidth, view.clientHeight],
      'the window'
    );
    const grid = el('.euiSheet__grid');
    const footer = el('[data-test-subj=euiSheetFooter]');
    const gridBottom = grid.getBoundingClientRect().bottom;
    // the footer's own margin above it
    const footerTop =
      footer.getBoundingClientRect().top -
      parseFloat(getComputedStyle(footer).marginTop);
    assert.true(
      Math.abs(gridBottom - footerTop) < 1,
      `grid bottom ${gridBottom}, footer top ${footerTop}`
    );
    const padding = parseFloat(getComputedStyle(wrapper()).paddingBottom);
    assert.true(
      Math.abs(footer.getBoundingClientRect().bottom + padding - box.bottom) <
        1,
      'the footer at the bottom'
    );
    const body = el('.euiDataGrid__virtualized');
    assert.true(
      body.getBoundingClientRect().bottom <= gridBottom + 1 &&
        body.offsetHeight > 300,
      `the grid's body takes the room (${body.offsetHeight} px)`
    );
    assert.strictEqual(document.body.style.overflow, 'hidden');
    await click('[data-test-toggle]');
    await frame();
    assert.false(isFull());
    assert.strictEqual(wrapper().offsetHeight, pageHeight, 'back in the page');
  });

  test('FS2 Escape: an open editor, the row menu, the copy mark and a range each come first', async function (assert) {
    await renderSheet(new State());
    await click('[data-test-toggle]');
    await focusCell(2, 0);
    await type('x');
    assert.ok(editor(), 'an editor');
    await press('Escape');
    assert.notOk(editor(), 'Escape closes the editor');
    assert.true(isFull(), 'still full screen');

    await focusCell(2, 0);
    await press('F10', { shiftKey: true });
    assert.dom('[data-test-subj=euiSheetRowMenu]', document.body).exists();
    await press('Escape');
    assert
      .dom('[data-test-subj=euiSheetRowMenu]', document.body)
      .doesNotExist();
    assert.true(isFull(), 'the menu closed, still full screen');

    await focusCell(2, 0);
    await clipboard('copy');
    assert.dom('.euiSheet__range--copied').exists('the copy mark');
    await press('Escape');
    assert.dom('.euiSheet__range--copied').doesNotExist();
    assert.true(isFull(), 'the mark cleared first');

    await press('ArrowDown', { shiftKey: true });
    assert.dom('.euiSheet__cell--selected').exists({ count: 2 });
    await press('Escape');
    assert.dom('.euiSheet__cell--selected').exists({ count: 1 });
    assert.true(isFull(), 'the range collapsed first');

    await press('Escape');
    assert.false(isFull(), 'then Escape ends full screen');
    assert.strictEqual(document.activeElement, cell(2, 0), 'focus stays');
    await press('Escape');
    assert.false(isFull(), 'and does nothing more');
  });

  test('FS3 controlled: with @onFullScreenChange the sheet follows @fullScreen only', async function (assert) {
    const state = new State();
    const calls: boolean[] = [];
    state.fullScreen = false;
    state.onFullScreenChange = (on) => calls.push(on);
    await renderSheet(state);
    await click('[data-test-toggle]');
    assert.deepEqual(calls, [true]);
    assert.false(isFull(), 'not until @fullScreen changes');
    state.fullScreen = true;
    await settled();
    assert.true(isFull());
    await focusCell(0, 0);
    await press('Escape');
    assert.deepEqual(calls, [true, false]);
    assert.true(isFull(), 'Escape asks; @fullScreen decides');
    state.api!.setFullScreen(true);
    assert.deepEqual(calls, [true, false], 'no call for the same state');
    state.fullScreen = false;
    await settled();
    assert.false(isFull());
    // without the handler, @fullScreen is the start and the API changes it
    const local = new State();
    local.fullScreen = true;
    await renderSheet(local);
    assert.true(isFull(), '@fullScreen starts it');
    local.api!.setFullScreen(false);
    await settled();
    assert.false(isFull(), 'the sheet keeps its own state');
  });

  test('FS4 the expanded record, the row menu and a select editor open above the full-screen sheet', async function (assert) {
    await renderSheet(new State());
    await click('[data-test-toggle]');
    await frame();

    await focusCell(3, 0);
    await press('F10', { shiftKey: true });
    await frame();
    const menu = el('[data-test-subj=euiSheetRowMenu]');
    assert.true(onTop(menu), 'the row menu');
    await click(el('[data-test-subj=euiSheetRowMenu-insertBelow]'));
    await frame();
    assert.true(isFull(), 'an item works');

    await focusCell(3, 1);
    await press('Enter');
    await frame();
    const panel = el('[data-test-subj=euiSheetEditor]');
    assert.true(onTop(panel), 'the select panel');
    await press('Escape');

    await focusCell(3, 0);
    await press(' ');
    await waitUntil(() =>
      document.querySelector('[data-test-subj=euiSheetRecord]')
    );
    await frame();
    const record = el('[data-test-subj=euiSheetRecord]');
    // the flyout slides in from the right
    await waitUntil(
      () =>
        record.getBoundingClientRect().right <=
        document.documentElement.clientWidth + 1,
      { timeout: 3000 }
    );
    assert.true(onTop(record), 'the expanded record');
    await click(el('[data-test-subj=euiSheetRecordNext]'));
    assert.true(isFull(), 'its buttons work');
    await press('Escape');
    await frame();
    assert
      .dom('[data-test-subj=euiSheetRecord]', document.body)
      .doesNotExist('Escape closes the record');
    assert.true(isFull(), 'not full screen');
  });

  test('FS5 the page scrolls again after exit and after destroy', async function (assert) {
    const state = new State();
    document.body.style.overflow = 'auto';
    await renderSheet(state);
    state.api!.setFullScreen(true);
    await settled();
    assert.strictEqual(document.body.style.overflow, 'hidden');
    state.api!.setFullScreen(false);
    await settled();
    assert.strictEqual(document.body.style.overflow, 'auto', 'on exit');
    state.api!.setFullScreen(true);
    await settled();
    state.show = false;
    await settled();
    assert.strictEqual(document.body.style.overflow, 'auto', 'on destroy');
  });

  test('FS6 the focused cell and the range are kept; the range outline follows', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await focusCell(1, 0);
    await press('ArrowRight', { shiftKey: true });
    const outline = () => el('.euiSheet__range:not(.euiSheet__range--copied)');
    const matches = () => {
      const a = cell(1, 0).getBoundingClientRect();
      const b = cell(1, 1).getBoundingClientRect();
      const box = outline().getBoundingClientRect();
      return (
        Math.abs(box.left - a.left) < 3 &&
        Math.abs(box.right - b.right) < 3 &&
        Math.abs(box.top - a.top) < 3
      );
    };
    assert.true(matches(), 'the outline before');
    const focused = document.activeElement;
    // a click on the toolbar button would move focus: the API, as a
    // keyboard shortcut of the app would
    state.api!.setFullScreen(true);
    await frame();
    assert.true(isFull());
    assert.strictEqual(document.activeElement, focused, 'the same cell');
    assert.dom('.euiSheet__cell--selected').exists({ count: 2 });
    assert.true(matches(), 'the outline is placed again');
    state.api!.setFullScreen(false);
    await frame();
    assert.strictEqual(document.activeElement, focused, 'still the same cell');
    assert.true(matches(), 'and after exit');
  });

  test('FS7 the header menu, the field editor and the shortcut list open above it too', async function (assert) {
    const state = new State();
    state.onFieldUpdate = () => {};
    await renderSheet(state);
    state.api!.setFullScreen(true);
    await frame();

    await click(el('[data-test-subj=dataGridHeaderCellActionButton-status]'));
    await waitUntil(() =>
      document.querySelector(
        '[data-test-subj=dataGridHeaderCellActionGroup-status]'
      )
    );
    await frame();
    assert.true(
      onTop(el('[data-test-subj=dataGridHeaderCellActionGroup-status]')),
      'the header menu'
    );
    await press('Escape');
    await frame();
    assert.true(isFull(), 'Escape in the header menu closes only it');

    state.api!.editField('name');
    await frame();
    const fieldEditor = el('[data-test-subj=euiSheetFieldEditor]');
    assert.true(onTop(fieldEditor), 'the field editor');
    await click(el('[data-test-subj=euiSheetFieldCancel]'));
    await frame();

    state.api!.showShortcuts();
    await frame();
    assert.true(
      onTop(el('[data-test-subj=euiSheetShortcuts]')),
      'the shortcut list'
    );
    await press('Escape');
    await frame();
    assert
      .dom('[data-test-subj=euiSheetShortcuts]', document.body)
      .doesNotExist();
    assert.true(isFull(), 'closing it keeps full screen');
  });
});
