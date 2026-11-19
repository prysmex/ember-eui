/**
 * App field types through `@fieldTypes`: a custom cell, a custom editor,
 * an editor with a part rendered elsewhere (C1-C3, PACKAGE-DESIGN.md 10.4),
 * and the built-in date type with another editor (C4, decision Q2).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  blur,
  click,
  fillIn,
  focus,
  render,
  waitUntil
} from '@ember/test-helpers';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { schedule } from '@ember/runloop';
import { modifier } from 'ember-modifier';

import EuiSheet from '#src/components/eui-sheet.gts';
import { dateType, SheetInputEditor } from '#src/field-types.ts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  editor,
  editorFrame,
  el,
  focusCell,
  press,
  text,
  type
} from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type {
  EuiSheetFieldType,
  SheetCellSignature,
  SheetEditorSignature
} from '#src/types.ts';

interface Row {
  id: string;
  name: string;
  rating: number | null;
  pick: string;
  due: string | null;
}

const getId = (record: { id: string }) => record.id;
const rows = (): Row[] =>
  Array.from({ length: 3 }, (_, i) => ({
    id: `r${i}`,
    name: `name${i}`,
    rating: i,
    pick: `p${i}`,
    due: null
  }));

/* C1: a cell component and navKey, no editor ------------------------------ */

const seenCellArgs: Array<{ value: unknown; text: string; fieldId: string }> =
  [];

class RatingCell extends Component<SheetCellSignature<number | null>> {
  get stars(): number[] {
    seenCellArgs.push({
      value: this.args.value,
      text: this.args.text,
      fieldId: this.args.field.id
    });
    return [1, 2, 3, 4, 5];
  }

  <template>
    {{#each this.stars as |star|}}
      <span
        data-test-star={{star}}
        role="img"
        aria-label="{{star}} stars"
        {{on "click" (fn @onCommit star)}}
      >*</span>
    {{/each}}
  </template>
}

const ratingType: EuiSheetFieldType<number | null> = {
  parse: (text) =>
    text.trim() === ''
      ? { value: null }
      : /^[0-5]$/.test(text.trim())
        ? { value: Number(text.trim()) }
        : { error: 'Not a rating' },
  format: (value) => (value == null ? '' : `${value}/5`),
  navKey: (key) => (/^[0-5]$/.test(key) ? { value: Number(key) } : undefined),
  cell: RatingCell
};

/* C2: an editor that claims keys ----------------------------------------- */

const editorLog: {
  draft?: string;
  initialKey?: string | null;
  record?: unknown;
  keys: string[];
} = { keys: [] };

class PickEditor extends Component<SheetEditorSignature<string>> {
  count = 0;

  setup = modifier((input: HTMLInputElement) => {
    editorLog.draft = this.args.draft;
    editorLog.initialKey = this.args.initialKey;
    editorLog.record = this.args.record;
    input.focus();
  });

  onKeyDown = (event: KeyboardEvent): void => {
    editorLog.keys.push(event.key);
    if (event.key === 'ArrowDown') this.count++;
    if (event.key === 'Enter') {
      this.args.onCommit({ value: `picked-${this.count}` }, { move: [0, 1] });
    }
  };

  commitText = (): void => {
    this.args.onCommit({ text: 'typed' });
  };

  <template>
    <input
      aria-label="Pick"
      data-test-pick-input
      {{on "keydown" this.onKeyDown}}
      {{this.setup}}
    />
    <button
      type="button"
      data-test-pick-text
      {{on "click" this.commitText}}
    >Text</button>
  </template>
}

const pickType: EuiSheetFieldType<string> = {
  parse: (text) => ({ value: `parsed:${text}` }),
  format: (value) => value ?? '',
  editor: PickEditor,
  handlesKey: (event) => event.key === 'ArrowDown' || event.key === 'Enter'
};

/* C3: an editor with a part rendered outside the wrapper ------------------ */

class SurfaceEditor extends Component<SheetEditorSignature<string>> {
  get destination(): HTMLElement {
    return document.querySelector<HTMLElement>('#ember-testing')!;
  }

  focusOnInsert = modifier((input: HTMLInputElement) => input.focus());

  <template>
    <input
      aria-label="Surface"
      data-test-surface-input
      {{this.focusOnInsert}}
    />
    {{#in-element this.destination insertBefore=null}}
      <div data-eui-sheet-editor-surface data-test-surface>
        <button type="button" data-test-surface-button>In the surface</button>
      </div>
    {{/in-element}}
  </template>
}

const surfaceType: EuiSheetFieldType<string> = {
  parse: (text) => ({ value: text }),
  format: (value) => value ?? '',
  editor: SurfaceEditor
};

/* C4: the date type with another picker ---------------------------------- */

const pickerLog: { initialKey?: string | null; value?: unknown } = {};

/** Stands in for a calendar such as @ember-eui/flatpickr's, appended outside the sheet. */
class FakeDatePicker extends Component<SheetEditorSignature<string | null>> {
  get destination(): HTMLElement {
    return document.querySelector<HTMLElement>('#ember-testing')!;
  }

  record = modifier((input: HTMLInputElement) => {
    pickerLog.initialKey = this.args.initialKey;
    pickerLog.value = this.args.value;
    input.focus();
  });

  pick = (iso: string): void => {
    this.args.onCommit({ value: iso });
  };

  <template>
    {{#if @initialKey}}
      <SheetInputEditor
        @value={{@value}}
        @field={{@field}}
        @record={{@record}}
        @draft={{@draft}}
        @initialKey={{@initialKey}}
        @onDraftChange={{@onDraftChange}}
        @onCommit={{@onCommit}}
        @onCancel={{@onCancel}}
        @messages={{@messages}}
      />
    {{else}}
      <input aria-label="Due" data-test-fake-picker {{this.record}} />
      {{#in-element this.destination insertBefore=null}}
        <div class="euiSheetEditorSurface" data-test-fake-calendar>
          <button
            type="button"
            data-test-day="2026-11-21"
            {{on "click" (fn this.pick "2026-11-21")}}
          >21</button>
        </div>
      {{/in-element}}
    {{/if}}
  </template>
}

/* C5, C6: an editor that removes its own focused element ------------------ */

/**
 * Stands in for flatpickr, which redraws its days when one is picked: the
 * focused day is removed from the DOM (a focusout with no relatedTarget),
 * and the date is saved after the redraw.
 */
class RedrawingPicker extends Component<SheetEditorSignature<string | null>> {
  @tracked generation = 0;

  get destination(): HTMLElement {
    return document.querySelector<HTMLElement>('#ember-testing')!;
  }

  get days(): string[] {
    return [`d${this.generation}-a`, `d${this.generation}-b`];
  }

  focusOnInsert = modifier((input: HTMLInputElement) => input.focus());

  /** Redraws the days (the focused one is removed), then saves after the render. */
  pick = (day: string): void => {
    this.generation++;
    schedule('afterRender', () => this.args.onCommit({ value: day }));
  };

  /** Redraws without saving (e.g. moving to the next month). */
  redraw = (): void => {
    this.generation++;
  };

  <template>
    <input aria-label="Day" data-test-redraw-input {{this.focusOnInsert}} />
    <button
      type="button"
      data-test-redraw-next
      {{on "click" this.redraw}}
    >Next</button>
    {{#in-element this.destination insertBefore=null}}
      <div class="euiSheetEditorSurface" data-test-redraw-calendar>
        {{#each this.days key="@identity" as |day|}}
          <button
            type="button"
            data-test-redraw-day
            {{on "click" (fn this.pick day)}}
          >{{day}}</button>
        {{/each}}
      </div>
    {{/in-element}}
  </template>
}

const redrawType: EuiSheetFieldType<string | null> = {
  parse: (text) => ({ value: text || null }),
  format: (value) => value ?? '',
  editor: RedrawingPicker
};

const FIELD_TYPES: Record<string, EuiSheetFieldType<any, any>> = {
  rating: ratingType,
  pick: pickType,
  surface: surfaceType,
  date: { ...dateType, editor: FakeDatePicker },
  redraw: redrawType
};

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name' },
  { id: 'rating', type: 'rating' },
  { id: 'pick', type: 'pick' },
  { id: 'name2', type: 'surface' },
  { id: 'due', type: 'date' },
  { id: 'day', type: 'redraw' }
];

module('Integration | Component | EuiSheet custom type', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    seenCellArgs.length = 0;
    editorLog.keys = [];
  });

  async function renderSheet() {
    const store = localRecords<Row>(rows(), { getRecordId: getId });
    await render(
      <template>
        <div style="width:900px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @fieldTypes={{FIELD_TYPES}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('C1 a cell component and navKey', async function (assert) {
    const store = await renderSheet();
    assert.dom('[data-test-star]', cell(1, 1)).exists({ count: 5 });
    assert.true(
      seenCellArgs.some(
        (args) =>
          args.value === 1 && args.text === '1/5' && args.fieldId === 'rating'
      ),
      'the cell gets @value, @text and @field'
    );
    await focusCell(0, 1);
    await type('3');
    assert.strictEqual(editorFrame(), null, 'no editor');
    await click(el('[data-test-star="5"]', cell(2, 1)));
    assert.deepEqual(
      store.log.map((set) => set.patches),
      [
        [{ recordId: 'r0', fieldId: 'rating', from: 0, to: 3 }],
        [{ recordId: 'r2', fieldId: 'rating', from: 2, to: 5 }]
      ]
    );
  });

  test('C2 an editor that claims keys and commits itself', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 2);
    await type('x');
    assert.ok(el('[data-test-pick-input]'), 'the app editor is open');
    assert.strictEqual(editorLog.initialKey, 'x');
    assert.strictEqual(editorLog.draft, 'x');
    assert.strictEqual((editorLog.record as Row).id, 'r0', '@record');

    await press('ArrowDown');
    await press('ArrowDown');
    assert.ok(editorFrame(), 'ArrowDown does not close it');
    await press('Enter');
    assert.deepEqual(
      editorLog.keys,
      ['ArrowDown', 'ArrowDown', 'Enter'],
      'the keys reached the editor'
    );
    assert.deepEqual(
      store.log.map((set) => set.patches),
      [[{ recordId: 'r0', fieldId: 'pick', from: 'p0', to: 'picked-2' }]]
    );
    assert.strictEqual(editorFrame(), null);
    await waitUntil(() => document.activeElement === cell(0, 3));
    assert.strictEqual(document.activeElement, cell(0, 3), 'focus moved right');

    await focusCell(1, 2);
    await press('Enter');
    assert.strictEqual(editorLog.initialKey, null, 'opened with Enter');
    assert.strictEqual(
      editorLog.draft,
      'p1',
      'the draft is the formatted value'
    );
    await press('Escape');
    assert.strictEqual(editorFrame(), null, 'Escape (not claimed) cancels');
    assert.strictEqual(store.log.length, 1);
    await waitUntil(() => document.activeElement === cell(1, 2));

    await press('Enter');
    await click('[data-test-pick-text]');
    assert.deepEqual(
      store.log[1]!.patches,
      [{ recordId: 'r1', fieldId: 'pick', from: 'p1', to: 'parsed:typed' }],
      '@onCommit({ text }) goes through parse'
    );
  });

  test('C3 an editor surface outside the wrapper', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 3);
    await press('Enter');
    const surface = el('[data-test-surface]');
    assert.false(
      el('[data-test-subj=euiSheet]').contains(surface),
      'the surface is outside the wrapper'
    );
    await focus('[data-test-surface-button]');
    assert.ok(editorFrame(), 'focus in the surface keeps the editor open');
    await focus(el('[data-test-surface-input]'));
    assert.ok(editorFrame(), 'and back');
    await focus('[data-test-surface-button]');
    await focusCell(1, 0);
    assert.strictEqual(editorFrame(), null, 'focusing a grid cell closes it');
    assert.dom('[data-test-surface]').doesNotExist();
    assert.strictEqual(store.log.length, 0, 'nothing was typed');
    assert.strictEqual(document.activeElement, cell(1, 0));
  });

  test('C4 the date type with another date picker', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 4);
    await press('Enter');
    assert.ok(
      el('[data-test-fake-picker]'),
      'the app editor replaces the native input'
    );
    assert.strictEqual(pickerLog.initialKey, null);
    await click('[data-test-day="2026-11-21"]');
    assert.deepEqual(
      store.log.map((set) => set.patches),
      [[{ recordId: 'r0', fieldId: 'due', from: null, to: '2026-11-21' }]]
    );
    assert.strictEqual(editorFrame(), null);
    assert.strictEqual(
      text(0, 4),
      '21/11/2026',
      "the built-in type's format still applies"
    );

    await focusCell(1, 4);
    await type('2');
    assert.dom(editor()).hasAttribute('type', 'text');
    assert.strictEqual(
      editor()?.value,
      '2',
      'typing a digit opens the text input'
    );
    await fillIn(editor()!, '3/4/2026');
    await press('Enter');
    assert.deepEqual(store.log[1]!.patches, [
      { recordId: 'r1', fieldId: 'due', from: null, to: '2026-04-03' }
    ]);
    await focusCell(2, 4);
    await type('x');
    assert.strictEqual(
      editorFrame(),
      null,
      "dateType's opensOnKey still applies"
    );
  });

  test('C5 a pick that removes the focused element is saved', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 5);
    await press('Enter');
    assert.ok(el('[data-test-redraw-input]'), 'the editor is open');
    // click() focuses the day first; the pick redraws the days, which
    // removes the focused one, and saves after the render
    await click('[data-test-redraw-day]');
    assert.deepEqual(
      store.log.map((set) => set.patches),
      [[{ recordId: 'r0', fieldId: 'day', from: undefined, to: 'd0-a' }]],
      'the picked value is saved, not the draft'
    );
    assert.strictEqual(editorFrame(), null, 'the pick closed the editor');
    assert.strictEqual(text(0, 5), 'd0-a');
  });

  test('C6 removing the focused element keeps the editor open', async function (assert) {
    const store = await renderSheet();
    await focusCell(1, 5);
    await press('Enter');
    await focus('[data-test-redraw-day]');
    assert.ok(editorFrame(), 'focus in the surface keeps the editor open');

    // the days are redrawn while one is focused (a native click does not
    // move focus): the focused day leaves the DOM, nothing is saved
    el('[data-test-redraw-next]').click();
    await waitUntil(
      () => document.activeElement === el('[data-test-redraw-input]')
    );
    assert.ok(
      editorFrame(),
      'the removed focused day does not close the editor'
    );
    assert.strictEqual(
      document.activeElement,
      el('[data-test-redraw-input]'),
      'focus is given back to the editor'
    );
    assert.strictEqual(store.log.length, 0, 'nothing was saved');

    await blur(el('[data-test-redraw-input]'));
    assert.strictEqual(
      editorFrame(),
      null,
      'focus leaving to nowhere still closes the editor'
    );
  });
});
