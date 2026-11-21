/**
 * The import screen's "New field..." form (v0.4 10, "Creating fields"): the
 * sheet's field editor content (`FieldEditorForm`: name, type, the type's
 * `fieldOptions`, description, required), which needs no sheet. Shown
 * inline under the column's row; its name gets focus, Escape cancels.
 * Saving only changes the draft: nothing is created before Import.
 */
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import { FieldEditorForm } from '../field-editor.gts';

import type { SheetFieldDraft, SheetMessages } from '../../core/index.ts';
import type { SheetFieldEditorType } from '../../types.ts';

interface ImportNewFieldFormSignature {
  Args: {
    draft: SheetFieldDraft;
    types: SheetFieldEditorType[];
    messages: SheetMessages;
    themeClass?: string;
    onSave: (draft: SheetFieldDraft) => void;
    onCancel: () => void;
  };
}

/** Focuses the form's `[data-autofocus]` control when it appears. */
const focusFirst = modifier((element: HTMLElement) => {
  element.querySelector<HTMLElement>('[data-autofocus]')?.focus();
});

export default class ImportNewFieldForm extends Component<ImportNewFieldFormSignature> {
  onKeyDown = (event: KeyboardEvent): void => {
    if (event.key !== 'Escape' || event.isComposing) return;
    event.preventDefault();
    event.stopPropagation();
    this.args.onCancel();
  };

  <template>
    <div
      class="euiSheetImport__form"
      data-test-subj="euiSheetImportNewFieldForm"
      {{focusFirst}}
      {{on "keydown" this.onKeyDown}}
    >
      <FieldEditorForm
        @mode="create"
        @draft={{@draft}}
        @types={{@types}}
        @isSaving={{false}}
        @onSave={{@onSave}}
        @onCancel={{@onCancel}}
        @messages={{@messages}}
        @themeClass={{@themeClass}}
      />
    </div>
  </template>
}
