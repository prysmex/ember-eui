import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { EuiFormRow, EuiMarkdownEditor } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';
import { EnsureSafeComponentHelper } from '@embroider/util';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id.ts';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiMarkdownEditorSignature } from '@ember-eui/core/components/eui-markdown-editor';
import type { ComponentLike } from '@glint/template';

export interface FieldMarkdownEditorSignature {
  Element: EuiMarkdownEditorSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiMarkdownEditorSignature['Args'] & {
      rowClasses?: string;
      fieldClasses?: string;
      formId?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      onChange?: (state: boolean, e: MouseEvent) => void;
      placeholder?: string;
      editorComponent?: ComponentLike
    };
  Blocks: {
    label: [...EuiFormRowSignature['Blocks']['label']];
  };
}

export default class ValidatedFormFieldMarkdownEditor extends ValidatedFormFieldBase<FieldMarkdownEditorSignature> {
  @action
  //@ts-expect-error
  handleChange(str: string) {
    this.args.onChange(str);
    this.notifyValidityChange();
  }

  <template>
    {{#let (argOrDefault @id (randomId)) as |theId|}}
      <EuiFormRow
        class={{this.rowClasses}}
        @labelType={{@labelType}}
        @display={{@display}}
        @hasEmptyLabelSpace={{@hasEmptyLabelSpace}}
        @fullWidth={{@fullWidth}}
        @hasChildLabel={{@hasChildLabel}}
        @label={{this.label}}
        @labelAppend={{@labelAppend}}
        @id={{theId}}
        @isInvalid={{this.isInvalidAndTouched}}
        @error={{this.validationErrorMessages}}
        @helpText={{@helpText}}
        @errorClasses={{@errorClasses}}
        @isFakeLabelBlock={{not (has-block "label")}}
        {{didInsert this.setValidationMessages}}
        {{didUpdate this.didUpdateValue @validations}}
        {{didUpdate this.didUpdateValue @value}}
      >
        <:label as |label|>
          {{yield label to="label"}}
        </:label>
        <:field>
          {{#let
            (if
              @editorComponent
              (component (EnsureSafeComponentHelper @editorComponent))
              (component EuiMarkdownEditor)
            )
            as |MarkdownEditor|
          }}
            {{!@glint-expect-error}}
            <MarkdownEditor
              class={{@fieldClasses}}
              form={{@formId}}
              aria-label={{@ariaLabel}}
              @value={{@value}}
              @isInvalid={{this.isInvalidAndTouched}}
              @disabled={{@disabled}}
              @editorId={{theId}}
              @onChange={{this.handleChange}}
              @ariaDescribedBy={{@ariaDescribedBy}}
              @ariaLabel={{@ariaLabel}}
              @ariaLabelledBy={{@ariaLabelledBy}}
              autofocus={{@autofocus}}
              placeholder={{@placeholder}}
              @onParse={{@onParse}}
              @parsingPluginList={{@parsingPluginList}}
              @uiPlugins={{@uiPlugins}}
              @height={{@height}}
              @maxHeight={{@maxHeight}}
              @autoExpandPreview={{@autoExpandPreview}}
              @initialViewMode={{@initialViewMode}}
              ...attributes
              {{on "blur" (fn this.setIsTouched true)}}
            />
          {{/let}}
        </:field>
      </EuiFormRow>
    {{/let}}
  </template>
}
