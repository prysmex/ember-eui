/**
 * View intents (V02-DESIGN.md 6): sort arrows and the header menu,
 * presentation state (controlled with a handler, local without), the
 * `<:toolbar>` and `<:footer>` blocks, the highlighted term, the loading
 * bar and field descriptions. Column drag (V03 5.3, CD1-CD9) and header
 * lines (V03 5.4, HW1-HW3).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { registerWarnHandler } from '@ember/debug';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
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
  editorFrame,
  el,
  focusCell,
  press,
  resizerOf,
  selected,
  text,
  type
} from '../../helpers/sheet.ts';

import type { ChangeSet, EuiSheetField } from '#src/core/index.ts';
import type { TOC } from '@ember/component/template-only';
import type {
  EuiSheetFieldType,
  SheetCellSignature,
  SheetRowHeight,
  SheetSort
} from '#src/types.ts';

interface Row {
  id: string;
  name: string;
  city: string;
  qty: number | null;
  notes?: string;
}

const NAME: EuiSheetField<Row> = { id: 'name', label: 'Name' };
const CITY: EuiSheetField<Row> = { id: 'city', label: 'City' };
const QTY: EuiSheetField<Row> = { id: 'qty', label: 'Qty', type: 'number' };
const NOTES: EuiSheetField<Row> = { id: 'notes', label: 'Notes' };

const rows = (): Row[] => [
  { id: 'a', name: 'Ana', city: 'Monterrey', qty: 3, notes: 'n-a' },
  { id: 'b', name: 'Beto', city: 'Madrid', qty: 1, notes: 'n-b' },
  { id: 'c', name: 'Caro', city: 'Lima', qty: 2, notes: 'n-c' }
];

const getId = (row: Row) => row.id;

class State {
  @tracked fields: EuiSheetField<Row>[] = [NAME, CITY, QTY];
  @tracked hiddenFields: EuiSheetField<Row>[] | undefined = undefined;
  @tracked sort: SheetSort[] | undefined = undefined;
  @tracked fieldWidths: Record<string, number> | undefined = undefined;
  @tracked rowHeight: SheetRowHeight | undefined = undefined;
  @tracked highlight: string | undefined = undefined;
  @tracked isLoading: boolean | undefined = undefined;
  @tracked fieldDrag: boolean | undefined = undefined;
  @tracked headerLines: 1 | 2 | 3 | undefined = undefined;
  @tracked frozenFields: number | undefined = undefined;
  onSortChange: ((sort: SheetSort[]) => void) | undefined = undefined;
  onHiddenFieldsChange: ((ids: string[]) => void) | undefined = undefined;
  onFieldOrderChange: ((ids: string[]) => void) | undefined = undefined;
  onFieldWidthChange: ((id: string, width: number) => void) | undefined =
    undefined;
  onRowHeightChange: ((rowHeight: SheetRowHeight) => void) | undefined =
    undefined;
  onFilterByField: ((id: string) => void) | undefined = undefined;
  fieldTypes: Record<string, EuiSheetFieldType<any, any>> | undefined =
    undefined;
  store = localRecords(rows(), { getRecordId: getId });
  changes: ChangeSet[] = [];
  onChange = (changeSet: ChangeSet) => {
    this.changes.push(changeSet);
    this.store.apply(changeSet);
  };
}

/** Opens a column's header menu and returns its items' labels. */
async function openMenu(fieldId: string): Promise<string[]> {
  await click(el(`[data-test-subj=dataGridHeaderCellActionButton-${fieldId}]`));
  await waitUntil(() =>
    document.querySelector(
      `[data-test-subj=dataGridHeaderCellActionGroup-${fieldId}]`
    )
  );
  return menuItems(fieldId).map((item) => item.textContent?.trim() ?? '');
}

function menuItems(fieldId: string): HTMLElement[] {
  return Array.from(
    document.querySelectorAll<HTMLElement>(
      `[data-test-subj=dataGridHeaderCellActionGroup-${fieldId}] button`
    )
  );
}

async function pick(fieldId: string, label: string): Promise<void> {
  const item = menuItems(fieldId).find(
    (button) => button.textContent?.trim() === label
  );
  if (!item) throw new Error(`No "${label}" in ${fieldId}'s menu`);
  await click(item);
}

/** The visible column ids, in order. */
function headers(): string[] {
  return Array.from(
    document.querySelectorAll<HTMLElement>('[role=columnheader]')
  )
    .map((header) => header.dataset['gridcellColumnId']!)
    .filter((id) => id !== 'euiSheetRow');
}

function header(fieldId: string): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-id="${fieldId}"]`);
}

const sortIcon = (fieldId: string) =>
  `[data-test-subj=dataGridHeaderCellSortingIcon-${fieldId}]`;

/** Warnings by id, while a test collects them (CD5). */
let warnings: string[] | null = null;
registerWarnHandler((message, options, next) => {
  if (warnings && options?.id) warnings.push(options.id);
  next(message, options);
});

/** Waits a frame: the grid focuses the dropped header in a timeout. */
async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

/** A keyboard drag of a field's header: Space, the arrows, Space (V03 5.3). */
async function keyboardDrag(fieldId: string, steps: number): Promise<void> {
  await focus(header(fieldId));
  await press(' ');
  for (let i = 0; i < Math.abs(steps); i++) {
    await press(steps > 0 ? 'ArrowRight' : 'ArrowLeft');
  }
  await press(' ');
  await frame();
}

const byId = (ids: string[]) =>
  ids.map((id) => [NAME, CITY, QTY, NOTES].find((field) => field.id === id)!);

/** A custom cell that shows what it got as `@highlight`. */
const HighlightProbe: TOC<SheetCellSignature> = <template>
  <span data-test-probe-highlight>{{@highlight}}|{{@text}}</span>
</template>;

const PROBE_TYPES: Record<string, EuiSheetFieldType<any, any>> = {
  probe: {
    parse: (text: string) => ({ value: text }),
    format: (value: unknown) => (typeof value === 'string' ? value : ''),
    cell: HighlightProbe
  }
};

module('Integration | Component | EuiSheet view intents', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(state: State): Promise<void> {
    await render(
      <template>
        <div style="width:700px">
          <EuiSheet
            @fields={{state.fields}}
            @hiddenFields={{state.hiddenFields}}
            @records={{state.store.records}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @sort={{state.sort}}
            @onSortChange={{state.onSortChange}}
            @onHiddenFieldsChange={{state.onHiddenFieldsChange}}
            @onFieldOrderChange={{state.onFieldOrderChange}}
            @fieldWidths={{state.fieldWidths}}
            @onFieldWidthChange={{state.onFieldWidthChange}}
            @rowHeight={{state.rowHeight}}
            @onRowHeightChange={{state.onRowHeightChange}}
            @onFilterByField={{state.onFilterByField}}
            @highlight={{state.highlight}}
            @isLoading={{state.isLoading}}
            @fieldTypes={{state.fieldTypes}}
            @fieldDrag={{state.fieldDrag}}
            @headerLines={{state.headerLines}}
            @frozenFields={{state.frozenFields}}
          />
        </div>
      </template>
    );
  }

  test('VW1 without @onSortChange: no sort items and no arrow, even with @sort', async function (assert) {
    const state = new State();
    state.sort = [{ field: 'city', direction: 'asc' }];
    await renderSheet(state);
    assert.dom(sortIcon('city')).doesNotExist('no arrow');
    const labels = await openMenu('city');
    assert.notOk(
      labels.some((label) => label.startsWith('Sort')),
      `no sort item (${labels.join(', ')})`
    );
  });

  test('VW2 "Sort A-Z" emits the intent; rows stay; the arrow shows once @sort is updated', async function (assert) {
    const state = new State();
    const calls: SheetSort[][] = [];
    state.onSortChange = (sort) => calls.push(sort);
    await renderSheet(state);
    const labels = await openMenu('city');
    assert.true(labels.includes('Sort A-Z'), labels.join(', '));
    await pick('city', 'Sort A-Z');
    assert.deepEqual(calls, [[{ field: 'city', direction: 'asc' }]]);
    assert.deepEqual(
      [text(0, 1), text(1, 1), text(2, 1)],
      ['Monterrey', 'Madrid', 'Lima'],
      'the sheet does not sort'
    );
    assert.dom(sortIcon('city')).doesNotExist('no arrow until @sort');
    state.sort = [{ field: 'city', direction: 'asc' }];
    await settled();
    assert.dom(sortIcon('city')).exists('the arrow follows @sort');
    assert.dom(header('city')).hasAttribute('aria-sort', 'ascending');
  });

  test('VW3 a second sort goes out as two items; the label follows the schema; sortable: false', async function (assert) {
    const state = new State();
    const calls: SheetSort[][] = [];
    state.sort = [{ field: 'name', direction: 'asc' }];
    state.onSortChange = (sort) => calls.push(sort);
    state.fields = [NAME, { ...CITY, sortable: false }, QTY];
    await renderSheet(state);
    const labels = await openMenu('qty');
    assert.true(labels.includes('Sort Low-High'), labels.join(', '));
    await pick('qty', 'Sort High-Low');
    assert.deepEqual(calls, [
      [
        { field: 'name', direction: 'asc' },
        { field: 'qty', direction: 'desc' }
      ]
    ]);
    const city = await openMenu('city');
    assert.notOk(
      city.some((label) => label.startsWith('Sort')),
      `sortable: false has no sort items (${city.join(', ')})`
    );
  });

  test('VW4 hide with @onHiddenFieldsChange: called with the ids; the column stays until @fields changes', async function (assert) {
    const state = new State();
    const calls: string[][] = [];
    state.hiddenFields = [NOTES];
    state.onHiddenFieldsChange = (ids) => calls.push(ids);
    await renderSheet(state);
    await openMenu('city');
    await pick('city', 'Hide column');
    assert.deepEqual(calls, [['notes', 'city']]);
    assert.deepEqual(headers(), ['name', 'city', 'qty'], 'still shown');
    state.fields = [NAME, QTY];
    state.hiddenFields = [NOTES, CITY];
    await settled();
    assert.deepEqual(headers(), ['name', 'qty']);
    state.fields = [NAME, { ...QTY, hideable: false }];
    await settled();
    const labels = await openMenu('qty');
    assert.false(labels.includes('Hide column'), 'hideable: false');
  });

  test('VW5 hide without a handler: the column goes (C6), copy excludes it, the form lists it', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await openMenu('city');
    await pick('city', 'Hide column');
    assert.deepEqual(
      headers(),
      ['name', 'qty'],
      'hidden, not moved to the end'
    );
    await focusCell(0, 0);
    await click(cell(1, 1), { shiftKey: true });
    const copied = await clipboard('copy');
    assert.strictEqual(copied.text, 'Ana\t3\nBeto\t1', 'copy has no city');
    await focusCell(0, 0);
    await press(' ');
    await waitUntil(() =>
      document.querySelector('[data-test-subj=euiSheetRecordField-city]')
    );
    assert
      .dom('[data-test-subj=euiSheetRecordField-city]', document.body)
      .exists('the expanded record lists the hidden field');
    await press('Escape');
  });

  test('VW6 move left/right: @onFieldOrderChange, and the local fallback; the first field has neither', async function (assert) {
    const state = new State();
    await renderSheet(state);
    // the first field cannot be moved or hidden: without sort or filter
    // items it has no menu at all
    assert
      .dom('[data-test-subj=dataGridHeaderCellActionButton-name]')
      .doesNotExist();
    const city = await openMenu('city');
    assert.false(city.includes('Move left'), 'not past the first field');
    assert.true(city.includes('Move right'));
    await pick('city', 'Move right');
    assert.deepEqual(headers(), ['name', 'qty', 'city'], 'local order');
    await openMenu('city');
    await pick('city', 'Move left');
    assert.deepEqual(headers(), ['name', 'city', 'qty']);

    const controlled = new State();
    const calls: string[][] = [];
    controlled.onFieldOrderChange = (ids) => calls.push(ids);
    await renderSheet(controlled);
    await openMenu('city');
    await pick('city', 'Move right');
    assert.deepEqual(calls, [['name', 'qty', 'city']]);
    assert.deepEqual(
      headers(),
      ['name', 'city', 'qty'],
      'until @fields changes'
    );
    controlled.fields = [NAME, QTY, CITY];
    await settled();
    assert.deepEqual(headers(), ['name', 'qty', 'city']);
  });

  test('VW7 @onFilterByField adds "Filter by this field" and gets the field id', async function (assert) {
    const state = new State();
    await renderSheet(state);
    assert.false(
      (await openMenu('city')).includes('Filter by this field'),
      'no item without the handler'
    );
    const filtered = new State();
    const calls: string[] = [];
    filtered.onFilterByField = (id) => calls.push(id);
    await renderSheet(filtered);
    assert.true((await openMenu('city')).includes('Filter by this field'));
    await pick('city', 'Filter by this field');
    assert.deepEqual(calls, ['city']);
    assert.true(
      (await openMenu('name')).includes('Filter by this field'),
      'also on the first field'
    );
  });

  test('VW8 @fieldWidths sets widths; a resize calls @onFieldWidthChange; a new width re-applies (N6)', async function (assert) {
    const state = new State();
    const calls: Array<[string, number]> = [];
    state.fieldWidths = { name: 180, city: 120 };
    state.onFieldWidthChange = (id, width) => calls.push([id, width]);
    await renderSheet(state);
    assert.strictEqual(header('name').style.width, '180px');
    assert.strictEqual(header('city').style.width, '120px');
    const resizer = resizerOf(header('city'));
    await triggerEvent(resizer, 'mousedown', { clientX: 300 });
    await triggerEvent(window as unknown as Element, 'mousemove', {
      clientX: 330
    });
    await triggerEvent(window as unknown as Element, 'mouseup');
    assert.deepEqual(calls, [['city', 150]]);
    state.fieldWidths = { name: 180, city: 150 };
    await settled();
    assert.strictEqual(header('city').style.width, '150px');
    state.fieldWidths = { name: 240, city: 150 };
    await settled();
    assert.strictEqual(
      header('name').style.width,
      '240px',
      'a changed width re-applies to an existing column'
    );
    // controlled: dropping a width from @fieldWidths resets it (the sheet
    // keeps no width of its own with the handler)
    state.fieldWidths = { name: 240 };
    await settled();
    assert.notStrictEqual(
      header('city').style.width,
      '150px',
      'the reset width is not kept'
    );

    // without a handler the grid keeps the width (6.4); when its columns
    // change (a hide gives it new ones) the sheet gives it back (V03 X6)
    const local = new State();
    await renderSheet(local);
    const localResizer = resizerOf(header('city'));
    const before = parseFloat(header('city').style.width);
    const name = header('name').style.width;
    await triggerEvent(localResizer, 'mousedown', { clientX: 300 });
    await triggerEvent(window as unknown as Element, 'mousemove', {
      clientX: 340
    });
    await triggerEvent(window as unknown as Element, 'mouseup');
    assert.strictEqual(parseFloat(header('city').style.width), before + 40);
    assert.strictEqual(
      header('name').style.width,
      name,
      'the other columns keep their widths'
    );
    await openMenu('qty');
    await pick('qty', 'Hide column');
    assert.strictEqual(
      parseFloat(header('city').style.width),
      before + 40,
      'a resized width is kept when the columns change (X6)'
    );
  });

  test('VW9 @rowHeight changes the rows and the editor; setRowHeight calls the handler or the fallback', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const short = cell(0, 1).getBoundingClientRect().height;
    state.rowHeight = 'tall';
    await settled();
    const tall = cell(0, 1).getBoundingClientRect().height;
    assert.ok(tall > short * 2, `taller (${short} → ${tall})`);
    await focusCell(0, 1);
    await type('x');
    const frame = editorFrame()!.getBoundingClientRect();
    // V03 batch 1: plus up to 2 px above and below (lifted)
    assert.ok(
      frame.height - tall > -1 && frame.height - tall < 4.5,
      `the editor has the row's height (${frame.height} for ${tall})`
    );
    await press('Escape');
  });

  test('VW10 <:toolbar> and <:footer> yield the block API; nothing without them', async function (assert) {
    const state = new State();
    state.hiddenFields = [NOTES];
    const heights: SheetRowHeight[] = [];
    let checked: Row[] = [];
    const remember = (records: Row[]) => {
      checked = records;
      return records.length;
    };
    await render(
      <template>
        <div style="width:700px">
          <EuiSheet
            @fields={{state.fields}}
            @hiddenFields={{state.hiddenFields}}
            @records={{state.store.records}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
          >
            <:toolbar as |sheet|>
              <span data-test-hidden>{{#each sheet.hiddenFields as |f|}}{{f.id}}
                {{/each}}</span>
              <span data-test-fields>{{#each sheet.fields as |f|}}{{f.id}}
                {{/each}}</span>
              <button
                type="button"
                data-test-hide
                {{on "click" (fn sheet.hideField "city")}}
              >hide</button>
              <button
                type="button"
                data-test-show
                {{on "click" (fn sheet.showField "notes")}}
              >show</button>
              <button
                type="button"
                data-test-tall
                {{on "click" (fn sheet.setRowHeight "tall")}}
              >tall</button>
              <span data-test-height>{{sheet.rowHeight}}</span>
            </:toolbar>
            <:footer as |sheet|>
              <span data-test-checked>{{remember sheet.checkedRecords}}</span>
              <span data-test-sort>{{sheet.sort.length}}</span>
            </:footer>
          </EuiSheet>
        </div>
      </template>
    );
    assert.dom('[data-test-subj=euiSheetToolbar] [data-test-hide]').exists();
    assert
      .dom('[data-test-subj=euiSheetFooter] [data-test-checked]')
      .hasText('0');
    assert.dom('[data-test-hidden]').hasText('notes');
    await click('[data-test-hide]');
    assert.deepEqual(headers(), ['name', 'qty'], 'hideField (local)');
    assert.dom('[data-test-fields]').hasText('name qty');
    await click('[data-test-show]');
    assert.deepEqual(headers(), ['name', 'qty', 'notes'], 'showField (local)');
    assert.dom('[data-test-hidden]').hasText('city');
    const short = cell(0, 0).getBoundingClientRect().height;
    await click('[data-test-tall]');
    assert.dom('[data-test-height]').hasText('tall');
    assert.ok(
      cell(0, 0).getBoundingClientRect().height > short * 2,
      'setRowHeight (local): rows are taller'
    );
    await click(
      el('[data-test-subj=euiSheetRowCheck]', cell(1, 0).parentElement!)
    );
    assert.dom('[data-test-checked]').hasText('1');
    assert.deepEqual(
      checked.map((row) => row.id),
      ['b'],
      'checkedRecords'
    );
    assert.dom('[data-test-sort]').hasText('0');

    // controlled: the handlers, not the local state
    const controlled = new State();
    controlled.hiddenFields = [NOTES];
    const hidden: string[][] = [];
    controlled.onHiddenFieldsChange = (ids) => hidden.push(ids);
    controlled.onRowHeightChange = (rowHeight) => heights.push(rowHeight);
    await render(
      <template>
        <div style="width:700px">
          <EuiSheet
            @fields={{controlled.fields}}
            @hiddenFields={{controlled.hiddenFields}}
            @records={{controlled.store.records}}
            @getRecordId={{getId}}
            @onChange={{controlled.onChange}}
            @onHiddenFieldsChange={{controlled.onHiddenFieldsChange}}
            @onRowHeightChange={{controlled.onRowHeightChange}}
          >
            <:toolbar as |sheet|>
              <button
                type="button"
                data-test-hide
                {{on "click" (fn sheet.hideField "city")}}
              >hide</button>
              <button
                type="button"
                data-test-show
                {{on "click" (fn sheet.showField "notes")}}
              >show</button>
              <button
                type="button"
                data-test-first
                {{on "click" (fn sheet.hideField "name")}}
              >first</button>
              <button
                type="button"
                data-test-medium
                {{on "click" (fn sheet.setRowHeight "medium")}}
              >medium</button>
              <span data-test-height>{{sheet.rowHeight}}</span>
            </:toolbar>
          </EuiSheet>
        </div>
      </template>
    );
    await click('[data-test-hide]');
    await click('[data-test-show]');
    await click('[data-test-first]');
    assert.deepEqual(
      hidden,
      [['notes', 'city'], []],
      'the first field is never hidden'
    );
    assert.deepEqual(
      headers(),
      ['name', 'city', 'qty'],
      'nothing changed itself'
    );
    await click('[data-test-medium]');
    assert.deepEqual(heights, ['medium']);
    assert
      .dom('[data-test-height]')
      .hasText('short', '@rowHeight is not updated');

    await renderSheet(new State());
    assert.dom('[data-test-subj=euiSheetToolbar]').doesNotExist();
    assert.dom('[data-test-subj=euiSheetFooter]').doesNotExist();
  });

  test('VW11 @highlight marks the text in plain cells and reaches a custom cell', async function (assert) {
    const state = new State();
    state.fieldTypes = PROBE_TYPES;
    state.fields = [NAME, { ...CITY, type: 'probe' }, QTY];
    await renderSheet(state);
    assert.dom('mark', cell(1, 0)).doesNotExist('nothing without @highlight');
    state.highlight = 'et';
    await settled();
    assert.dom('mark', cell(1, 0)).hasText('et', 'Beto: "et" is marked');
    assert.dom('mark', cell(0, 0)).doesNotExist('Ana has no match');
    assert
      .dom('[data-test-probe-highlight]', cell(1, 1))
      .hasText('et|Madrid', 'the custom cell gets @highlight');
    assert.strictEqual(text(1, 0), 'Beto', 'the text is unchanged');
    state.highlight = 'A';
    await settled();
    assert.strictEqual(
      cell(0, 0).querySelectorAll('mark').length,
      2,
      'every match, any case'
    );
    state.highlight = '';
    await settled();
    assert.dom('mark', cell(0, 0)).doesNotExist('empty: no marks');
  });

  test('VW12 @isLoading shows the bar and editing still works', async function (assert) {
    const state = new State();
    state.isLoading = true;
    await renderSheet(state);
    assert.dom('[data-test-subj=euiSheetLoading]').exists();
    await focusCell(0, 1);
    await type('x');
    await press('Enter');
    assert.strictEqual(state.changes.length, 1, 'an edit while loading');
    assert.strictEqual(text(0, 1), 'x');
    state.isLoading = false;
    await settled();
    assert.dom('[data-test-subj=euiSheetLoading]').doesNotExist();
  });

  test('VW13 a description: a tip in the header and help text in the form', async function (assert) {
    const state = new State();
    state.fields = [NAME, { ...CITY, description: 'Where they work' }, QTY];
    await renderSheet(state);
    assert
      .dom('[data-test-subj=euiSheetFieldDescription]', header('city'))
      .exists();
    assert
      .dom('[data-test-subj=euiSheetFieldDescription]', header('name'))
      .doesNotExist();
    assert.dom('.euiSheet__headerTitle', header('city')).hasText('City');
    await focusCell(0, 1);
    await press(' ');
    await waitUntil(() =>
      document.querySelector('[data-test-subj=euiSheetRecordDescription]')
    );
    assert
      .dom(
        '[data-test-subj=euiSheetRecordField-city] [data-test-subj=euiSheetRecordDescription]',
        document.body
      )
      .hasText('Where they work');
    await press('Escape');
  });
  /* Column drag (V03 5.3) */

  test('CD1 drag is on by default: a droppable and a draggable per field; @fieldDrag={{false}}: neither; a press on a title is not prevented', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const droppable = '[data-test-subj=euiDataGridHeaderDroppable]';
    assert.dom(droppable).exists();
    assert.dom(`${droppable} .euiDraggable`).exists({ count: 3 });
    assert
      .dom('[role=columnheader][data-gridcell-column-id=euiSheetRow]')
      .exists('the row-number header')
      .doesNotHaveAttribute('draggable');
    assert.strictEqual(
      header('euiSheetRow').closest(droppable),
      null,
      'outside the droppable'
    );
    const press = new MouseEvent('mousedown', {
      bubbles: true,
      cancelable: true,
      button: 0
    });
    el('.euiDataGridHeaderCell__content', header('city')).dispatchEvent(press);
    await settled();
    assert.false(press.defaultPrevented, 'the drag can start');
    state.fieldDrag = false;
    await settled();
    assert.dom(droppable).doesNotExist();
    assert.dom('.euiDraggable').doesNotExist();
    assert
      .dom('[data-test-subj=dataGridColumnResizer]', header('city'))
      .exists('the v0.2 DOM: the resizer in the header cell');
    state.fieldDrag = undefined;
    state.fields = [NAME];
    await settled();
    assert.dom(droppable).doesNotExist('one field: nothing to drag');
  });

  test('CD2 a keyboard drag of the third field emits the new order; without a handler the sheet reorders', async function (assert) {
    const state = new State();
    const calls: string[][] = [];
    state.fields = [NAME, CITY, QTY, NOTES];
    state.onFieldOrderChange = (ids) => {
      calls.push(ids);
      state.fields = byId(ids);
    };
    await renderSheet(state);
    await keyboardDrag('qty', 1);
    assert.deepEqual(calls, [['name', 'city', 'notes', 'qty']]);
    assert.deepEqual(headers(), ['name', 'city', 'notes', 'qty']);

    const local = new State();
    local.fields = [NAME, CITY, QTY, NOTES];
    await renderSheet(local);
    await keyboardDrag('qty', 1);
    assert.deepEqual(
      headers(),
      ['name', 'city', 'notes', 'qty'],
      'local order'
    );
    assert.strictEqual(text(0, 3), '3', 'the cells moved with it');
  });

  test('CD3 a click on a title still selects the column; Shift+click extends', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await click(el('.euiDataGridHeaderCell__content', header('city')));
    assert.deepEqual(selected(), ['0:1', '1:1', '2:1'], 'the column');
    await click(el('.euiDataGridHeaderCell__content', header('qty')), {
      shiftKey: true
    });
    assert.strictEqual(selected().length, 6, 'Shift+click extends');
  });

  test('CD4 a drop before the first field leaves it first; the next drag starts from what is on screen', async function (assert) {
    const state = new State();
    const calls: string[][] = [];
    state.fields = [NAME, CITY, QTY, NOTES];
    state.onFieldOrderChange = (ids) => {
      calls.push(ids);
      state.fields = byId(ids);
    };
    await renderSheet(state);
    await keyboardDrag('qty', -2);
    assert.deepEqual(
      calls,
      [['name', 'qty', 'city', 'notes']],
      'emitted with the first field in front'
    );
    assert.deepEqual(headers(), ['name', 'qty', 'city', 'notes']);
    // the first field dragged away: no change, nothing emitted
    await keyboardDrag('name', 2);
    assert.strictEqual(calls.length, 1, 'a no-op is not emitted');
    assert.deepEqual(headers(), ['name', 'qty', 'city', 'notes']);
    await keyboardDrag('notes', -1);
    assert.deepEqual(
      calls[calls.length - 1],
      ['name', 'qty', 'notes', 'city'],
      'the order a user expects from the screen'
    );
  });

  test('CD5 an owner that ignores @onFieldOrderChange: the columns stay, one warning, the next drag starts from the shown order', async function (assert) {
    warnings = [];
    try {
      const state = new State();
      const calls: string[][] = [];
      state.fields = [NAME, CITY, QTY, NOTES];
      state.onFieldOrderChange = (ids) => calls.push(ids);
      await renderSheet(state);
      await keyboardDrag('qty', 1);
      assert.deepEqual(calls, [['name', 'city', 'notes', 'qty']]);
      assert.deepEqual(
        headers(),
        ['name', 'city', 'qty', 'notes'],
        'unchanged'
      );
      await keyboardDrag('city', 1);
      assert.deepEqual(
        calls[calls.length - 1],
        ['name', 'qty', 'city', 'notes'],
        'from the shown order, not the grid’s stale one'
      );
      assert.deepEqual(
        warnings.filter((id) => id === 'ember-eui.sheet.controlled-argument'),
        ['ember-eui.sheet.controlled-argument'],
        'warned once'
      );
    } finally {
      warnings = null;
    }
  });

  test('CD7 a resized width is kept when another column is dragged (bare sheet)', async function (assert) {
    const state = new State();
    state.fields = [NAME, CITY, QTY, NOTES];
    await renderSheet(state);
    const before = parseFloat(header('city').style.width);
    await triggerEvent(resizerOf(header('city')), 'mousedown', {
      clientX: 300
    });
    await triggerEvent(window as unknown as Element, 'mousemove', {
      clientX: 340
    });
    await triggerEvent(window as unknown as Element, 'mouseup');
    assert.strictEqual(parseFloat(header('city').style.width), before + 40);
    await keyboardDrag('notes', -1);
    assert.deepEqual(headers(), ['name', 'city', 'notes', 'qty']);
    assert.strictEqual(
      parseFloat(header('city').style.width),
      before + 40,
      'kept (X6)'
    );
  });

  test('CD8 Enter on a header opens the menu; Move left / right work; the sort arrow is drawn', async function (assert) {
    const state = new State();
    state.sort = [{ field: 'city', direction: 'asc' }];
    state.onSortChange = () => {};
    await renderSheet(state);
    assert.dom(sortIcon('city')).exists('the sort arrow');
    await focus(header('city'));
    await press('Enter');
    await waitUntil(() =>
      document.querySelector(
        '[data-test-subj=dataGridHeaderCellActionGroup-city]'
      )
    );
    await pick('city', 'Move right');
    assert.deepEqual(headers(), ['name', 'qty', 'city']);
    await openMenu('city');
    await pick('city', 'Move left');
    assert.deepEqual(headers(), ['name', 'city', 'qty']);
  });

  test('CD9 starting a header drag saves the open editor', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await focusCell(0, 1);
    await type('x');
    assert.ok(editorFrame(), 'editing');
    const draggable = header('qty').closest('.euiDraggable')!;
    draggable.dispatchEvent(
      new DragEvent('dragstart', {
        bubbles: true,
        cancelable: true,
        dataTransfer: new DataTransfer()
      })
    );
    await settled();
    assert.strictEqual(editorFrame(), null, 'closed');
    assert.strictEqual(state.changes.length, 1, 'saved');
    assert.strictEqual(state.changes[0]!.patches[0]!.to, 'x');
    draggable.dispatchEvent(new DragEvent('dragend', { bubbles: true }));
    await frame();
  });

  /* Header lines (V03 5.4) */

  const LONG: EuiSheetField<Row> = {
    id: 'city',
    label: 'The city where the person lives today'
  };

  /** Header row height, first body row top vs header bottom, and the label's line count. */
  function headerLayout(fieldId: string): {
    height: number;
    gap: number;
    lines: number;
  } {
    const row = el('[data-test-subj=dataGridHeader]').getBoundingClientRect();
    const body = cell(0, 0).getBoundingClientRect();
    const content = el('.euiDataGridHeaderCell__content', header(fieldId));
    const lineHeight = parseFloat(getComputedStyle(content).lineHeight);
    return {
      height: row.height,
      gap: Math.abs(body.top - row.bottom),
      // offsetHeight: CSS px (the test container is scaled)
      lines: Math.round(content.offsetHeight / lineHeight)
    };
  }

  for (const variant of ['plain', 'frozen and described'] as const) {
    test(`HW1/HW2 @headerLines={{2}} wraps a long label and the rows follow the header (${variant})`, async function (assert) {
      const state = new State();
      const long =
        variant === 'plain'
          ? LONG
          : { ...LONG, description: 'Where they live' };
      state.fields = [NAME, long, QTY];
      state.fieldWidths = { city: 110 };
      if (variant !== 'plain') state.frozenFields = 1;
      await renderSheet(state);
      const one = headerLayout('city');
      assert.strictEqual(one.lines, 1, 'one line by default');
      state.headerLines = 2;
      await settled();
      await waitUntil(() => headerLayout('city').gap < 1);
      const two = headerLayout('city');
      assert.true(
        two.height > one.height,
        `taller (${one.height} → ${two.height})`
      );
      assert.true(two.gap < 1, 'the first row starts at the header’s bottom');
      assert.strictEqual(two.lines, 2, 'two lines, not more');
      assert.strictEqual(
        el('.euiDataGridHeaderCell__content', header('city')).title,
        long.label,
        'the full text in the title'
      );
      if (variant !== 'plain') {
        assert
          .dom('[data-test-subj=euiSheetFieldDescription]', header('city'))
          .exists();
      }
      state.headerLines = 3;
      await settled();
      await waitUntil(() => headerLayout('city').gap < 1);
      assert.true(headerLayout('city').lines <= 3, 'at most three lines');
    });
  }

  test('HW3 default: one line, as in v0.2', async function (assert) {
    const state = new State();
    state.fields = [NAME, LONG, QTY];
    state.fieldWidths = { city: 110 };
    await renderSheet(state);
    const content = el('.euiDataGridHeaderCell__content', header('city'));
    assert.strictEqual(headerLayout('city').lines, 1);
    assert.notStrictEqual(getComputedStyle(content).whiteSpace, 'normal');
    assert.false(
      el('[data-test-subj=euiSheet]').className.includes(
        'euiSheet--headerLines'
      ),
      'no class'
    );
  });
  /* Header marks and the header menu's trigger (V03 batch 1) */

  const trigger = (fieldId: string) =>
    el(`[data-test-subj=dataGridHeaderCellActionButton-${fieldId}]`);
  const shown = (element: HTMLElement) =>
    getComputedStyle(element).opacity === '1';

  test('HM1 a header click marks that header and no other', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await click(el('.euiDataGridHeaderCell__content', header('city')));
    const style = getComputedStyle(header('city'));
    assert.true(style.backgroundImage.includes('linear-gradient'), 'tinted');
    assert.true(style.boxShadow.includes('-3px'), `a bar (${style.boxShadow})`);
    for (const other of ['name', 'qty']) {
      assert.strictEqual(
        getComputedStyle(header(other)).backgroundImage,
        'none',
        `${other} is not marked`
      );
    }
    // the grid animates the trigger in
    await waitUntil(() => shown(trigger('city')), { timeout: 2000 });
    assert.true(shown(trigger('city')), 'its menu trigger shows');
  });

  test('MT1 the menu trigger shows on the active cell’s column without hover; MT2 and on a selected column', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await focusCell(0, 1);
    // the grid animates the trigger in
    await waitUntil(() => shown(trigger('city')), { timeout: 2000 });
    assert.true(shown(trigger('city')), 'the active cell’s column');
    assert.false(shown(trigger('qty')), 'not the others (until hover)');
    const probe = document.createElement('span');
    probe.style.color = 'var(--euiSheet-text)';
    el('[data-test-subj=euiSheet]').appendChild(probe);
    const textColor = getComputedStyle(probe).color;
    probe.remove();
    assert.strictEqual(
      getComputedStyle(trigger('city')).color,
      textColor,
      'in the text colour, not subdued'
    );
    assert.strictEqual(
      getComputedStyle(el('svg', trigger('city'))).width,
      '16px',
      'a 16 px icon'
    );
    await click(el('.euiDataGridHeaderCell__content', header('qty')));
    await waitUntil(() => shown(trigger('qty')), { timeout: 2000 });
    assert.true(shown(trigger('qty')), 'a selected column');
  });

  test('MT3 a right-click on a header opens its menu', async function (assert) {
    const state = new State();
    await renderSheet(state);
    const event = new MouseEvent('contextmenu', {
      bubbles: true,
      cancelable: true,
      button: 2
    });
    el('.euiDataGridHeaderCell__content', header('city')).dispatchEvent(event);
    await waitUntil(() =>
      document.querySelector(
        '[data-test-subj=dataGridHeaderCellActionGroup-city]'
      )
    );
    assert.true(event.defaultPrevented, 'not the browser’s menu');
    assert.true(menuItems('city').length > 0, 'the header menu');
    assert.deepEqual(selected(), [], 'no column selected by it');
  });

  test('EG1 the cell editor is lifted 2 px past its cell, with a 3 px ring and a shadow; clamped at the header', async function (assert) {
    const state = new State();
    await renderSheet(state);
    for (const row of [1, 0]) {
      await focusCell(row, 1);
      await type('x');
      const frame = editorFrame()!;
      const box = frame.getBoundingClientRect();
      const target = cell(row, 1).getBoundingClientRect();
      const scale = box.width / frame.offsetWidth;
      const past = {
        top: (target.top - box.top) / scale,
        left: (target.left - box.left) / scale,
        right: (box.right - target.right) / scale,
        bottom: (box.bottom - target.bottom) / scale
      };
      const sides = `${past.top.toFixed(1)} ${past.right.toFixed(1)} ${past.bottom.toFixed(1)} ${past.left.toFixed(1)}`;
      if (row === 1) {
        assert.true(
          Object.values(past).every((value) => Math.abs(value - 2) < 0.6),
          `row 1: 2 px on each side (${sides})`
        );
      } else {
        assert.true(
          Math.abs(past.top) < 0.6 && Math.abs(past.left - 2) < 0.6,
          `row 0: not over the header (${sides})`
        );
      }
      const input = el('.euiSheet__input', frame);
      assert.strictEqual(getComputedStyle(input).borderTopWidth, '3px');
      assert.notStrictEqual(getComputedStyle(input).boxShadow, 'none');
      // the text starts where the cell's text was: 6 px in
      const textLeft =
        (input.getBoundingClientRect().left - target.left) / scale +
        parseFloat(getComputedStyle(input).borderLeftWidth) +
        parseFloat(getComputedStyle(input).paddingLeft);
      assert.true(Math.abs(textLeft - 6) < 0.6, `text at ${textLeft} px`);
      await press('Escape');
    }
  });
  test('EM2 while @isLoading the empty message is not shown', async function (assert) {
    const state = new State();
    state.store = localRecords<Row>([], { getRecordId: getId });
    state.isLoading = true;
    await renderSheet(state);
    assert.dom('[data-test-subj=euiSheetEmpty]').doesNotExist('loading');
    state.isLoading = false;
    await settled();
    assert.dom('[data-test-subj=euiSheetEmpty]').exists('loaded, empty');
  });
});
