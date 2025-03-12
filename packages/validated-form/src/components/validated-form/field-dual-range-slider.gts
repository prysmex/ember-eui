import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiDualRange from '@ember-eui/core/components/eui-dual-range';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type {
  EuiDualRangeSignature,
  ValueMember
} from '@ember-eui/core/components/eui-dual-range';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface FieldDualRangeSliderSignature {
  Element: EuiDualRangeSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiDualRangeSignature['Args'] & {
      rowClasses?: string;
      fieldClasses?: string;
      formId?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      disabled?: boolean;
      compressed?: boolean;
      hasFocus?: boolean;
      isLoading?: boolean;
      readOnly?: boolean;
      icon?: string;

      onChange?: (state: boolean, e: MouseEvent) => void;
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
