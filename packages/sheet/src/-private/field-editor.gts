/**
 * The field editor (V03 6.4): a panel under the header cell it belongs to
 * (the row menu's way), in the sheet's layer (portaled, `layer.gts`, so an
 * ancestor's `overflow: hidden` does not cut it off): above the header
 * when there is no room below in the viewport, clamped to the viewport,
 * then scrolling (at least 280 px tall); with a focus trap. Not inside the
 * header cell (P9). Escape and
 * Cancel close it and focus the header; a click outside or a grid scroll
 * cancels it. The frame is the sheet's (position, focus, saving state,
 * the delete confirmation); `@fieldEditor` replaces the content.
 */
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';

import EuiButton from '@ember-eui/core/components/eui-button';
import EuiButtonEmpty from '@ember-eui/core/components/eui-button-empty';
import EuiCallOut from '@ember-eui/core/components/eui-call-out';
import EuiFieldText from '@ember-eui/core/components/eui-field-text';
import EuiFocusTrap from '@ember-eui/core/components/eui-focus-trap';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import EuiPanel from '@ember-eui/core/components/eui-panel';
import EuiSelect from '@ember-eui/core/components/eui-select';
import EuiSwitch from '@ember-eui/core/components/eui-switch';
import EuiTextArea from '@ember-eui/core/components/eui-text-area';

import SheetLayer, { placeLayer } from './layer.gts';

import type EuiSheet from '../components/eui-sheet.gts';
import type { FieldEditorState } from './sheet/field-editor.ts';
import type { EuiSheetField, SheetFieldDraft } from '../core/index.ts';
import type { SheetFieldEditorSignature } from '../types.ts';
import type { LayerAnchor } from './layer.gts';

/** The panel's width (`styles.ts`); a narrower viewport gets its own width. */
export const FIELD_EDITOR_WIDTH = 320;

/** The least height of the clamped panel; it scrolls inside. */
const FIELD_EDITOR_MIN_HEIGHT = 280;

/** Marks the panel, so the sheet's key and scroll handlers leave it alone. */
export const FIELD_EDITOR_SELECTOR = '[data-eui-sheet-field-editor]';

/**
 * A field as a draft: its plain values, without `id` and without parts
 * that are functions (`options(record)`, `required(record)`, `validate`).
 * The owner merges it over the field, so those parts stay.
 */
export function draftOf(field: EuiSheetField): SheetFieldDraft {
  const draft: SheetFieldDraft = {
    label: field.label ?? field.id,
    type: field.type ?? 'text'
  };
  for (const [key, value] of Object.entries(field)) {
    if (key === 'id' || key === 'label' || key === 'type') continue;
    if (typeof value === 'function' || value === undefined) continue;
    draft[key] = value;
  }
  return draft;
}

/** Option defaults a type needs when the editor switches to it. */
function defaultsFor(
  type: string,
  draft: SheetFieldDraft
): Record<string, unknown> {
  if (
    (type === 'singleSelect' || type === 'multiSelect') &&
    !Array.isArray(draft['options'])
  ) {
    return { options: [] };
  }
  if (type === 'currency' && !draft['currency']) return { currency: 'USD' };
  return {};
}

/** A one-item list, to key the type's options form by the type. */
const array = (...items: unknown[]): unknown[] => items;

/** The built-in content: name, type, the type's options, description, required. */
export class FieldEditorForm extends Component<SheetFieldEditorSignature> {
  id = guidFor(this);
  @tracked draft: SheetFieldDraft = { ...this.args.draft };
  @tracked nameMissing = false;

  get messages() {
    return this.args.messages;
  }

  get title(): string {
    return this.args.mode === 'create'
      ? this.messages.addField()
      : this.messages.editField();
  }

  get typeOptions(): Array<{ value: string; text: string }> {
    return this.args.types.map((type) => ({
      value: type.name,
      text: type.label
    }));
  }

  get optionsForm() {
    return this.args.types.find((type) => type.name === this.draft.type)
      ?.fieldOptions;
  }

  get typeChanged(): boolean {
    return (
      this.args.mode === 'edit' &&
      (this.args.field?.type ?? 'text') !== this.draft.type
    );
  }

  get showRequired(): boolean {
    return typeof this.args.field?.required !== 'function';
  }

  get required(): boolean {
    return this.draft.required === true;
  }

  get nameError(): string | undefined {
    return this.nameMissing ? this.messages.fieldNameRequired() : undefined;
  }

  update = (patch: Record<string, unknown>): void => {
    this.draft = { ...this.draft, ...patch };
  };

  onName = (event: Event): void => {
    const label = (event.target as HTMLInputElement).value;
    this.update({ label });
    if (label.trim()) this.nameMissing = false;
  };

  onNameKeyDown = (event: KeyboardEvent): void => {
    if (event.key !== 'Enter' || event.isComposing) return;
    event.preventDefault();
    this.save();
  };

  onType = (event: Event): void => {
    const type = (event.target as HTMLSelectElement).value;
    this.update({ type, ...defaultsFor(type, this.draft) });
  };

  onDescription = (event: Event): void => {
    this.update({ description: (event.target as HTMLTextAreaElement).value });
  };

  onRequired = (): void => {
    this.update({ required: !this.required });
  };

  save = (): void => {
    if (this.args.isSaving) return;
    const label = this.draft.label.trim();
    if (!label) {
      this.nameMissing = true;
      document.getElementById(`${this.id}-name`)?.focus();
      return;
    }
    const draft: SheetFieldDraft = { ...this.draft, label };
    if (draft.description === '') {
      if (this.args.field?.description) draft.description = undefined;
      else delete draft.description;
    }
    this.args.onSave(draft);
  };

  <template>
    <div class="euiSheetFieldEditor__form" data-test-subj="euiSheetFieldForm">
      <h2 class="euiSheetFieldEditor__title">{{this.title}}</h2>
      <EuiFormRow
        @label={{(this.messages.fieldName)}}
        @id="{{this.id}}-name"
        @display="rowCompressed"
        @isInvalid={{this.nameMissing}}
        @error={{this.nameError}}
      >
        <EuiFieldText
          @compressed={{true}}
          @fullWidth={{true}}
          @value={{this.draft.label}}
          @isInvalid={{this.nameMissing}}
          id="{{this.id}}-name"
          data-autofocus
          data-eui-sheet-field-name
          data-test-subj="euiSheetFieldName"
          {{on "input" this.onName}}
          {{on "keydown" this.onNameKeyDown}}
        />
      </EuiFormRow>
      <EuiFormRow
        @label={{(this.messages.fieldType)}}
        @id="{{this.id}}-type"
        @display="rowCompressed"
      >
        <EuiSelect
          @compressed={{true}}
          @fullWidth={{true}}
          @options={{this.typeOptions}}
          @value={{this.draft.type}}
          id="{{this.id}}-type"
          data-test-subj="euiSheetFieldType"
          {{on "change" this.onType}}
        />
      </EuiFormRow>
      {{#if this.typeChanged}}
        <EuiCallOut
          @size="s"
          @color="warning"
          @iconType="warning"
          @title={{(this.messages.fieldTypeChangeWarning)}}
          class="euiSheetFieldEditor__warning"
          data-test-subj="euiSheetFieldTypeWarning"
        />
      {{/if}}
      {{#if this.optionsForm}}
        {{#let this.optionsForm as |Options|}}
          {{! keyed by the type, so a type change starts the form afresh }}
          {{#each (array this.draft.type) key="@identity"}}
            <Options
              @draft={{this.draft}}
              @field={{@field}}
              @onChange={{this.update}}
              @messages={{this.messages}}
            />
          {{/each}}
        {{/let}}
      {{/if}}
      <EuiFormRow
        @label={{(this.messages.fieldDescription)}}
        @id="{{this.id}}-description"
        @display="rowCompressed"
      >
        <EuiTextArea
          @compressed={{true}}
          @fullWidth={{true}}
          @rows={{2}}
          @resize="vertical"
          @value={{this.draft.description}}
          id="{{this.id}}-description"
          data-test-subj="euiSheetFieldDescriptionInput"
          {{on "input" this.onDescription}}
        />
      </EuiFormRow>
      {{#if this.showRequired}}
        <EuiSwitch
          @compressed={{true}}
          @label={{(this.messages.fieldRequired)}}
          @checked={{this.required}}
          @onChange={{this.onRequired}}
          class="euiSheetFieldEditor__required"
          data-test-subj="euiSheetFieldRequired"
        />
      {{/if}}
      {{#if @error}}
        <EuiCallOut
          @size="s"
          @color="danger"
          @iconType="error"
          @title={{@error}}
          class="euiSheetFieldEditor__error"
          data-test-subj="euiSheetFieldError"
        />
      {{/if}}
      <div class="euiSheetFieldEditor__actions">
        <EuiButtonEmpty
          @size="s"
          @type="button"
          data-test-subj="euiSheetFieldCancel"
          {{on "click" @onCancel}}
        >{{this.messages.cancel}}</EuiButtonEmpty>
        <EuiButton
          @size="s"
          @fill={{true}}
          @type="button"
          @isLoading={{@isSaving}}
          data-test-subj="euiSheetFieldSave"
          {{on "click" this.save}}
        >{{this.messages.save}}</EuiButton>
      </div>
    </div>
  </template>
}

interface FieldEditorSignature {
  Args: { sheet: EuiSheet<any>; state: FieldEditorState };
}

/** The frame: position, focus trap, the delete confirmation, the content. */
export default class FieldEditor extends Component<FieldEditorSignature> {
  get sheet(): EuiSheet<any> {
    return this.args.sheet;
  }

  get state(): FieldEditorState {
    return this.args.state;
  }

  get messages() {
    return this.sheet.messages;
  }

  /** The header's box in the viewport now (the layer reads it at every placement). */
  anchor = (): LayerAnchor | null =>
    this.sheet.dom.toViewport(this.state.anchor);

  minHeight = FIELD_EDITOR_MIN_HEIGHT;

  get isDelete(): boolean {
    return this.state.mode === 'delete';
  }

  get mode(): 'create' | 'edit' {
    return this.state.mode === 'create' ? 'create' : 'edit';
  }

  get field(): EuiSheetField | undefined {
    return this.sheet.fields.fieldById(this.state.fieldId);
  }

  get confirmText(): string {
    const field = this.field;
    return this.messages.deleteFieldConfirm(field?.label ?? field?.id ?? '');
  }

  get types() {
    return this.sheet.fieldEditor.fieldEditorTypes(this.field, this.state.mode);
  }

  get content() {
    return this.sheet.args.fieldEditor;
  }

  save = (draft: SheetFieldDraft): void =>
    this.sheet.fieldEditor.saveFieldEditor(draft);

  cancel = (): void => this.sheet.fieldEditor.closeFieldEditor(true);

  confirmDelete = (): void => this.sheet.fieldEditor.confirmDeleteField();

  onClickOutside = (): void => this.sheet.fieldEditor.closeFieldEditor(false);

  onEscape = (event: KeyboardEvent): void => {
    event.preventDefault();
    this.cancel();
  };

  <template>
    <SheetLayer @sheet={{this.sheet}}>
      <div
        class="euiSheet__fieldEditor"
        data-eui-sheet-field-editor
        data-test-subj="euiSheetFieldEditor"
        {{placeLayer
          anchor=this.anchor
          wrapper=this.sheet.wrapper
          gap=4
          scroller=".euiSheet__fieldEditorPanel"
          minHeight=this.minHeight
        }}
      >
        <EuiFocusTrap
          @returnFocus={{false}}
          @onClickOutside={{this.onClickOutside}}
          @onEscapeKey={{this.onEscape}}
        >
          <EuiPanel
            @paddingSize="m"
            @hasShadow={{true}}
            class="euiSheet__fieldEditorPanel"
          >
            {{#if this.isDelete}}
              <div
                class="euiSheetFieldEditor__form"
                data-test-subj="euiSheetFieldDelete"
              >
                <p class="euiSheetFieldEditor__confirm">{{this.confirmText}}</p>
                {{#if this.state.error}}
                  <EuiCallOut
                    @size="s"
                    @color="danger"
                    @iconType="error"
                    @title={{this.state.error}}
                    class="euiSheetFieldEditor__error"
                    data-test-subj="euiSheetFieldError"
                  />
                {{/if}}
                <div class="euiSheetFieldEditor__actions">
                  <EuiButtonEmpty
                    @size="s"
                    @type="button"
                    data-autofocus
                    data-test-subj="euiSheetFieldCancel"
                    {{on "click" this.cancel}}
                  >{{this.messages.cancel}}</EuiButtonEmpty>
                  <EuiButton
                    @size="s"
                    @fill={{true}}
                    @color="danger"
                    @type="button"
                    @isLoading={{this.state.isSaving}}
                    data-test-subj="euiSheetFieldDeleteConfirm"
                    {{on "click" this.confirmDelete}}
                  >{{this.messages.deleteField}}</EuiButton>
                </div>
              </div>
            {{else if this.content}}
              {{#let this.content as |Content|}}
                <Content
                  @mode={{this.mode}}
                  @field={{this.field}}
                  @draft={{this.state.draft}}
                  @types={{this.types}}
                  @isSaving={{this.state.isSaving}}
                  @error={{this.state.error}}
                  @onSave={{this.save}}
                  @onCancel={{this.cancel}}
                  @messages={{this.messages}}
                  @themeClass={{this.sheet.themeClass}}
                />
              {{/let}}
            {{else}}
              <FieldEditorForm
                @mode={{this.mode}}
                @field={{this.field}}
                @draft={{this.state.draft}}
                @types={{this.types}}
                @isSaving={{this.state.isSaving}}
                @error={{this.state.error}}
                @onSave={{this.save}}
                @onCancel={{this.cancel}}
                @messages={{this.messages}}
                @themeClass={{this.sheet.themeClass}}
              />
            {{/if}}
          </EuiPanel>
        </EuiFocusTrap>
      </div>
    </SheetLayer>
  </template>
}
