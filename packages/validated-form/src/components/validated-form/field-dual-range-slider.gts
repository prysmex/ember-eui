import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiDualRange from '@ember-eui/core/components/eui-dual-range';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id.ts';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type {
  EuiDualRangeSignature,
  ValueMember
} from '@ember-eui/core/components/eui-dual-range';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

/**
 * A validated dual range slider in an EuiFormRow. Takes FieldBase's, EuiFormRow's and
 * the control's args.
 */
export interface FieldDualRangeSliderSignature {
  Element: EuiDualRangeSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiDualRangeSignature['Args'] & {
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
      /** Disables the control. */
      disabled?: boolean;
      /** Compressed control. */
      compressed?: boolean;
      /** @deprecated Has no effect. */
      hasFocus?: boolean;
      /** Shows a spinner. */
      isLoading?: boolean;
      /** Read-only control. */
      readOnly?: boolean;
      /** Icon of the control. */
      icon?: string;

      /** Called with `[lower, upper]`. */
      onChange?: (value: [ValueMember, ValueMember]) => void;
    };
  Blocks: {
    label: [];
    helpText: [...EuiFormRowSignature['Blocks']['helpText']];
    prepend: [...EuiDualRangeSignature['Blocks']['prepend']];
    min: [...EuiDualRangeSignature['Blocks']['min']];
    append: [...EuiDualRangeSignature['Blocks']['append']];
    max: [...EuiDualRangeSignature['Blocks']['max']];
  };
}

export default class ValidatedFormFieldRangeSlider extends ValidatedFormFieldBase<FieldDualRangeSliderSignature> {
  @action
  //@ts-expect-error
  handleChange(
    e: [ValueMember, ValueMember],
    _isValid: boolean,
    _event: Event
  ) {
    // The received event for the dual range is an array with [min, max] as strings
    const value = [Number(e[0]), Number(e[1])];

    this.args.onChange(value);
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
        {{didUpdate this.didUpdateValue @value}}
      >
        <:label>
          {{yield to="label"}}
        </:label>

        <:field>
          <EuiDualRange
            class={{@fieldClasses}}
            form={{@formId}}
            @value={{@value}}
            @fullWidth={{@fullWidth}}
            @isInvalid={{this.isInvalidAndTouched}}
            @levels={{@levels}}
            @showLabels={{@showLabels}}
            @showInput={{@showInput}}
            @tickInterval={{@tickInterval}}
            @ticks={{@ticks}}
            aria-label={{@ariaLabel}}
            @disabled={{@disabled}}
            @compressed={{@compressed}}
            @showRange={{@showRange}}
            @showTicks={{@showTicks}}
            @readOnly={{@readOnly}}
            @id={{theId}}
            @step={{@step}}
            @onChange={{this.handleChange}}
            @max={{@max}}
            @min={{@min}}
            @isPrependProvided={{has-block "prepend"}}
            @isAppendProvided={{has-block "append"}}
            @isFakeMinBlock={{not (has-block "min")}}
            @isFakeMaxBlock={{not (has-block "max")}}
            autofocus={{@autofocus}}
            ...attributes
          >
            <:prepend as |classes|>
              {{yield classes to="prepend"}}
            </:prepend>
            <:min>
              {{yield to="min"}}
            </:min>
            <:max>
              {{yield to="max"}}
            </:max>
            <:append as |classes|>
              {{yield classes to="append"}}
            </:append>
          </EuiDualRange>
        </:field>

        <:helpText as |helpText|>
          {{yield helpText to="helpText"}}
        </:helpText>
      </EuiFormRow>
    {{/let}}
  </template>
}
