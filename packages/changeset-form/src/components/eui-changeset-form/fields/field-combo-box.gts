import { assert } from '@ember/debug';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { EuiComboBox,EuiFormRow } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import optional from 'ember-composable-helpers/helpers/optional';
import queue from 'ember-composable-helpers/helpers/queue';

import randomId from '../../../-private/random-id';
import Base from './base';

import type { BaseSignature } from './base';
import type { EuiComboBoxSignature } from '@ember-eui/core/components/eui-combo-box';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface EuiChangesetFormFieldComboBoxSignature {
  Element: EuiComboBoxSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiComboBoxSignature['Args'] & {
      onChange: (options: any[] | string) => void;
      singleSelection?: { isPlainText: boolean } | boolean;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      placeholder?: string;
      radioLabel?: string;
    };

  Blocks: {
    default: EuiComboBoxSignature['Blocks']['default'];
  };
}

/**
 * In order to provide full flexibility, this component doesn't handle the setting
 * or hardcodes the selected
 */
export default class EuiChangesetFormFieldComboBox extends Base<EuiChangesetFormFieldComboBoxSignature> {
  constructor(
    owner: unknown,
    args: EuiChangesetFormFieldComboBoxSignature['Args']
  ) {
    super(owner, args);

    assert(
      `Must provide @onChange to FieldComboBox for ${this.args.fieldName}`,
      this.args.onChange
    );
  }

  @action
  handleChange(options: any[]) {
    this.args.onChange(options);
    this.validate();
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
        <EuiComboBox
          class={{@fieldClasses}}
          @onChange={{this.handleChange}}
          @dropdownClass={{@dropdownClass}}
          @placeholder={{@placeholder}}
          @options={{@options}}
          @singleSelection={{@singleSelection}}
          @selectedOptions={{@selectedOptions}}
          @searchEnabled={{argOrDefault @searchEnabled true}}
          @searchField={{@searchField}}
          aria-label={{@ariaLabel}}
          form={{@formId}}
          @isInvalid={{this.isInvalid}}
          @isDisabled={{@isDisabled}}
          @fullWidth={{@fullWidth}}
          @isClearable={{@isClearable}}
          @isLoading={{@isLoading}}
          @readOnly={{@readOnly}}
          @compressed={{@compressed}}
          @onCreateOption={{@onCreateOption}}
          @customOptionText={{@customOptionText}}
          @onBlur={{queue this.validate (optional @onBlur)}}
          @onFocus={{@onFocus}}
          @onClose={{@onClose}}
          @onOpen={{@onOpen}}
          @extra={{@extra}}
          ...attributes
          as |opt index select|
        >
          {{yield opt index select}}
        </EuiComboBox>
      </EuiFormRow>
    {{/let}}
  </template>
}
