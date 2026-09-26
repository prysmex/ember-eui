import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import EuiRadioGroup from '@ember-eui/core/components/eui-radio-group';
import { argOrDefault } from '@ember-eui/core/helpers';
import { maybeUnwrapProxy } from '@ember-eui/core/utils/maybe-unwrap-proxy';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id.ts';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiRadioGroupSignature } from '@ember-eui/core/components/eui-radio-group';

export interface FieldRadioGroupSignature {
  Element: EuiRadioGroupSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiRadioGroupSignature['Args'] & {
      rowClasses?: string;
      fieldClasses?: string;
      formId?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      onChange?: (optionId: string) => void;
    };
  Blocks: {
    label: [...EuiFormRowSignature['Blocks']['label']];
    helpText: [...EuiFormRowSignature['Blocks']['helpText']];
  };
}

export default class ValidatedFormFieldRadioGroup extends ValidatedFormFieldBase<FieldRadioGroupSignature> {
  get value() {
    return maybeUnwrapProxy(this.args.value);
  }

  @action
  //@ts-expect-error
  handleChange(optionId: string) {
    this.args.onChange?.(optionId);
    this.isTouched = true;
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
        @isFakeHelpTextBlock={{not (has-block "helpText")}}
        {{didInsert this.setValidationMessages}}
        {{didUpdate this.didUpdateValue @validations}}
        {{didUpdate this.didUpdateValue @value}}
      >
        <:label as |label|>
          {{yield label to="label"}}
        </:label>
        <:field>
          <EuiRadioGroup
            class={{@fieldClasses}}
            @formId={{@formId}}
            aria-label={{@ariaLabel}}
            @disabled={{@disabled}}
            @valueKey={{@valueKey}}
            @labelKey={{@labelKey}}
            @compressed={{@compressed}}
            @name={{@name}}
            @options={{this.options}}
            @idSelected={{this.value}}
            @legend={{@legend}}
            @onChange={{this.handleChange}}
            autofocus={{@autofocus}}
            ...attributes
          />
        </:field>
        <:helpText as |helpText|>
          {{yield helpText to="helpText"}}
        </:helpText>
      </EuiFormRow>
    {{/let}}
  </template>
}
