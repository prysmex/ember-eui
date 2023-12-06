import { action } from '@ember/object';
import { maybeUnwrapProxy } from '@ember-eui/core/utils/maybe-unwrap-proxy';
import ValidatedFormFieldBase from './field-base';
import type { FieldBaseSignature } from './field-base';
import { argOrDefault } from '@ember-eui/core/helpers';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { EuiFormRow, EuiCheckboxGroup } from '@ember-eui/core/components';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiCheckboxGroupSignature } from '@ember-eui/core/components/eui-checkbox-group';
import { not } from 'ember-truth-helpers';

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
    {{#let (argOrDefault @id (uniqueId)) as |theId|}}
      <EuiFormRow
        class={{@rowClasses}}
        @extra={{this.rowExtra}}
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
