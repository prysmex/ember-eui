import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiFieldText from '@ember-eui/core/components/eui-field-text';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiFieldTextSignature } from '@ember-eui/core/components/eui-field-text';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface FieldTextSignature {
  Element: EuiFieldTextSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiFieldTextSignature['Args'] & {
      rowClasses?: string;
      fieldClasses?: string;
      formId?: string;
      ariaLabel?: string;
      autofocus?: boolean;
    };
  Blocks: {
    label: [];
    helpText: [...EuiFormRowSignature['Blocks']['helpText']];
    prepend: [...EuiFieldTextSignature['Blocks']['prepend']];
    append: [...EuiFieldTextSignature['Blocks']['append']];
  };
}

export default class ValidatedFormFieldText extends ValidatedFormFieldBase<FieldTextSignature> {
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
          <EuiFieldText
            class={{@fieldClasses}}
            aria-label={{@ariaLabel}}
            form={{@formId}}
            @value={{@value}}
            @icon={{@icon}}
            @isInvalid={{this.isInvalidAndTouched}}
            @fullWidth={{@fullWidth}}
            @isLoading={{@isLoading}}
            @disabled={{@disabled}}
            @readOnly={{@readOnly}}
            @inputRef={{@inputRef}}
            @controlOnly={{@controlOnly}}
            @compressed={{@compressed}}
            @clear={{@clear}}
            @id={{theId}}
            @isFakePrependBlock={{not (has-block "prepend")}}
            @isFakeAppendBlock={{not (has-block "append")}}
            autofocus={{@autofocus}}
            placeholder={{@placeholder}}
            {{on "input" this.handleChange}}
            ...attributes
          >
            <:prepend as |classes inputId|>
              {{yield classes inputId to="prepend"}}
            </:prepend>
            <:append as |classes inputId|>
              {{yield classes inputId to="append"}}
            </:append>
          </EuiFieldText>
        </:field>
        <:helpText as |helpText|>
          {{yield helpText to="helpText"}}
        </:helpText>
      </EuiFormRow>
    {{/let}}
  </template>
}
