import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiFieldNumber from '@ember-eui/core/components/eui-field-number';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id.ts';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiFieldNumberSignature } from '@ember-eui/core/components/eui-field-number';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface FieldNumberSignature {
  Element: EuiFieldNumberSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiFieldNumberSignature['Args'] & {
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
    helpText: [...EuiFormRowSignature['Blocks']['helpText']];
    prepend: [...EuiFieldNumberSignature['Blocks']['prepend']];
    append: [...EuiFieldNumberSignature['Blocks']['append']];
  };
}

export default class ValidatedFormFieldNumber extends ValidatedFormFieldBase<FieldNumberSignature> {
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
          <EuiFieldNumber
            class={{@fieldClasses}}
            form={{@formId}}
            aria-label={{@ariaLabel}}
            @value={{@value}}
            @icon={{@icon}}
            @isInvalid={{this.isInvalidAndTouched}}
            @fullWidth={{@fullWidth}}
            @isLoading={{@isLoading}}
            @readOnly={{@readOnly}}
            @disabled={{@disabled}}
            @min={{@min}}
            @max={{@max}}
            @step={{@step}}
            @inputRef={{@inputRef}}
            @controlOnly={{@controlOnly}}
            @compressed={{@compressed}}
            @id={{theId}}
            @clear={{@clear}}
            @isPrependProvided={{has-block "prepend"}}
            @isAppendProvided={{has-block "append"}}
            autofocus={{@autofocus}}
            placeholder={{@placeholder}}
            ...attributes
            {{on "blur" (fn this.setIsTouched true)}}
            {{on "input" this.handleChange}}
          >
            <:prepend as |classes|>
              {{yield classes to="prepend"}}
            </:prepend>
            <:append as |classes|>
              {{yield classes to="append"}}
            </:append>
          </EuiFieldNumber>
        </:field>
        <:helpText as |helpText|>
          {{yield helpText to="helpText"}}
        </:helpText>
      </EuiFormRow>
    {{/let}}
  </template>
}
