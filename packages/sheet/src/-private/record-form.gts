/**
 * The expanded record's content (V02-DESIGN.md 5.7), shared by the flyout
 * and the modal: the fields of `@fields`, then those of `@hiddenFields`,
 * each a label and a box. One editor at a time is mounted inline in its
 * field (V7). The shells are portaled, outside the sheet's wrapper, so the
 * form handles its own keys.
 */
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { next } from '@ember/runloop';
import { modifier } from 'ember-modifier';

import { isReadOnly, valueOf } from '../core/index.ts';
import RecordFormField from './record-form-field.gts';

import type EuiSheet from '../components/eui-sheet.gts';
import type { EuiSheetField } from '../core/index.ts';
import type { EuiSheetFieldType, SheetEditorResult } from '../types.ts';

/** The editor open in the form. */
export class FormEditing {
  /** The record it edits: the shell may move to another one meanwhile. */
  record: unknown;
  fieldId: string;
  initialKey: string | null;
  draft: string;
  /** Plain: the last text (or value) the editor reported, and whether it reported one. */
  latest: string;
  latestValue: unknown = undefined;
  kind: 'text' | 'value' = 'text';
  dirty = false;

  constructor(
    record: unknown,
    fieldId: string,
    initialKey: string | null,
    draft: string
  ) {
    this.record = record;
    this.fieldId = fieldId;
    this.initialKey = initialKey;
    this.draft = draft;
    this.latest = draft;
  }
}

interface RecordFormSignature {
  Args: {
    sheet: EuiSheet<any>;
    record: unknown;
  };
}

export default class RecordForm extends Component<RecordFormSignature> {
  @tracked _editing: FormEditing | null = null;

  /** The open editor; the shell pauses its focus trap meanwhile (N3). */
  get editing(): FormEditing | null {
    return this._editing;
  }

  set editing(editing: FormEditing | null) {
    this._editing = editing;
    this.sheet.formEditorOpen = editing !== null;
  }
  element: HTMLElement | null = null;

  get sheet(): EuiSheet<any> {
    return this.args.sheet;
  }

  get fields(): EuiSheetField[] {
    return this.sheet.allFields;
  }

  typeOf(field: EuiSheetField): EuiSheetFieldType {
    return this.sheet.typeOf(field);
  }

  canEdit(field: EuiSheetField): boolean {
    return !isReadOnly(this.sheet.context, field, this.args.record as never);
  }

  /** Mounts the field's editor (and so unmounts any other). */
  open = (field: EuiSheetField, initialKey: string | null): void => {
    if (!this.canEdit(field) || !this.typeOf(field).editor) return;
    if (this.editing) this.commit();
    const view = this.sheet.cellViewFor(this.args.record, field);
    this.editing = new FormEditing(
      this.args.record,
      field.id,
      initialKey,
      initialKey ?? view.text
    );
  };

  onDraftChange = (text: string): void => {
    const editing = this.editing;
    if (!editing) return;
    editing.latest = text;
    editing.kind = 'text';
    editing.dirty = true;
  };

  onDraftValue = (value: unknown): void => {
    const editing = this.editing;
    if (!editing) return;
    editing.latestValue = value;
    editing.kind = 'value';
    editing.dirty = true;
  };

  /** Closes the editor, saving its result or its reported draft. */
  commit = (
    result?: SheetEditorResult<unknown>,
    focus: 'next' | 'previous' | 'same' | 'none' = 'none'
  ): void => {
    const editing = this.editing;
    if (!editing) return;
    this.editing = null;
    const field = this.fields.find((f) => f.id === editing.fieldId);
    if (!field) return;
    // the record the editor was opened on (the sheet finds its current object)
    const record = editing.record;
    if (result && 'value' in result) {
      this.sheet.commitFormValue(record, field, result.value);
    } else if (result && 'text' in result) {
      this.sheet.commitFormText(record, field, result.text);
    } else if (editing.dirty && editing.kind === 'value') {
      this.sheet.commitFormValue(record, field, editing.latestValue);
    } else if (editing.dirty) {
      this.sheet.commitFormText(record, field, editing.latest);
    }
    if (focus !== 'none') {
      this.focusBox(
        field.id,
        focus === 'next' ? 1 : focus === 'previous' ? -1 : 0
      );
    }
  };

  cancel = (): void => {
    const editing = this.editing;
    if (!editing) return;
    this.editing = null;
    this.focusBox(editing.fieldId, 0);
  };

  onEditorCommit = (
    result?: SheetEditorResult<unknown>,
    options?: { move?: [number, number] }
  ): void => {
    // a move down or right (Tab) goes to the next field, left (Shift+Tab)
    // to the previous one; no move: focus goes back to the box
    const [rows, cols] = options?.move ?? [0, 0];
    this.commit(
      result,
      rows > 0 || cols > 0 ? 'next' : rows < 0 || cols < 0 ? 'previous' : 'same'
    );
  };

  onEditorFocusOut = (): void => {
    if (this.editing) this.commit();
  };

  /** Focuses the box of `fieldId`, or of the field `offset` after it, once rendered. */
  focusBox(fieldId: string, offset: number): void {
    const ids = this.fields.map((field) => field.id);
    const index = ids.indexOf(fieldId) + offset;
    const target = ids[Math.min(Math.max(index, 0), ids.length - 1)];
    if (target === undefined) return;
    this.sheet.afterFormRender(() => {
      const box = this.element?.querySelector<HTMLElement>(
        `[data-eui-sheet-record-box="${CSS.escape(target)}"]`
      );
      box?.focus();
    });
  }

  /** Keys of a box (nav mode). Escape is left to the shell, which closes. */
  onBoxKeyDown = (field: EuiSheetField, event: KeyboardEvent): void => {
    const sheet = this.sheet;
    const { key } = event;
    if ((event.ctrlKey || event.metaKey) && !event.altKey) {
      const letter = key.toLowerCase();
      if (letter === 'z') {
        stop(event);
        if (event.shiftKey) sheet.redo({ focus: false });
        else sheet.undo({ focus: false });
        return;
      }
      if (letter === 'y' && event.ctrlKey && !event.shiftKey) {
        stop(event);
        sheet.redo({ focus: false });
      }
      return;
    }
    const plain = !event.altKey;
    const record = this.args.record;
    const type = this.typeOf(field);
    const editable = this.canEdit(field);
    if (plain && editable && type.navKey) {
      const result = type.navKey(key, valueOf(record, field.id), field);
      if (result) {
        stop(event);
        sheet.commitFormValue(record, field, result.value);
        return;
      }
    }
    if (key === ' ') {
      // a role=button would click on Space
      stop(event);
      return;
    }
    if (key === 'Enter' || key === 'F2') {
      stop(event);
      this.open(field, null);
      return;
    }
    if (key.length === 1 && plain && !event.isComposing) {
      if (!editable || !type.editor) return;
      if (!(type.opensOnKey?.(key) ?? true)) return;
      stop(event);
      this.open(field, key);
      return;
    }
    if ((key === 'Delete' || key === 'Backspace') && editable) {
      stop(event);
      sheet.clearFormField(record, field);
    }
  };

  onBoxClick = (field: EuiSheetField): void => {
    const type = this.typeOf(field);
    if (!this.canEdit(field)) return;
    if (type.onCellClick) {
      const result = type.onCellClick(
        valueOf(this.args.record, field.id) as never,
        field,
        this.args.record
      );
      if (result)
        this.sheet.commitFormValue(this.args.record, field, result.value);
      return;
    }
    this.open(field, null);
  };

  /** Keys inside the open editor (capture, before the editor's own). */
  @action
  onKeyDown(event: KeyboardEvent): void {
    const editing = this.editing;
    if (!editing) return;
    const target = event.target;
    if (!(target instanceof Element) || !target.closest('.euiSheet__editor')) {
      return;
    }
    const field = this.fields.find((f) => f.id === editing.fieldId);
    if (!field) return;
    if (this.typeOf(field).handlesKey?.(event)) return;
    if (event.key === 'Enter') {
      stop(event);
      this.commit(undefined, 'next');
    } else if (event.key === 'Escape') {
      // stopPropagation: the flyout and the modal close on Escape
      stop(event);
      this.cancel();
    }
    // Tab: the browser moves focus on, and the focus-out commits
  }

  setup = modifier((element: HTMLElement) => {
    this.element = element;
    return () => {
      this.element = null;
    };
  });

  willDestroy(): void {
    super.willDestroy();
    // the shell closed with an editor open (programmatically: a click on
    // its close button commits on focus-out first): keep what was typed,
    // after the teardown
    const editing = this.editing;
    const field = editing && this.fields.find((f) => f.id === editing.fieldId);
    const sheet = this.sheet;
    if (!editing) return;
    next(() => {
      sheet.formEditorOpen = false;
      if (editing.dirty && field && editing.kind === 'value') {
        sheet.commitFormValue(editing.record, field, editing.latestValue);
      } else if (editing.dirty && field) {
        sheet.commitFormText(editing.record, field, editing.latest);
      }
    });
  }

  <template>
    <div
      class="euiSheetRecord__form"
      data-test-subj="euiSheetRecordForm"
      {{on "keydown" this.onKeyDown capture=true}}
      {{this.setup}}
    >
      {{#each this.fields key="id" as |field|}}
        <RecordFormField
          @sheet={{@sheet}}
          @record={{@record}}
          @field={{field}}
          @editing={{this.editing}}
          @onBoxKeyDown={{this.onBoxKeyDown}}
          @onBoxClick={{this.onBoxClick}}
          @onDraftChange={{this.onDraftChange}}
          @onDraftValue={{this.onDraftValue}}
          @onCommit={{this.onEditorCommit}}
          @onCancel={{this.cancel}}
          @onFocusOut={{this.onEditorFocusOut}}
        />
      {{/each}}
    </div>
  </template>
}

function stop(event: Event): void {
  event.preventDefault();
  event.stopPropagation();
}
