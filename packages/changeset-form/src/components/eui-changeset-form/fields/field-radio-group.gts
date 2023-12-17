import { action } from '@ember/object';
import { EuiFormRow, EuiRadioGroup } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

import Base from './base';

import type { BaseSignature } from './base';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiRadioGroupSignature } from '@ember-eui/core/components/eui-radio-group';

export interface EuiChangesetFormFieldRadioGroupSignature {
  Element: EuiRadioGroupSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiRadioGroupSignature['Args'] & {
      onChange?: (value: string) => void;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      placeholder?: string;
      radioLabel?: string;
    };

  Blocks: {};
}

export default class EuiChangesetFormFieldRadioGroup extends Base<EuiChangesetFormFieldRadioGroupSignature> {
  form: HTMLFormElement | null = null;

  @action
  handleChange(idSelected: string) {
    this.args.changeset.set(this.args.fieldName, idSelected);
    this.validate();
    this.args.onChange?.(idSelected);
  }

  <template>
    {{#let (argOrDefault @id (uniqueId)) as |theId|}}
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
        <EuiRadioGroup
          class={{@fieldClasses}}
          @formId={{@formId}}
          aria-label={{@ariaLabel}}
          @disabled={{@disabled}}
          @valueKey={{@valueKey}}
          @labelKey={{@labelKey}}
          @compressed={{@compressed}}
          @name={{@name}}
          @options={{@options}}
          @idSelected={{this.value}}
          @legend={{@legend}}
          {{!template-lint-disable}}
          @onChange={{this.handleChange}}
          autofocus={{@autofocus}}
          ...attributes
        />
      </EuiFormRow>
    {{/let}}
  </template>
}
