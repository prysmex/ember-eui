import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { EuiCheckboxGroup,EuiFormRow } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';
import { maybeUnwrapProxy } from '@ember-eui/core/utils/maybe-unwrap-proxy';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiCheckboxGroupSignature } from '@ember-eui/core/components/eui-checkbox-group';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface FieldCheckboxGroupSignature {
  Element: EuiCheckboxGroupSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiCheckboxGroupSignature['Args'] & {
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
  };
}

export default class ValidatedFormFieldCheckboxGroup extends ValidatedFormFieldBase<FieldCheckboxGroupSignature> {
  get value(): string[] {
    let value = maybeUnwrapProxy(this.args.value);

    return value?.toArray?.() || value;
  }

  get arrayToMap() {
    const currArr = this.value || [];

    return this.transformToMap(currArr);
  }

  transformToMap(value: string[] = []) {
    let valuesMap = value.reduce(
      (acc, val) => {
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
    const value = this.value || [];

    const found = value.find((v) => v === optionId);
    let newArr = [];

    if (found) {
      newArr = value.filter((v) => v !== optionId);
    } else {
      newArr = [...value, optionId];
    }

    this.args.onChange?.(newArr);

    this.notifyValidityChange();
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
        <:label>
          {{yield to="label"}}
        </:label>

        <:field>
          <EuiCheckboxGroup
            class={{@fieldClasses}}
            @formId={{@formId}}
            @valueKey={{@valueKey}}
            @labelKey={{@labelKey}}
            aria-label={{@ariaLabel}}
            @disabled={{@disabled}}
            @compressed={{@compressed}}
            @isInvalid={{this.isInvalidAndTouched}}
            @options={{this.options}}
            @idToSelectedMap={{this.arrayToMap}}
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
