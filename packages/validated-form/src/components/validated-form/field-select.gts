import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { EuiFormRow, EuiSelect } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiSelectSignature } from '@ember-eui/core/components/eui-select';

export interface FieldSelectSignature {
  Element: EuiSelectSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiSelectSignature['Args'] & {
      rowClasses?: string;
      fieldClasses?: string;
      formId?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      onChange?: (state: boolean, e: MouseEvent) => void;
    };
  Blocks: {
    label: [];
    prepend: [...EuiSelectSignature['Blocks']['prepend']];
    append: [...EuiSelectSignature['Blocks']['append']];
  };
}

export default class ValidatedFormFieldSelect extends ValidatedFormFieldBase<FieldSelectSignature> {
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
          <EuiSelect
            aria-label={{@ariaLabel}}
            class={{@fieldClasses}}
            form={{@formId}}
            @options={{this.options}}
            @isInvalid={{this.isInvalidAndTouched}}
            @fullWidth={{@fullWidth}}
            @isLoading={{@isLoading}}
            @hasNoInitialSelection={{@hasNoInitialSelection}}
            @inputRef={{@inputRef}}
            @disabled={{@disabled}}
            @value={{@value}}
            @compressed={{@compressed}}
            @isFakePrependBlock={{not (has-block "prepend")}}
            @isFakeAppendBlock={{not (has-block "append")}}
            @id={{theId}}
            autofocus={{@autofocus}}
            ...attributes
            {{on "blur" (fn this.setIsTouched true)}}
            {{on "change" this.handleChange}}
          >
            <:prepend as |classes inputId|>
              {{yield classes inputId to="prepend"}}
            </:prepend>
            <:append as |classes inputId|>
              {{yield classes inputId to="append"}}
            </:append>
          </EuiSelect>
        </:field>
      </EuiFormRow>
    {{/let}}
  </template>
}
