import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { EuiFormRow, EuiRadioGroup } from '@ember-eui/core/components';
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
      onChange?: (state: boolean, e: MouseEvent) => void;
    };
  Blocks: {
    label: [...EuiFormRowSignature['Blocks']['label']];
  };
}

export default class ValidatedFormFieldRadioGroup extends ValidatedFormFieldBase<FieldRadioGroupSignature> {
  get value() {
    let value = maybeUnwrapProxy(this.args.value);

    return value?.toArray?.() || value;
  }

  get arrayToMap() {
    const currArr = this.args.value || [];

    return this.transformToMap(currArr);
  }

  transformToMap(value = []) {
    let valuesMap = value.reduce(
      (acc, val: string) => {
        acc[val] = true;

        return acc;
      },
      {} as { [key: string]: boolean }
    );

    return valuesMap;
  }

  @action
  //@ts-expect-error
  handleChange(optionId: string) {
    let value = this.value || [];

    const found = value.find((v: string) => v === optionId);
    let newArr = [];

    if (found) {
      newArr = value.filter((v: string) => v !== optionId);
    } else {
      newArr = [...value, optionId];
    }

    this.args.onChange?.(newArr);
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
      </EuiFormRow>
    {{/let}}
  </template>
}
