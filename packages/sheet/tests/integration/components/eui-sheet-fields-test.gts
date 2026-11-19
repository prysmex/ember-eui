/**
 * Field management from the grid (V03 6, FM1-FM19): the "+" column, the
 * header menu's field items, the field editor and its options forms,
 * `@fieldEditor`, `@creatableFieldTypes`, the history pruned on a field
 * delete, `localRecords` end to end and `api.addField` / `api.editField`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import {
  click,
  fillIn,
  focus,
  render,
  select,
  settled,
  triggerEvent,
  triggerKeyEvent,
  typeIn,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  clipboard,
  el,
  focusCell,
  press,
  pressed,
  text,
  type
} from '../../helpers/sheet.ts';

import type {
  ChangeSet,
  EuiSheetField,
  SheetFieldDraft
} from '#src/core/index.ts';
import type { TOC } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';
import type {
  EuiSheetFieldType,
  EuiSheetSignature,
  SheetApi,
  SheetFieldEditorSignature,
  SheetFieldOptionsSignature
} from '#src/types.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const NAME: EuiSheetField<Row> = { id: 'name', label: 'Name' };
const CITY: EuiSheetField<Row> = { id: 'city', label: 'City' };
const QTY: EuiSheetField<Row> = { id: 'qty', label: 'Qty', type: 'number' };
const NOTES: EuiSheetField<Row> = { id: 'notes', label: 'Notes' };
const STATUS: EuiSheetField<Row> = {
  id: 'status',
  label: 'Status',
  type: 'singleSelect',
  options: [
    { value: 'o', label: 'Open', color: 'success' },
    { value: 'c', label: 'Closed' }
  ]
};

const rows = (): Row[] => [
  { id: 'a', name: 'Ana', city: 'Monterrey', qty: 3, status: 'o' },
  { id: 'b', name: 'Beto', city: 'Madrid', qty: 1, status: 'c' },
  { id: 'c', name: 'Caro', city: 'Lima', qty: 2, status: null }
];

const getId = (row: Row) => row.id;

type SheetArgs = EuiSheetSignature<Row>['Args'];
type Create = NonNullable<SheetArgs['onFieldCreate']>;
type Update = NonNullable<SheetArgs['onFieldUpdate']>;
type Delete = NonNullable<SheetArgs['onFieldDelete']>;

class State {
  @tracked fields: EuiSheetField<Row>[] = [NAME, CITY, QTY];
  @tracked hiddenFields: EuiSheetField<Row>[] | undefined = undefined;
  @tracked frozenFields: number | undefined = undefined;
  @tracked summary: Record<string, string> | undefined = undefined;
  @tracked records: Row[] = rows();
  onFieldCreate: Create | undefined = undefined;
  onFieldUpdate: Update | undefined = undefined;
  onFieldDelete: Delete | undefined = undefined;
  fieldEditor: ComponentLike<SheetFieldEditorSignature> | undefined = undefined;
  creatableFieldTypes: string[] | undefined = undefined;
  fieldTypes: Record<string, EuiSheetFieldType<any, any>> | undefined =
    undefined;
  api: SheetApi | null = null;
  changes: ChangeSet[] = [];
  onChange = (changeSet: ChangeSet) => {
    this.changes.push(changeSet);
    const store = localRecords(this.records, { getRecordId: getId });
    store.apply(changeSet);
    this.records = store.records;
  };
  registerApi = (api: SheetApi) => (this.api = api);
}

/** Records every call of the three intents; create adds the field, delete removes it. */
function manage(state: State) {
  const calls = {
    create: [] as Array<[SheetFieldDraft, unknown]>,
    update: [] as Array<[string, SheetFieldDraft, unknown]>,
    delete: [] as string[]
  };
  state.onFieldCreate = (draft, position) => {
    calls.create.push([draft, position]);
    const fields = [...state.fields];
    fields.splice(position.index, 0, {
      ...draft,
      id: `new${calls.create.length}`
    });
    state.fields = fields;
  };
  state.onFieldUpdate = (id, draft, context) => {
    calls.update.push([id, draft, context]);
  };
  state.onFieldDelete = (id) => {
    calls.delete.push(id);
    state.fields = state.fields.filter((field) => field.id !== id);
  };
  return calls;
}

const ADD = 'euiSheet-addField';

const widthStyle = (width: number) => htmlSafe(`width:${width}px`);

function addHeader(): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-id="${ADD}"]`);
}

/** A cell's content, without the grid's copy markers. */
function contentOf(element: HTMLElement): string {
  return (
    element.querySelector('[data-datagrid-cellcontent]')?.textContent?.trim() ??
    ''
  );
}

function header(fieldId: string): HTMLElement {
  return el(`[role=columnheader][data-gridcell-column-id="${fieldId}"]`);
}

const editorSel = '[data-test-subj=euiSheetFieldEditor]';
const nameSel = '[data-test-subj=euiSheetFieldName]';
const typeSel = '[data-test-subj=euiSheetFieldType]';
const saveSel = '[data-test-subj=euiSheetFieldSave]';

function nameInput(): HTMLInputElement {
  return el(nameSel) as HTMLInputElement;
}

/** Waits for the trap's initial focus (the name input, or the confirm's Cancel). */
async function waitForEditorFocus(): Promise<void> {
  await waitUntil(() => !!document.activeElement?.closest(editorSel), {
    timeout: 2000
  });
}

async function openMenu(fieldId: string): Promise<void> {
  await click(el(`[data-test-subj=dataGridHeaderCellActionButton-${fieldId}]`));
  await waitUntil(() =>
    document.querySelector(
      `[data-test-subj=dataGridHeaderCellActionGroup-${fieldId}]`
    )
  );
}

/** A frame and a timeout: the focus trap and the popover settle. */
async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

/** Opens a field's header menu and picks one of the sheet's items. */
async function pickItem(fieldId: string, item: string): Promise<void> {
  await openMenu(fieldId);
  await click(el(`[data-test-subj=euiSheet${item}-${fieldId}]`));
  await frame();
}

function menuHas(fieldId: string, item: string): boolean {
  return !!document.querySelector(
    `[data-test-subj=euiSheet${item}-${fieldId}]`
  );
}

/** Option labels of the type select. */
function typeLabels(): string[] {
  return Array.from(
    (el(typeSel) as HTMLSelectElement).options,
    (option) => option.text
  );
}

/** An app editor content (FM15): shows what it got; its button saves. */
const AppEditor: TOC<SheetFieldEditorSignature> = <template>
  <div data-test-app-editor>
    <span data-test-app-mode>{{@mode}}</span>
    <span data-test-app-label>{{@draft.label}}</span>
    <span data-test-app-types>{{@types.length}}</span>
    <button
      type="button"
      data-test-app-save
      {{on "click" (fn @onSave (draftFor @draft))}}
    >Save</button>
  </div>
</template>;

const draftFor = (draft: SheetFieldDraft): SheetFieldDraft => ({
  ...draft,
  label: 'From app',
  type: 'number'
});

const steps3 = () => ({ steps: 3 });
const stepsOf = (draft: SheetFieldDraft): string => {
  const steps = draft['steps'];
  return typeof steps === 'number' ? String(steps) : '';
};

/** An app type's options form (FM16): a button that sets `steps`. */
const StageOptions: TOC<SheetFieldOptionsSignature> = <template>
  <div data-test-stage-options>
    <span data-test-stage-steps>{{stepsOf @draft}}</span>
    <button
      type="button"
      data-test-stage-set
      {{on "click" (fn @onChange (steps3))}}
    >3 steps</button>
  </div>
</template>;

const STAGE_TYPE: EuiSheetFieldType<string, EuiSheetField> = {
  parse: (text: string) => ({ value: text }),
  format: (value: unknown) => (typeof value === 'string' ? value : ''),
  label: 'Stage',
  fieldOptions: StageOptions
};

module('Integration | Component | EuiSheet fields', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(state: State, width = 700): Promise<void> {
    await render(
      <template>
        <div style={{widthStyle width}}>
          <EuiSheet
            @fields={{state.fields}}
            @hiddenFields={{state.hiddenFields}}
            @records={{state.records}}
            @getRecordId={{getId}}
            @onChange={{state.onChange}}
            @frozenFields={{state.frozenFields}}
            @summary={{state.summary}}
            @onFieldCreate={{state.onFieldCreate}}
            @onFieldUpdate={{state.onFieldUpdate}}
            @onFieldDelete={{state.onFieldDelete}}
            @fieldEditor={{state.fieldEditor}}
            @creatableFieldTypes={{state.creatableFieldTypes}}
            @fieldTypes={{state.fieldTypes}}
            @registerApi={{state.registerApi}}
          />
        </div>
      </template>
    );
  }

  test('FM1 without the handlers: no "+" column, no field items in the menu', async function (assert) {
    const state = new State();
    await renderSheet(state);
    assert
      .dom(`[role=columnheader][data-gridcell-column-id="${ADD}"]`)
      .doesNotExist();
    assert.dom(`[data-gridcell-column-id="${ADD}"]`).doesNotExist();
    await openMenu('city');
    for (const item of [
      'EditField',
      'DuplicateField',
      'InsertFieldLeft',
      'InsertFieldRight',
      'DeleteField'
    ]) {
      assert.false(menuHas('city', item), `no ${item}`);
    }
  });

  test('FM2 with @onFieldCreate: the "+" header cell; a click opens the editor with the name focused', async function (assert) {
    const state = new State();
    manage(state);
    await renderSheet(state);
    assert.dom(addHeader()).exists();
    assert
      .dom('[data-test-subj=euiSheetAddField] .euiIcon', addHeader())
      .exists();
    assert.strictEqual(
      addHeader().dataset['gridcellColumnIndex'],
      '4',
      'after the row numbers and the three fields'
    );
    await click(el('[data-test-subj=euiSheetAddField]'));
    await waitForEditorFocus();
    assert.dom(editorSel, document.body).exists();
    assert
      .dom('.euiSheetFieldEditor__title', document.body)
      .hasText('Add field');
    assert.strictEqual(document.activeElement, nameInput(), 'name focused');
    assert.dom(nameInput()).hasValue('');
    assert.dom(typeSel, document.body).hasValue('text');
    assert
      .dom('.euiSheet')
      .hasClass('euiSheet--addingField', 'the "+" shows open');
  });

  test('FM3 Save calls onFieldCreate(draft, { index: <count>, after: <last id> }), closes, focuses the header', async function (assert) {
    const state = new State();
    const calls = manage(state);
    await renderSheet(state);
    await click(addHeader());
    await waitForEditorFocus();
    await click(el(saveSel));
    assert.deepEqual(calls.create, [], 'an empty name does not save');
    assert
      .dom('.euiFormErrorText', document.body)
      .hasText('Give the field a name');
    await fillIn(nameInput(), '  Estado ');
    await click(el(saveSel));
    assert.deepEqual(calls.create, [
      [
        { label: 'Estado', type: 'text' },
        { index: 3, after: 'qty' }
      ]
    ]);
    await frame();
    assert.dom(editorSel, document.body).doesNotExist('closed');
    assert.strictEqual(document.activeElement, addHeader(), 'the "+" header');
    assert.dom(header('new1')).exists('the owner added it');

    // Enter in the name saves too
    await triggerKeyEvent(addHeader(), 'keydown', 'Enter');
    await waitForEditorFocus();
    await fillIn(nameInput(), 'Otro');
    await triggerKeyEvent(nameInput(), 'keydown', 'Enter');
    assert.strictEqual(calls.create.length, 2);
    assert.deepEqual(calls.create[1]![1], { index: 4, after: 'new1' });
  });

  test('FM4 Insert left / right pass index and after; no Insert left on the first field', async function (assert) {
    const state = new State();
    const calls = manage(state);
    await renderSheet(state);
    await pickItem('city', 'InsertFieldLeft');
    await waitForEditorFocus();
    await fillIn(nameInput(), 'Left');
    await click(el(saveSel));
    assert.deepEqual(calls.create[0]![1], { index: 1, after: 'name' });
    await pickItem('city', 'InsertFieldRight');
    await waitForEditorFocus();
    await fillIn(nameInput(), 'Right');
    await click(el(saveSel));
    assert.deepEqual(calls.create[1]![1], { index: 3, after: 'city' });
    await openMenu('name');
    assert.false(menuHas('name', 'InsertFieldLeft'), 'none on the first field');
    assert.true(menuHas('name', 'InsertFieldRight'));
  });

  test("FM5 Edit field opens with the field's values; Save calls onFieldUpdate(id, draft, { previous })", async function (assert) {
    const state = new State();
    const calls = manage(state);
    state.fields = [NAME, CITY, { ...QTY, description: 'How many' }];
    await renderSheet(state);
    await pickItem('qty', 'EditField');
    await waitForEditorFocus();
    assert.strictEqual(document.activeElement, nameInput(), 'name focused');
    assert
      .dom('.euiSheetFieldEditor__title', document.body)
      .hasText('Edit field');
    assert.dom(nameInput()).hasValue('Qty');
    assert.dom(typeSel, document.body).hasValue('number');
    const description = el('[data-test-subj=euiSheetFieldDescriptionInput]');
    assert.strictEqual(
      `${description.tagName}:${(description as HTMLTextAreaElement).value}`,
      'TEXTAREA:How many'
    );
    await fillIn(nameInput(), 'Amount');
    await click(el('[data-test-subj=euiSheetFieldRequired]'));
    await click(el(saveSel));
    assert.strictEqual(calls.update.length, 1);
    const [id, draft, context] = calls.update[0]!;
    assert.strictEqual(id, 'qty');
    assert.deepEqual(draft, {
      label: 'Amount',
      type: 'number',
      description: 'How many',
      required: true
    });
    assert.strictEqual(
      (context as { previous: EuiSheetField }).previous,
      state.fields[2]
    );
    await frame();
    assert.strictEqual(document.activeElement, header('qty'), 'its header');
  });

  test('FM6 changing the type shows the warning; the options form follows the type', async function (assert) {
    const state = new State();
    manage(state);
    await renderSheet(state);
    await pickItem('qty', 'EditField');
    await waitForEditorFocus();
    assert
      .dom('[data-test-subj=euiSheetFieldTypeWarning]', document.body)
      .doesNotExist();
    assert
      .dom('[data-test-subj=euiSheetFieldOptions]', document.body)
      .doesNotExist('number has none');
    await select(el(typeSel), 'singleSelect');
    assert
      .dom('[data-test-subj=euiSheetFieldTypeWarning]', document.body)
      .hasText(
        'Changing the type may change or clear values the new type cannot read.'
      );
    assert
      .dom('[data-test-subj=euiSheetFieldOptionAdd]', document.body)
      .exists('select options');
    await select(el(typeSel), 'currency');
    assert
      .dom('[data-test-subj=euiSheetFieldCurrency]', document.body)
      .hasValue('USD', 'a default code');
    assert
      .dom('[data-test-subj=euiSheetFieldOptionAdd]', document.body)
      .doesNotExist();
    await select(el(typeSel), 'number');
    assert
      .dom('[data-test-subj=euiSheetFieldTypeWarning]', document.body)
      .doesNotExist('its own type again');
    // a new field has no warning
    await press('Escape');
    await click(addHeader());
    await waitForEditorFocus();
    await select(el(typeSel), 'rating');
    assert
      .dom('[data-test-subj=euiSheetFieldTypeWarning]', document.body)
      .doesNotExist();
    assert
      .dom('[data-test-subj=euiSheetFieldRatingMax]', document.body)
      .hasValue('5');
  });

  test('FM7 select options: add, rename, recolour and remove end up in draft.options; values are kept', async function (assert) {
    const state = new State();
    const calls = manage(state);
    state.fields = [NAME, STATUS];
    await renderSheet(state);
    await pickItem('status', 'EditField');
    await waitForEditorFocus();
    const labels = () =>
      Array.from(
        document.querySelectorAll<HTMLInputElement>(
          '[data-test-subj=euiSheetFieldOptionLabel]'
        )
      );
    assert.deepEqual(
      labels().map((input) => input.value),
      ['Open', 'Closed']
    );
    await fillIn(labels()[0]!, 'Opened');
    await select(
      document.querySelectorAll(
        '[data-test-subj=euiSheetFieldOptionColor]'
      )[0]!,
      'danger'
    );
    await click(el('[data-test-subj=euiSheetFieldOptionAdd]'));
    await frame();
    assert.strictEqual(labels().length, 3);
    assert.strictEqual(
      document.activeElement,
      labels()[2],
      'the new row focused'
    );
    // typed key by key: the row keeps its input (and focus)
    await typeIn(labels()[2]!, 'Later');
    assert.strictEqual(document.activeElement, labels()[2], 'still focused');
    await click(
      document.querySelectorAll(
        '[data-test-subj=euiSheetFieldOptionRemove]'
      )[1]!
    );
    await click(el(saveSel));
    assert.deepEqual(calls.update[0]![1]['options'], [
      { value: 'o', label: 'Opened', color: 'danger' },
      { value: 'Later', label: 'Later' }
    ]);
  });

  test('FM8 a promise: Save is busy; a rejection shows its message and keeps the editor; resolving closes it', async function (assert) {
    const state = new State();
    let settle: { resolve: () => void; reject: (e: Error) => void } | null =
      null;
    state.onFieldCreate = () =>
      new Promise<void>((resolve, reject) => {
        settle = { resolve, reject };
      });
    await renderSheet(state);
    await click(addHeader());
    await waitForEditorFocus();
    await fillIn(nameInput(), 'Estado');
    await click(el(saveSel));
    assert
      .dom(saveSel, document.body)
      .hasAttribute('aria-busy', 'true', 'busy');
    // while busy, Escape, Cancel and a click outside do not close it
    await triggerKeyEvent(nameInput(), 'keydown', 'Escape');
    await click(el('[data-test-subj=euiSheetFieldCancel]'));
    await click(cell(1, 0));
    await frame();
    assert.dom(editorSel, document.body).exists('still open while saving');
    settle!.reject(new Error('That name is taken'));
    await frame();
    assert.dom(editorSel, document.body).exists('still open');
    assert
      .dom('[data-test-subj=euiSheetFieldError]', document.body)
      .hasText('That name is taken');
    assert
      .dom(saveSel, document.body)
      .doesNotHaveAttribute('aria-busy', 'not busy');
    await click(el(saveSel));
    assert
      .dom('[data-test-subj=euiSheetFieldError]', document.body)
      .doesNotExist('cleared');
    settle!.resolve();
    await frame();
    assert.dom(editorSel, document.body).doesNotExist('closed');
    assert.strictEqual(document.activeElement, addHeader());
  });

  test('FM9 Delete field asks, then calls onFieldDelete(id); not on the first field or with manageable: false', async function (assert) {
    const state = new State();
    const calls = manage(state);
    state.fields = [NAME, CITY, { ...QTY, manageable: false }];
    await renderSheet(state);
    await pickItem('city', 'DeleteField');
    await waitForEditorFocus();
    assert
      .dom('[data-test-subj=euiSheetFieldDelete]', document.body)
      .includesText('Delete "City" and its values in every record?');
    assert.deepEqual(calls.delete, [], 'asked first');
    await click(el('[data-test-subj=euiSheetFieldDeleteConfirm]'));
    assert.deepEqual(calls.delete, ['city']);
    await frame();
    assert.dom(editorSel, document.body).doesNotExist();
    assert.strictEqual(
      document.activeElement,
      header('qty'),
      'the header now at its place'
    );
    await openMenu('name');
    assert.false(menuHas('name', 'DeleteField'), 'not the first field');
    assert.true(menuHas('name', 'EditField'));
    await openMenu('qty');
    assert.false(menuHas('qty', 'DeleteField'), 'manageable: false');
    assert.false(menuHas('qty', 'EditField'));
    assert.false(menuHas('qty', 'DuplicateField'));
    assert.true(
      menuHas('qty', 'InsertFieldRight'),
      'inserting next to it is fine'
    );
  });

  test('FM10 Duplicate calls onFieldCreate with copyOf and index + 1', async function (assert) {
    const state = new State();
    const calls = manage(state);
    await renderSheet(state);
    await pickItem('city', 'DuplicateField');
    assert.dom(editorSel, document.body).doesNotExist('no editor');
    assert.deepEqual(calls.create, [
      [
        { label: 'City copy', type: 'text' },
        { index: 2, after: 'city', copyOf: 'city' }
      ]
    ]);
  });

  test('FM11 Escape cancels and focuses the header; a click outside cancels', async function (assert) {
    const state = new State();
    const calls = manage(state);
    await renderSheet(state);
    await pickItem('city', 'EditField');
    await waitForEditorFocus();
    await fillIn(nameInput(), 'Changed');
    await triggerKeyEvent(nameInput(), 'keydown', 'Escape');
    await frame();
    assert.dom(editorSel, document.body).doesNotExist('Escape');
    assert.strictEqual(document.activeElement, header('city'));
    await click(addHeader());
    await waitForEditorFocus();
    await click(el('[data-test-subj=euiSheetFieldCancel]'));
    await frame();
    assert.dom(editorSel, document.body).doesNotExist('Cancel');
    assert.strictEqual(document.activeElement, addHeader());
    await click(addHeader());
    await waitForEditorFocus();
    await click(cell(1, 0));
    await frame();
    assert.dom(editorSel, document.body).doesNotExist('a click outside');
    assert.deepEqual(calls.update, []);
    assert.deepEqual(calls.create, []);
  });

  test('FM12 ArrowRight and End stay on the last field; from the last header ArrowRight reaches "+" and Enter opens', async function (assert) {
    const state = new State();
    manage(state);
    await renderSheet(state);
    await focusCell(0, 2);
    assert.true(await pressed('ArrowRight'), "ArrowRight is the sheet's");
    assert.strictEqual(document.activeElement, cell(0, 2), 'stays');
    await focusCell(1, 0);
    await press('End');
    assert.strictEqual(document.activeElement, cell(1, 2), 'End');
    await focusCell(0, 0);
    await press('End', { ctrlKey: true });
    assert.strictEqual(
      document.activeElement,
      cell(3, 2),
      'Ctrl+End: the last row (the add row), the last field'
    );
    await focusCell(1, 1);
    await press('ArrowRight');
    assert.strictEqual(document.activeElement, cell(1, 2), 'a plain move');
    await focus(header('qty'));
    await press('ArrowRight');
    await frame();
    assert.strictEqual(document.activeElement, addHeader(), 'the "+" header');
    await press('Enter');
    await waitForEditorFocus();
    assert.dom(editorSel, document.body).exists('Enter opens');
    await press('Escape');
    await frame();
    await press(' ');
    await waitForEditorFocus();
    assert.dom(editorSel, document.body).exists('Space opens');
  });

  test('FM13 the "+" column with @frozenFields={{1}} and @summary: rendered, empty footer cell, FZ1 still holds', async function (assert) {
    const state = new State();
    manage(state);
    const wide = Array.from({ length: 8 }, (_, i) => ({
      id: `f${i}`,
      label: `Field ${i}`,
      width: 150
    }));
    state.fields = wide;
    state.records = Array.from({ length: 5 }, (_, r) => {
      const row: Row = { id: `r${r}` };
      wide.forEach((field, c) => (row[field.id] = `r${r}c${c}`));
      return row;
    });
    state.frozenFields = 1;
    state.summary = { f0: 'Five', '': 'Σ' };
    await renderSheet(state, 500);
    assert.dom(addHeader()).exists();
    const footer = el(
      `.euiDataGridFooterCell[data-gridcell-column-id="${ADD}"]`
    );
    assert.strictEqual(contentOf(footer), '', 'an empty footer cell');
    assert.notStrictEqual(footer.style.position, 'sticky', 'not sticky');
    assert
      .dom('[data-test-subj=euiSheetSummary]', footer)
      .doesNotExist('no summary in it');
    assert.dom(`[role=gridcell][data-gridcell-column-id="${ADD}"]`).exists();
    const outer = el('.euiDataGrid__virtualized');
    const first = cell(2, 0).getBoundingClientRect().left;
    outer.scrollLeft = 600;
    await triggerEvent(outer, 'scroll');
    assert.true(outer.scrollLeft > 0, 'scrolled');
    assert.ok(
      Math.abs(cell(2, 0).getBoundingClientRect().left - first) < 1,
      'the first field stays in place'
    );
    outer.scrollLeft = outer.scrollWidth;
    await triggerEvent(outer, 'scroll');
    await frame();
    assert
      .dom(
        `[role=gridcell][data-gridcell-visible-row-index="2"][data-gridcell-column-id="${ADD}"]`
      )
      .exists('the "+" body cell is rendered at the end');
  });

  test('FM14 after a field delete Ctrl+Z emits nothing for it; an entry that touched another field emits only that one', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await focusCell(0, 1);
    await type('x');
    await press('Enter');
    assert.strictEqual(state.changes.length, 1, 'the edit');
    await focusCell(1, 1);
    await clipboard('paste', 'P\t9');
    assert.strictEqual(state.changes.length, 2, 'the paste of city and qty');
    // the owner deletes the city field (and keeps the values in the records)
    state.fields = [NAME, QTY];
    await settled();
    await focusCell(0, 0);
    await pressed('z', { ctrlKey: true });
    assert.strictEqual(state.changes.length, 3, 'one undo');
    assert.deepEqual(
      state.changes[2]!.patches,
      [{ recordId: 'b', fieldId: 'qty', from: 9, to: 1 }],
      'only the qty patch of the paste'
    );
    await pressed('z', { ctrlKey: true });
    assert.strictEqual(
      state.changes.length,
      3,
      'the city edit was pruned: nothing to undo'
    );
    // a type change prunes the same way
    await focusCell(0, 1);
    await type('7');
    await press('Enter');
    assert.strictEqual(state.changes.length, 4, 'an edit of qty');
    state.fields = [NAME, { ...QTY, type: 'text' }];
    await settled();
    await focusCell(0, 0);
    await pressed('z', { ctrlKey: true });
    assert.strictEqual(
      state.changes.length,
      4,
      'qty was retyped: nothing to undo'
    );
  });

  test("FM20 without @onFieldOrderChange, a created field goes where it was inserted in the sheet's own order", async function (assert) {
    const state = new State();
    manage(state);
    await renderSheet(state);
    const ids = () =>
      Array.from(
        document.querySelectorAll<HTMLElement>('[role=columnheader]'),
        (h) => h.dataset['gridcellColumnId']
      ).filter((id) => id !== 'euiSheetRow' && id !== ADD);
    // the sheet's own order: City moved right of Qty
    await openMenu('city');
    await click(
      Array.from(
        document.querySelectorAll<HTMLElement>(
          '[data-test-subj=dataGridHeaderCellActionGroup-city] button'
        )
      ).find((b) => b.textContent?.trim() === 'Move right')!
    );
    await frame();
    assert.deepEqual(ids(), ['name', 'qty', 'city']);
    await pickItem('name', 'InsertFieldRight');
    await waitForEditorFocus();
    await fillIn(nameInput(), 'New');
    await click(el(saveSel));
    await frame();
    assert.deepEqual(
      ids(),
      ['name', 'new1', 'qty', 'city'],
      'after Name, not at the end'
    );
  });

  test('FM15 @fieldEditor gets mode, draft and types; its onSave reaches the handler', async function (assert) {
    const state = new State();
    const calls = manage(state);
    state.fieldEditor = AppEditor;
    await renderSheet(state);
    await pickItem('city', 'EditField');
    assert.dom('[data-test-app-mode]', document.body).hasText('edit');
    assert.dom('[data-test-app-label]', document.body).hasText('City');
    assert.dom('[data-test-app-types]', document.body).hasText('14');
    assert
      .dom(nameSel, document.body)
      .doesNotExist('the built-in form is replaced');
    await click(el('[data-test-app-save]'));
    assert.deepEqual(calls.update[0]!.slice(0, 2), [
      'city',
      { label: 'From app', type: 'number' }
    ]);
    await frame();
    assert.dom(editorSel, document.body).doesNotExist();
    await click(addHeader());
    assert.dom('[data-test-app-mode]', document.body).hasText('create');
  });

  test('FM16 @creatableFieldTypes limits the type select; an app type with label and fieldOptions', async function (assert) {
    const state = new State();
    const calls = manage(state);
    state.creatableFieldTypes = ['text', 'rating', 'stage', 'missing'];
    state.fieldTypes = { stage: STAGE_TYPE };
    await renderSheet(state);
    await click(addHeader());
    await waitForEditorFocus();
    assert.deepEqual(typeLabels(), ['Single line text', 'Rating', 'Stage']);
    await fillIn(nameInput(), 'Phase');
    await select(el(typeSel), 'stage');
    assert.dom('[data-test-stage-options]', document.body).exists('its form');
    await click(el('[data-test-stage-set]'));
    assert.dom('[data-test-stage-steps]', document.body).hasText('3');
    await click(el(saveSel));
    assert.deepEqual(calls.create[0]![0], {
      label: 'Phase',
      type: 'stage',
      steps: 3
    });
    // a field whose type is not creatable keeps it in the list on edit
    await pickItem('qty', 'EditField');
    await waitForEditorFocus();
    assert.deepEqual(typeLabels(), [
      'Number',
      'Single line text',
      'Rating',
      'Stage'
    ]);
  });

  test('FM17 localRecords end to end: create a number field, type in it, change it to text, duplicate it with values, delete it', async function (assert) {
    const store = localRecords<Row>(rows(), {
      getRecordId: getId,
      fields: [NAME, CITY]
    });
    await render(
      <template>
        <div style="width:900px">
          <EuiSheet
            @fields={{store.fields}}
            @records={{store.records}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @onFieldCreate={{store.createField}}
            @onFieldUpdate={{store.updateField}}
            @onFieldDelete={{store.deleteField}}
          />
        </div>
      </template>
    );
    await click(addHeader());
    await waitForEditorFocus();
    await fillIn(nameInput(), 'Score');
    await select(el(typeSel), 'number');
    await click(el(saveSel));
    await frame();
    assert.deepEqual(
      store.fields.map((field) => field.id),
      ['name', 'city', 'score']
    );
    await focusCell(0, 2);
    await type('7');
    await press('Enter');
    assert.strictEqual(store.records[0]!['score'], 7, 'a number');
    assert.strictEqual(text(0, 2), '7');

    await pickItem('score', 'EditField');
    await waitForEditorFocus();
    await select(el(typeSel), 'text');
    await click(el(saveSel));
    await frame();
    assert.strictEqual(store.records[0]!['score'], '7', 'converted to text');
    assert.strictEqual(store.fields[2]!.type, 'text');

    await pickItem('score', 'DuplicateField');
    assert.deepEqual(
      store.fields.map((field) => field.id),
      ['name', 'city', 'score', 'score-copy']
    );
    assert.strictEqual(store.records[0]!['score-copy'], '7', 'values copied');
    assert.strictEqual(text(0, 3), '7');

    await pickItem('score', 'DeleteField');
    await waitForEditorFocus();
    await click(el('[data-test-subj=euiSheetFieldDeleteConfirm]'));
    await frame();
    assert.deepEqual(
      store.fields.map((field) => field.id),
      ['name', 'city', 'score-copy']
    );
    assert.false('score' in store.records[0]!, 'the key is gone');
  });

  test('FM18 api.addField() and api.editField(id), also of a hidden field', async function (assert) {
    const state = new State();
    const calls = manage(state);
    state.hiddenFields = [NOTES];
    await renderSheet(state);
    state.api!.addField({ index: 1 });
    await waitForEditorFocus();
    assert
      .dom('.euiSheetFieldEditor__title', document.body)
      .hasText('Add field');
    await fillIn(nameInput(), 'Second');
    await click(el(saveSel));
    assert.deepEqual(calls.create[0]![1], { index: 1, after: 'name' });
    await frame();
    state.api!.addField({ index: 0 });
    await waitForEditorFocus();
    await fillIn(nameInput(), 'Never first');
    await click(el(saveSel));
    assert.deepEqual(
      calls.create[1]![1],
      { index: 1, after: 'name' },
      'nothing goes before the first field'
    );
    await frame();
    state.api!.editField('qty');
    await waitForEditorFocus();
    assert.dom(nameInput()).hasValue('Qty');
    await press('Escape');
    await frame();
    state.api!.editField('notes');
    await waitForEditorFocus();
    assert.dom(nameInput()).hasValue('Notes', 'a hidden field');
    await click(el(saveSel));
    assert.strictEqual(calls.update[0]![0], 'notes');
  });

  test('FM19 the add row and a selected range with the "+" column: its cells take the row\'s look', async function (assert) {
    const state = new State();
    manage(state);
    await renderSheet(state);
    const addRowCells = Array.from(
      document.querySelectorAll<HTMLElement>(
        '.euiSheet__addRow [role=gridcell]'
      )
    );
    const plusCell = addRowCells.find(
      (c) => c.dataset['gridcellColumnId'] === ADD
    );
    assert.ok(plusCell, 'the add row has a "+" column cell');
    const colors = new Set(
      addRowCells.map((c) => getComputedStyle(c).backgroundColor)
    );
    assert.strictEqual(
      colors.size,
      1,
      `one background (${[...colors].join(' | ')})`
    );
    assert
      .dom(plusCell!)
      .hasNoClass('euiSheet__rowCell', 'not a row-number cell');
    // a range over a whole row: the "+" cell is not part of it
    await click(
      el(
        '[role=gridcell][data-gridcell-visible-row-index="1"][data-gridcell-column-index="0"]'
      )
    );
    const rowPlus = el(
      `[role=gridcell][data-gridcell-visible-row-index="1"][data-gridcell-column-id="${ADD}"]`
    );
    assert.dom(rowPlus).hasNoClass('euiSheet__cell--selected');
    assert.dom(cell(1, 2)).hasClass('euiSheet__cell--selected');
    assert.strictEqual(contentOf(rowPlus), '', 'empty');
    // a click on a "+" body cell lands on the row's last field
    await click(rowPlus);
    await frame();
    assert.strictEqual(document.activeElement, cell(1, 2));
  });
});
