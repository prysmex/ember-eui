import { action } from '@ember/object';
import { EuiCheckboxGroup,EuiFormRow } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import randomId from '../../../-private/random-id';
import Base from './base';

import type { BaseSignature } from './base';
import type { EuiCheckboxGroupSignature } from '@ember-eui/core/components/eui-checkbox-group';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface EuiChangesetFormFieldCheckboxGroupSignature {
  Element: EuiCheckboxGroupSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiCheckboxGroupSignature['Args'] & {
      onChange?: (value: string[]) => void;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      placeholder?: string;
      radioLabel?: string;
    };

  Blocks: {};
}

export default class EuiChangesetFormFieldCheckboxGroup extends Base<EuiChangesetFormFieldCheckboxGroupSignature> {
  get value(): string[] {
    return (
      this.args.changeset.get(this.args.fieldName)?.toArray() ||
      this.args.changeset.get(this.args.fieldName)
    );
  }

  get arrayToMap() {
    const currArr = this.value || [];

    return this.transformToMap(currArr);
  }

  transformToMap(value: string[] = []) {
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
  handleChange(optionId: string) {
    let value: string[] = this.value || [];

    const found = value.find((v) => v === optionId);
    let newArr = [];

    if (found) {
      newArr = value.filter((v) => v !== optionId);
    } else {
      newArr = [...value, optionId];
    }

    this.args.changeset.set(this.args.fieldName, newArr);
    this.validate();
    this.args.onChange?.(newArr);
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
        @label={{@label}}
        @labelAppend={{@labelAppend}}
        @id={{theId}}
        @isInvalid={{this.isInvalid}}
        @error={{this.errors}}
        @helpText={{@helpText}}
        @errorClasses={{@errorClasses}}
      >
        <EuiCheckboxGroup
          class={{@fieldClasses}}
          @formId={{@formId}}
          @valueKey={{@valueKey}}
          @labelKey={{@labelKey}}
          aria-label={{@ariaLabel}}
          @disabled={{@disabled}}
          @compressed={{@compressed}}
          @options={{@options}}
          @idToSelectedMap={{this.arrayToMap}}
          @legend={{@legend}}
          @onChange={{this.handleChange}}
          autofocus={{@autofocus}}
          ...attributes
        />
      </EuiFormRow>
    {{/let}}
  </template>
}
