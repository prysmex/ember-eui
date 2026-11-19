/**
 * View intents (V02-DESIGN.md 6): sort arrows and the header menu,
 * presentation state (controlled with a handler, local without), the
 * `<:toolbar>` and `<:footer>` blocks, the highlighted term, the loading
 * bar and field descriptions.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  click,
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
    const resizer = el(
      '[role=columnheader][data-gridcell-column-id="city"] [data-test-subj=dataGridColumnResizer]'
    );
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

    // without a handler the grid keeps the width (6.4), until its columns
    // change: a hide gives it new columns, and it drops resized widths
    const local = new State();
    await renderSheet(local);
    const localResizer = el(
      '[role=columnheader][data-gridcell-column-id="city"] [data-test-subj=dataGridColumnResizer]'
    );
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
    assert.notStrictEqual(
      parseFloat(header('city').style.width),
      before + 40,
      'the grid drops a resized width when its columns change'
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
    assert.ok(
      Math.abs(frame.height - tall) < 1,
      `the editor has the row's height (${frame.height})`
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
});
