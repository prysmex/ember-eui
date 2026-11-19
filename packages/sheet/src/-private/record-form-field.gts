/**
 * One field of the expanded record: its label, then a box with the type's
 * cell (or the text), focusable with `role="button"` when the field can be
 * edited (it is not in the grid, so tabbable is fine), and the field's
 * errors under it. While edited, the type's editor is mounted inline: in
 * place of the box ('cell' editors), or under it ('panel' editors).
 */
import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';

import EditorFrame from './editor-frame.gts';

import type EuiSheet from '../components/eui-sheet.gts';
import type { CellView } from '../components/eui-sheet.gts';
import type { EuiSheetField } from '../core/index.ts';
import type { SheetEditorResult } from '../types.ts';
import type { FormEditing } from './record-form.gts';

interface RecordFormFieldSignature {
  Args: {
    sheet: EuiSheet<any>;
    record: unknown;
    field: EuiSheetField;
    editing: FormEditing | null;
    onBoxKeyDown: (field: EuiSheetField, event: KeyboardEvent) => void;
    onBoxClick: (field: EuiSheetField) => void;
    onDraftChange: (text: string) => void;
    onCommit: (
      result?: SheetEditorResult<unknown>,
      options?: { move?: [number, number] }
    ) => void;
    onCancel: () => void;
    onFocusOut: () => void;
  };
}

export default class RecordFormField extends Component<RecordFormFieldSignature> {
  labelId = `${guidFor(this)}-label`;

  get view(): CellView {
    return this.args.sheet.cellViewFor(this.args.record, this.args.field);
  }

  get label(): string {
    return this.args.field.label ?? this.args.field.id;
  }

  /** This field's editor, when it is the one open. */
  get editing(): FormEditing | null {
    const editing = this.args.editing;
    return editing && editing.fieldId === this.args.field.id ? editing : null;
  }

  get isPanel(): boolean {
    return this.view.type.editorLayout === 'panel';
  }

  /** A 'cell' editor takes the box's place. */
  get showBox(): boolean {
    return !this.editing || this.isPanel;
  }

  get editable(): boolean {
    return !this.view.readOnly;
  }

  get cellComponent() {
    const view = this.view;
    return view.rejected ? undefined : view.type.cell;
  }

  onCellCommit = (value: unknown): void => {
    this.args.sheet.commitFormValue(this.args.record, this.args.field, value);
  };

  <template>
    <div
      class="euiSheetRecord__field"
      data-test-subj="euiSheetRecordField-{{@field.id}}"
    >
      <div
        class="euiSheetRecord__label"
        id={{this.labelId}}
      >{{this.label}}</div>
      {{#if this.showBox}}
        {{#if this.editable}}
          <div
            class="euiSheetRecord__box
              {{if this.view.errors.length 'euiSheetRecord__box--invalid'}}"
            role="button"
            tabindex="0"
            aria-labelledby={{this.labelId}}
            aria-invalid={{if this.view.errors.length "true"}}
            data-eui-sheet-record-box={{@field.id}}
            data-test-subj="euiSheetRecordBox"
            {{on "keydown" (fn @onBoxKeyDown @field)}}
            {{on "click" (fn @onBoxClick @field)}}
          >
            {{#if this.cellComponent}}
              <this.cellComponent
                @value={{this.view.value}}
                @text={{this.view.text}}
                @field={{this.view.field}}
                @record={{this.view.record}}
                @errors={{this.view.errors}}
                @readOnly={{this.view.readOnly}}
                @onCommit={{this.onCellCommit}}
              />
            {{else}}
              {{this.view.text}}
            {{/if}}
          </div>
        {{else}}
          <div
            class="euiSheetRecord__box euiSheetRecord__box--readOnly
              {{if this.view.errors.length 'euiSheetRecord__box--invalid'}}"
            aria-labelledby={{this.labelId}}
            data-eui-sheet-record-box={{@field.id}}
            data-test-subj="euiSheetRecordBox"
          >
            {{#if this.cellComponent}}
              <this.cellComponent
                @value={{this.view.value}}
                @text={{this.view.text}}
                @field={{this.view.field}}
                @record={{this.view.record}}
                @errors={{this.view.errors}}
                @readOnly={{true}}
                @onCommit={{this.onCellCommit}}
              />
            {{else}}
              {{this.view.text}}
            {{/if}}
          </div>
        {{/if}}
      {{/if}}
      {{#if this.editing}}
        <EditorFrame @layout="inline" @onFocusOut={{@onFocusOut}}>
          {{#if this.view.type.editor}}
            <this.view.type.editor
              @value={{this.view.value}}
              @field={{@field}}
              @record={{@record}}
              @draft={{this.editing.draft}}
              @initialKey={{this.editing.initialKey}}
              @onDraftChange={{@onDraftChange}}
              @onCommit={{@onCommit}}
              @onCancel={{@onCancel}}
              @messages={{@sheet.messages}}
              @themeClass={{@sheet.themeClass}}
            />
          {{/if}}
        </EditorFrame>
      {{/if}}
      {{#if this.view.errors.length}}
        <div
          class="euiSheetRecord__errors"
          data-test-subj="euiSheetRecordErrors"
        >
          {{#each this.view.errors as |message|}}
            <div>{{message}}</div>
          {{/each}}
        </div>
      {{/if}}
    </div>
  </template>
}
