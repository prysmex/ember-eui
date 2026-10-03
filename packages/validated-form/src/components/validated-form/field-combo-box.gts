import { fn } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiComboBox from '@ember-eui/core/components/eui-combo-box';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import { argOrDefault } from '@ember-eui/core/helpers';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import queue from '@nullvoxpopuli/ember-composable-helpers/helpers/queue';
import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id.ts';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiComboBoxSignature } from '@ember-eui/core/components/eui-combo-box';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

/**
 * A validated combo box in an EuiFormRow. Takes FieldBase's, EuiFormRow's and
 * the control's args.
 */
export interface FieldComboBoxSignature {
  Element: EuiComboBoxSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiComboBoxSignature['Args'] & {
      /** Classes for the EuiFormRow. */
      rowClasses?: string;
      /** Classes for the control. */
      fieldClasses?: string;
      /** @private Set by ValidatedForm. */
      formId?: string;
      /** Accessible label of the control. */
      ariaLabel?: string;
      /** Focuses the control on render. */
      autofocus?: boolean;
      /** Called with the selected options. */
      onChange?: (options: any[]) => void;
      /** Placeholder text. */
      placeholder?: string;
      /** The options, see the control. */
      options?: EuiComboBoxSignature['Args']['options'];
      /** The selected options. */
      selectedOptions?: EuiComboBoxSignature['Args']['selectedOptions'];
    };
  Blocks: {
    label: EuiFormRowSignature['Blocks']['label'];
    helpText: EuiFormRowSignature['Blocks']['helpText'];
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
        @isFakeHelpTextBlock={{not (has-block "helpText")}}
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
            @isInvalid={{this.isInvalidAndTouched}}
            @isClearable={{@isClearable}}
            @fullWidth={{@fullWidth}}
            @isLoading={{@isLoading}}
            @readOnly={{@readOnly}}
            @compressed={{@compressed}}
            @onCreateOption={{@onCreateOption}}
            @matchTriggerWidth={{@matchTriggerWidth}}
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
        <:helpText as |helpText|>
          {{yield helpText to="helpText"}}
        </:helpText>
      </EuiFormRow>
    {{/let}}
  </template>
}
