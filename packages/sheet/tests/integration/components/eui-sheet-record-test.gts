/** The expanded record (V02-DESIGN.md 5.7): a flyout or a modal with one shared form. */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  fillIn,
  render,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';

import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import EuiSheet from '#src/components/eui-sheet.gts';
import { textType } from '#src/field-types.ts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  editor,
  editorFrame,
  el,
  focusCell,
  isInvalid,
  pressed,
  text
} from '../../helpers/sheet.ts';

import type {
  CellErrors,
  EuiSheetField,
  RecordId,
  SheetOption
} from '#src/core/index.ts';
import type { EuiSheetFieldType, SheetEditorSignature } from '#src/types.ts';

/**
 * An editor with a part rendered elsewhere (like flatpickr's calendar):
 * an input in the frame and a surface in the body with a button that picks.
 */
class SurfaceEditor extends Component<SheetEditorSignature<string, any>> {
  get destination(): HTMLElement {
    return document.body;
  }

  setup = modifier((input: HTMLInputElement) => input.focus());

  pick = () => this.args.onCommit({ value: 'picked' });

  <template>
    <input class="euiSheet__input" value={{@draft}} {{this.setup}} />
    {{#in-element this.destination insertBefore=null}}
      <div data-eui-sheet-editor-surface class="testSurface {{@themeClass}}">
        <button
          type="button"
          data-test-subj="surfacePick"
          {{on "click" this.pick}}
        >pick</button>
      </div>
    {{/in-element}}
  </template>
}

const surfaceType: EuiSheetFieldType<string, any> = {
  ...textType,
  editor: SurfaceEditor
};

interface Task {
  id: string;
  name: string;
  qty: number | null;
  done: boolean;
  status: string | null;
  notes?: string;
  code?: string;
}

const STATUS: SheetOption[] = [
  { value: 'open', label: 'Open' },
  { value: 'closed', label: 'Closed' }
];

const FIELDS: EuiSheetField<Task>[] = [
  { id: 'name', label: 'Name' },
  { id: 'qty', label: 'Qty', type: 'number' },
  { id: 'done', label: 'Done', type: 'checkbox' },
  { id: 'status', label: 'Status', type: 'singleSelect', options: STATUS }
];
const HIDDEN: EuiSheetField<Task>[] = [
  { id: 'notes', label: 'Notes' },
  { id: 'code', label: 'Code', readOnly: true }
];

const tasks = (count: number): Task[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `r${i}`,
    name: `name${i}`,
    qty: i,
    done: false,
    status: 'open',
    notes: `note${i}`,
    code: `c${i}`
  }));

const getId = (task: { id: string }) => task.id;

class State {
  @tracked shell: 'flyout' | 'modal' | undefined = undefined;
  fields: EuiSheetField<Task>[] = FIELDS;
  fieldTypes: Record<string, EuiSheetFieldType<any, any>> | undefined =
    undefined;
  @tracked cellErrors: CellErrors | undefined = undefined;
  @tracked expandedId: RecordId | null = null;
  onExpanded: ((id: RecordId | null) => void) | undefined = undefined;
  validate:
    ((context: { records: readonly Task[] }) => CellErrors) | undefined =
    undefined;
}

function shell(): HTMLElement | null {
  return document.querySelector<HTMLElement>('[data-test-subj=euiSheetRecord]');
}

function box(fieldId: string): HTMLElement {
  return el(`[data-eui-sheet-record-box="${fieldId}"]`, document.body);
}

function labels(): string[] {
  return Array.from(
    shell()?.querySelectorAll<HTMLElement>('.euiSheetRecord__label') ?? []
  ).map((label) => label.textContent?.trim() ?? '');
}

function title(): string {
  return (
    shell()
      ?.querySelector('[data-test-subj=euiSheetRecordTitle]')
      ?.textContent?.trim() ?? ''
  );
}

/** A key on an element (a box or the editor's input). */
async function key(
  target: Element,
  value: string,
  modifiers: { shiftKey?: boolean; ctrlKey?: boolean } = {}
): Promise<boolean> {
  const event = new KeyboardEvent('keydown', {
    key: value,
    bubbles: true,
    cancelable: true,
    ...modifiers
  });
  target.dispatchEvent(event);
  await settled();
  return event.defaultPrevented;
}

const editorCount = () =>
  document.querySelectorAll('[data-test-subj=euiSheetEditor]').length;

module('Integration | Component | EuiSheet expanded record', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(state = new State(), count = 4) {
    const store = localRecords<Task>(tasks(count), { getRecordId: getId });
    await render(
      <template>
        <div style="width:800px">
          <EuiSheet
            @records={{store.records}}
            @fields={{state.fields}}
            @fieldTypes={{state.fieldTypes}}
            @hiddenFields={{HIDDEN}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @cellErrors={{state.cellErrors}}
            @validate={{state.validate}}
            @expandedRecord={{state.shell}}
            @expandedRecordId={{state.expandedId}}
            @onExpandedRecordChange={{state.onExpanded}}
          />
        </div>
      </template>
    );
    return store;
  }

  async function openOn(row: number, col = 0) {
    await focusCell(row, col);
    await pressed(' ');
    await waitUntil(() => shell());
  }

  test('RF1 Space opens the flyout: the visible fields, then the hidden ones', async function (assert) {
    await renderSheet();
    await openOn(1);
    assert.strictEqual(
      shell()!.dataset['euiSheetRecord'],
      'flyout',
      'flyout by default'
    );
    assert.false(
      el('[data-test-subj=euiSheet]').contains(shell()),
      'portaled, outside the sheet'
    );
    assert.deepEqual(labels(), [
      'Name',
      'Qty',
      'Done',
      'Status',
      'Notes',
      'Code'
    ]);
    assert.strictEqual(title(), 'name1', 'the first field is the title');
    assert.strictEqual(box('notes').textContent?.trim(), 'note1');
    assert.true(
      shell()!.classList.toString().includes('euiSheetRecord'),
      'the shell class'
    );
  });

  test('RF2 a text box: the editor opens inline, Enter saves and focuses the next box', async function (assert) {
    const store = await renderSheet();
    await openOn(0);
    box('name').focus();
    await key(box('name'), 'x');
    assert.ok(editor(), 'an inline editor');
    assert.true(shell()!.contains(editorFrame()), 'inside the form');
    assert.strictEqual(editor()!.value, 'x', 'seeded with the key');
    await fillIn(editor()!, 'xyz');
    await key(editor()!, 'Enter');
    assert.strictEqual(editor(), null, 'closed');
    assert.deepEqual(
      store.log.map((set) => [set.source, set.patches]),
      [
        [
          'edit',
          [{ recordId: 'r0', fieldId: 'name', from: 'name0', to: 'xyz' }]
        ]
      ]
    );
    await settled();
    assert.strictEqual(document.activeElement, box('qty'), 'the next box');
    assert.strictEqual(box('name').textContent?.trim(), 'xyz');
    assert.strictEqual(text(0, 0), 'xyz', 'the grid too');
    assert.strictEqual(title(), 'xyz');

    // Escape in the editor cancels, and the shell stays open
    await key(box('qty'), 'Enter');
    await fillIn(editor()!, '77');
    await key(editor()!, 'Escape');
    assert.ok(shell(), 'still open');
    assert.strictEqual(editor(), null);
    assert.strictEqual(store.log.length, 1, 'nothing saved');
    await settled();
    assert.strictEqual(document.activeElement, box('qty'));

    // a hidden field is edited the same way
    await key(box('notes'), 'Enter');
    await fillIn(editor()!, 'hidden!');
    await key(editor()!, 'Enter');
    assert.strictEqual(store.records[0]!.notes, 'hidden!');
  });

  test('RF3 a select box: the panel in flow, picked with the keyboard', async function (assert) {
    const store = await renderSheet();
    await openOn(0);
    await key(box('status'), 'Enter');
    const frame = editorFrame()!;
    assert.ok(frame, 'the panel');
    assert.dom(frame).hasClass('euiSheet__editor--inline');
    assert.strictEqual(
      getComputedStyle(frame).position,
      'relative',
      'in flow, not absolute'
    );
    assert.ok(box('status'), 'the box stays above the panel');
    await key(editor()!, 'ArrowDown');
    await key(editor()!, 'Enter');
    assert.deepEqual(store.log[0]!.patches, [
      { recordId: 'r0', fieldId: 'status', from: 'open', to: 'closed' }
    ]);
    assert.strictEqual(editorFrame(), null);
    await settled();
    assert.strictEqual(
      document.activeElement,
      box('notes'),
      'Enter: the next box'
    );

    // Tab (the select editor's own key) also moves on
    await key(box('status'), 'Enter');
    await key(editor()!, 'Tab');
    assert.strictEqual(editorFrame(), null);
    await settled();
    assert.strictEqual(
      document.activeElement,
      box('notes'),
      'Tab: the next box'
    );
    await key(box('status'), 'Enter');
    await key(editor()!, 'Tab', { shiftKey: true });
    await settled();
    assert.strictEqual(
      document.activeElement,
      box('done'),
      'Shift+Tab: the previous box'
    );
  });

  test('RF4 a checkbox box: click and Space toggle', async function (assert) {
    const store = await renderSheet();
    await openOn(0);
    await click(box('done'));
    assert.true(store.records[0]!.done, 'click');
    box('done').focus();
    assert.true(await key(box('done'), ' '), 'Space is prevented');
    assert.false(store.records[0]!.done, 'Space');
    assert.strictEqual(editorFrame(), null, 'no editor');
    assert.strictEqual(store.log.length, 2);

    // Delete on a box clears the field
    box('name').focus();
    assert.true(await key(box('name'), 'Delete'), 'Delete is prevented');
    assert.strictEqual(store.records[0]!.name, '', 'cleared');
    assert.strictEqual(store.log[2]!.source, 'clear');
  });

  test('RF5 a rejected text shows under the box and in the grid cell', async function (assert) {
    const store = await renderSheet();
    await openOn(0);
    await key(box('qty'), 'Enter');
    await fillIn(editor()!, 'abc');
    await key(editor()!, 'Enter');
    assert.deepEqual(
      store.log[0]!.rejected.map((r) => r.text),
      ['abc']
    );
    assert.strictEqual(box('qty').textContent?.trim(), 'abc');
    assert.dom(box('qty')).hasClass('euiSheetRecord__box--invalid');
    assert
      .dom('[data-test-subj=euiSheetRecordErrors]', box('qty').parentElement!)
      .hasText('"abc" is not a number');
    assert.true(isInvalid(0, 1), 'the grid cell');
    assert.strictEqual(text(0, 1), 'abc');
  });

  test('RF6 @validate and @cellErrors show under the box', async function (assert) {
    const state = new State();
    state.validate = ({ records }) =>
      Object.fromEntries(
        records
          .filter((task) => task.name === 'bad')
          .map((task) => [task.id, { name: 'no bad names' }])
      );
    state.cellErrors = { r0: { notes: 'server says no' } };
    await renderSheet(state);
    await openOn(0);
    const errorsOf = (fieldId: string) =>
      box(fieldId)
        .parentElement!.querySelector('[data-test-subj=euiSheetRecordErrors]')
        ?.textContent?.trim();
    assert.strictEqual(errorsOf('notes'), 'server says no', 'a hidden field');
    await key(box('name'), 'Enter');
    await fillIn(editor()!, 'bad');
    await key(editor()!, 'Enter');
    await settled();
    assert.strictEqual(errorsOf('name'), 'no bad names');
  });

  test('RF7 a read-only field', async function (assert) {
    const store = await renderSheet();
    await openOn(0);
    const code = box('code');
    assert.strictEqual(code.getAttribute('role'), null, 'no button role');
    assert.strictEqual(code.getAttribute('tabindex'), null, 'not focusable');
    await click(code);
    await key(code, 'x');
    assert.strictEqual(editorFrame(), null);
    assert.strictEqual(store.log.length, 0);
  });

  test('RF8 previous and next', async function (assert) {
    await renderSheet(new State(), 3);
    await openOn(1);
    const previous = el(
      '[data-test-subj=euiSheetRecordPrevious]',
      document.body
    );
    const next = el('[data-test-subj=euiSheetRecordNext]', document.body);
    await click(next);
    assert.strictEqual(title(), 'name2');
    assert.dom(next).isDisabled('at the end');
    await click(previous);
    await click(previous);
    assert.strictEqual(title(), 'name0');
    assert.dom(previous).isDisabled('at the start');
  });

  test('RF9 closing returns focus to the cell it was opened from', async function (assert) {
    await renderSheet();
    await openOn(2, 1);
    await key(box('name'), 'Escape');
    assert.strictEqual(shell(), null, 'Escape on a box closes');
    await waitUntil(() => document.activeElement === cell(2, 1));
    assert.strictEqual(document.activeElement, cell(2, 1));

    // (column 2 is the checkbox: its Space toggles)
    await openOn(1, 3);
    await click(el('[data-test-subj=euiFlyoutCloseButton]', document.body));
    assert.strictEqual(shell(), null);
    await waitUntil(() => document.activeElement === cell(1, 3));
    assert.strictEqual(document.activeElement, cell(1, 3), 'the close button');
  });

  test('RF10 controlled @expandedRecordId', async function (assert) {
    const state = new State();
    const calls: Array<RecordId | null> = [];
    state.onExpanded = (id) => calls.push(id);
    await renderSheet(state);
    await focusCell(1, 0);
    await pressed(' ');
    assert.deepEqual(calls, ['r1'], 'the handler gets the id');
    assert.strictEqual(shell(), null, 'nothing until the owner says');
    state.expandedId = 'r3';
    await settled();
    assert.strictEqual(title(), 'name3', 'the owner’s id');
    await key(box('name'), 'Escape');
    assert.deepEqual(calls, ['r1', null]);
    assert.ok(shell(), 'still the owner’s');
    state.expandedId = null;
    await settled();
    assert.strictEqual(shell(), null);
  });

  test('RF11 Ctrl+Z in the form undoes, focus stays in the form', async function (assert) {
    const store = await renderSheet();
    await openOn(0);
    await key(box('name'), 'Enter');
    await fillIn(editor()!, 'changed');
    await key(editor()!, 'Enter');
    await settled();
    assert.strictEqual(store.records[0]!.name, 'changed');
    const focused = document.activeElement;
    assert.true(await key(box('qty'), 'z', { ctrlKey: true }), 'prevented');
    assert.strictEqual(store.records[0]!.name, 'name0', 'undone');
    assert.strictEqual(box('name').textContent?.trim(), 'name0');
    assert.strictEqual(document.activeElement, focused, 'focus stays');
    await key(box('qty'), 'Z', { ctrlKey: true, shiftKey: true });
    assert.strictEqual(store.records[0]!.name, 'changed', 'redone');
  });

  test('RF12 one editor at a time', async function (assert) {
    const store = await renderSheet();
    await openOn(0);
    await key(box('name'), 'Enter');
    await fillIn(editor()!, 'first');
    assert.strictEqual(editorCount(), 1);
    // opening another box: the first commits on focus-out
    await click(box('notes'));
    assert.strictEqual(editorCount(), 1, 'still one');
    assert.strictEqual(store.records[0]!.name, 'first', 'the first was saved');
    assert.true(
      el('[data-test-subj=euiSheetRecordField-notes]', document.body).contains(
        editorFrame()
      ),
      'the new one is the notes editor'
    );
  });

  test('RF13 the record leaves @records: the form closes', async function (assert) {
    const store = await renderSheet();
    await openOn(1);
    store.records = store.records.filter((task) => task.id !== 'r1');
    await settled();
    assert.strictEqual(shell(), null);
  });

  test('RF14 @expandedRecord="modal": the same form in a modal', async function (assert) {
    const state = new State();
    state.shell = 'modal';
    const store = await renderSheet(state);
    await openOn(0, 1);
    assert.strictEqual(shell()!.dataset['euiSheetRecord'], 'modal');
    assert.deepEqual(labels(), [
      'Name',
      'Qty',
      'Done',
      'Status',
      'Notes',
      'Code'
    ]);
    await key(box('name'), 'x');
    await fillIn(editor()!, 'modal');
    await key(editor()!, 'Enter');
    assert.strictEqual(store.records[0]!.name, 'modal', 'RF2 in a modal');
    await settled();
    assert.strictEqual(document.activeElement, box('qty'));
    await key(box('qty'), 'Enter');
    await key(editor()!, 'Escape');
    assert.ok(shell(), 'an editor’s Escape does not close the modal');
    await key(box('qty'), 'Escape');
    assert.strictEqual(shell(), null, 'RF9: Escape on a box closes');
    await waitUntil(() => document.activeElement === cell(0, 1));
    assert.strictEqual(document.activeElement, cell(0, 1));
  });

  test('RF15 the expand icon and Enter on a row number open the record', async function (assert) {
    await renderSheet();
    const rowCell = (row: number) =>
      el(
        `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"]`
      );
    await click(el('[data-test-subj=euiSheetRowExpand]', rowCell(2)));
    assert.strictEqual(title(), 'name2', 'the expand icon');
    await key(box('name'), 'Escape');
    await waitUntil(() => document.activeElement === rowCell(2));
    assert.strictEqual(
      document.activeElement,
      rowCell(2),
      'back to the row number'
    );
    await triggerKeyEvent(rowCell(2), 'keydown', 'Enter');
    assert.strictEqual(title(), 'name2', 'Enter on a row number');
  });
  for (const shellName of ['flyout', 'modal'] as const) {
    test(`RF16 an editor surface rendered outside the ${shellName} keeps focus and picks (N3)`, async function (assert) {
      const state = new State();
      state.shell = shellName;
      state.fields = [
        ...FIELDS,
        { id: 'pick', label: 'Pick', type: 'surface' }
      ];
      state.fieldTypes = { surface: surfaceType };
      const store = await renderSheet(state);
      await openOn(0);
      await key(box('pick'), 'Enter');
      const button = el('[data-test-subj=surfacePick]', document.body);
      assert.false(
        shell()!.contains(button),
        'the surface is outside the shell'
      );
      button.focus();
      await new Promise((resolve) => setTimeout(resolve, 100));
      await settled();
      assert.strictEqual(
        document.activeElement,
        button,
        'the shell’s focus trap lets focus reach the surface'
      );
      assert.ok(editorFrame(), 'the editor stays open');
      await click(button);
      assert.deepEqual(store.log.at(-1)!.patches, [
        { recordId: 'r0', fieldId: 'pick', from: undefined, to: 'picked' }
      ]);
      assert.ok(shell(), 'the shell stays open');
    });
  }
});
