import { fn } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiComboBox from '@ember-eui/core/components/eui-combo-box';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import { argOrDefault } from '@ember-eui/core/helpers';

import optional from 'ember-composable-helpers/helpers/optional';
import queue from 'ember-composable-helpers/helpers/queue';
import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiComboBoxSignature } from '@ember-eui/core/components/eui-combo-box';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface FieldComboBoxSignature {
  Element: EuiComboBoxSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiComboBoxSignature['Args'] & {
      rowClasses?: string;
      fieldClasses?: string;
      formId?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      onChange?: (state: boolean, e: MouseEvent) => void;
      placeholder?: string;
      options?: EuiComboBoxSignature['Args']['options'];
      selectedOptions?: EuiComboBoxSignature['Args']['selectedOptions'];
    };
  Blocks: {
    label: EuiFormRowSignature['Blocks']['label'];
    default: EuiComboBoxSignature['Blocks']['default'];
  };
}

export default class ValidatedFormFieldComboBox extends ValidatedFormFieldBase<FieldComboBoxSignature> {
  validationProperty = 'args.selectedOptions';

  @action
  //@ts-expect-error
  handleChange(options: any[]) {
    this.args.onChange(options);
    this.notifyValidityChange();
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
        {{didUpdate this.didUpdateValue @selectedOptions}}
      >
        <:label>
          {{yield to="label"}}
        </:label>
        <:field>
          <EuiComboBox
            class={{@fieldClasses}}
            @onChange={{this.handleChange}}
            @dropdownClass={{@dropdownClass}}
            @placeholder={{@placeholder}}
            @options={{this.options}}
            @singleSelection={{@singleSelection}}
            @selectedOptions={{@selectedOptions}}
            @searchEnabled={{argOrDefault @searchEnabled true}}
            @placeholderComponent={{@placeholderComponent}}
            @searchMessageComponent={{@searchMessageComponent}}
            @loadingMessage={{@loadingMessage}}
            @beforeOptionsComponent={{@beforeOptionsComponent}}
            @afterOptionsComponent={{@afterOptionsComponent}}
            @searchField={{@searchField}}
            @searchMessage={{@searchMessage}}
            @search={{@search}}
            aria-label={{@ariaLabel}}
            form={{@formId}}
            @isInvalid={{this.isInvalidAndTouched}}
            @isClearable={{@isClearable}}
            @fullWidth={{@fullWidth}}
            @isLoading={{@isLoading}}
            @readOnly={{@readOnly}}
            @compressed={{@compressed}}
            @onCreateOption={{@onCreateOption}}
            @customOptionText={{@customOptionText}}
            @onBlur={{queue (fn this.setIsTouched true) (optional @onBlur)}}
            @onFocus={{@onFocus}}
            @onClose={{@onClose}}
            @onOpen={{@onOpen}}
            @isDisabled={{@isDisabled}}
            @renderInPlace={{@renderInPlace}}
            @extra={{@extra}}
            ...attributes
            as |opt index select|
          >
            {{yield opt index select}}
          </EuiComboBox>
        </:field>
      </EuiFormRow>
    {{/let}}
  </template>
}
