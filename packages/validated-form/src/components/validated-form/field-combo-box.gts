import ValidatedFormFieldBase from './field-base';
import type { FieldBaseSignature } from './field-base';
import { argOrDefault } from '@ember-eui/core/helpers';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { EuiFormRow, EuiComboBox } from '@ember-eui/core/components';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiComboBoxSignature } from '@ember-eui/core/components/eui-combo-box';
import { fn } from '@ember/helper';
import { not } from 'ember-truth-helpers';
import { action } from '@ember/object';
import queue from 'ember-composable-helpers/helpers/queue';
import optional from 'ember-composable-helpers/helpers/optional';

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
