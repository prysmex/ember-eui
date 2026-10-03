import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import EuiTextArea from '@ember-eui/core/components/eui-text-area';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id.ts';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiTextAreaSignature } from '@ember-eui/core/components/eui-text-area';
import type { ComponentLike } from '@glint/template';

/**
 * A validated textarea in an EuiFormRow. Takes FieldBase's, EuiFormRow's and the
 * control's args; `@onChange` receives the value.
 */
export interface FieldTextAreaSignature extends FieldBaseSignature {
  Element: EuiTextAreaSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiTextAreaSignature['Args'] & {
      /** @private Set by ValidatedForm. */
      formId?: string;
      /** Accessible label of the control. */
      ariaLabel?: string;
      /** Visible number of lines. */
      rows?: number;
      /** Which way it can be resized: `'vertical'`, `'horizontal'`, `'both'` or `'none'`. */
      resize?: 'vertical' | 'horizontal' | 'both' | 'none';
      /** Classes for the EuiFormRow. */
      rowClasses?: string;
      /** Classes for the control. */
      fieldClasses?: string;
      /** @deprecated Not rendered, see EuiFormRow. */
      labelAppend?: ComponentLike;
      /** @deprecated Has no effect. */
      prepend?: ComponentLike;
      /** @deprecated Has no effect. */
      append?: ComponentLike;
      /** Placeholder text. */
      placeholder?: string;
      /** Focuses the control on render. */
      autofocus?: boolean;
      /** Read-only control. */
      readOnly?: boolean;
      /** Called with the `<textarea>` element. */
      inputRef?: (element: HTMLTextAreaElement) => void;
    };
  Blocks: {
    label: [];
    helpText: [...EuiFormRowSignature['Blocks']['helpText']];
    default: [...EuiTextAreaSignature['Blocks']['default']];
  };
}

export default class ValidatedFormFieldTextArea extends ValidatedFormFieldBase<FieldTextAreaSignature> {
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
        @isFakeHelpTextBlock={{not (has-block "helpText")}}
        {{didInsert this.setValidationMessages}}
        {{didUpdate this.didUpdateValue @validations}}
        {{didUpdate this.didUpdateValue @value}}
      >
        <:label>
          {{yield to="label"}}
        </:label>
        <:field>
          <EuiTextArea
            class={{@fieldClasses}}
            form={{@formId}}
            aria-label={{@ariaLabel}}
            @value={{@value}}
            @isInvalid={{this.isInvalidAndTouched}}
            @fullWidth={{@fullWidth}}
            @compressed={{@compressed}}
            @resize={{@resize}}
            @disabled={{@disabled}}
            @inputRef={{@inputRef}}
            @id={{theId}}
            @rows={{@rows}}
            autofocus={{@autofocus}}
            placeholder={{@placeholder}}
            readonly={{@readOnly}}
            ...attributes
            {{on "input" this.handleChange}}
          >
            {{yield}}
          </EuiTextArea>
        </:field>
        <:helpText as |helpText|>
          {{yield helpText to="helpText"}}
        </:helpText>
      </EuiFormRow>
    {{/let}}
  </template>
}
