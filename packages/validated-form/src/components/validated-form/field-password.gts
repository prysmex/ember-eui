import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { EuiFieldPassword,EuiFormRow } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id.ts';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiFieldPasswordSignature } from '@ember-eui/core/components/eui-field-password';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface FieldPasswordSignature {
  Element: EuiFieldPasswordSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiFieldPasswordSignature['Args'] & {
      rowClasses?: string;
      fieldClasses?: string;
      formId?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      onChange?: (state: boolean, e: MouseEvent) => void;
      placeholder?: string;
    };
  Blocks: {
    label: [...EuiFormRowSignature['Blocks']['label']];
    prepend: [...EuiFieldPasswordSignature['Blocks']['prepend']];
    append: [...EuiFieldPasswordSignature['Blocks']['append']];
  };
}

export default class ValidatedFormFieldPassword extends ValidatedFormFieldBase<FieldPasswordSignature> {
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
        <:label>
          {{yield to="label"}}
        </:label>
        <:field>
          <EuiFieldPassword
            class={{@fieldClasses}}
            form={{@formId}}
            aria-label={{@ariaLabel}}
            @isInvalid={{this.isInvalidAndTouched}}
            @fullWidth={{@fullWidth}}
            @isLoading={{@isLoading}}
            @compressed={{@compressed}}
            @inputRef={{@inputRef}}
            @value={{@value}}
            @type={{@type}}
            @id={{theId}}
            @disabled={{@disabled}}
            @isFakePrependBlock={{not (has-block "prepend")}}
            @isFakeAppendBlock={{not (has-block "append")}}
            autofocus={{@autofocus}}
            placeholder={{@placeholder}}
            ...attributes
            {{on "blur" (fn this.setIsTouched true)}}
            {{on "input" this.handleChange}}
          >
            <:prepend as |classes inputId|>
              {{yield classes inputId to="prepend"}}
            </:prepend>
            <:append as |classes inputId|>
              {{yield classes inputId to="append"}}
            </:append>
          </EuiFieldPassword>
        </:field>
      </EuiFormRow>
    {{/let}}
  </template>
}
