import { action } from '@ember/object';
import { EuiFormRow, EuiRange } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

import Base from './base';

import type { BaseSignature } from './base';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiRangeSignature } from '@ember-eui/core/components/eui-range';

export interface EuiChangesetFormFieldRangeSliderSignature {
  Element: EuiRangeSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiRangeSignature['Args'] & {
      onChange?: (value: string, event: Event) => void;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      placeholder?: string;
      radioLabel?: string;
    };

  Blocks: {
    prepend: EuiRangeSignature['Blocks']['prepend'];
    append: EuiRangeSignature['Blocks']['append'];
    min: EuiRangeSignature['Blocks']['min'];
    valuePrepend: EuiRangeSignature['Blocks']['valuePrepend'];
    value: EuiRangeSignature['Blocks']['value'];
    valueAppend: EuiRangeSignature['Blocks']['valueAppend'];
    max: EuiRangeSignature['Blocks']['max'];
  };
}

export default class EuiChangesetFormFieldRangeSlider extends Base<EuiChangesetFormFieldRangeSliderSignature> {
  form: HTMLFormElement | null = null;

  @action
  handleInput(e: Event) {
    const value = (e.target as HTMLInputElement).value;

    this.args.changeset.set(this.args.fieldName, value);

    this.args.onChange?.(value, e);
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
        <EuiRange
          class={{@fieldClasses}}
          form={{@formId}}
          @compressed={{@compressed}}
          @readOnly={{@readOnly}}
          @fullWidth={{@fullWidth}}
          {{!template-lint-disable}}
          @id={{theId}}
          @levels={{@levels}}
          @step={{@step}}
          @showInput={{@showInput}}
          @showLabels={{@showLabels}}
          @showRange={{@showRange}}
          @showTicks={{@showTicks}}
          @showValue={{@showValue}}
          @ticks={{@ticks}}
          @tickInterval={{@tickInterval}}
          @valuePrepend={{@valuePrepend}}
          @valueAppend={{@valueAppend}}
          @onChange={{this.handleInput}}
          @value={{this.value}}
          @max={{@max}}
          @isLoading={{@isLoading}}
          @min={{@min}}
          @isInvalid={{this.isInvalid}}
          @isPrependProvided={{has-block "prepend"}}
          @isAppendProvided={{has-block "append"}}
          @isFakeMinBlock={{not (has-block "min")}}
          @isFakeMaxBlock={{not (has-block "max")}}
          @isFakeValueBlock={{not (has-block "value")}}
          @isFakeValuePrependBlock={{not (has-block "valuePrepend")}}
          @isFakeValueAppendBlock={{not (has-block "valueAppend")}}
          disabled={{@disabled}}
          aria-label={{@ariaLabel}}
          autofocus={{@autofocus}}
          ...attributes
        >
          <:prepend as |classes|>
            {{yield classes to="prepend"}}
          </:prepend>
          <:min as |min|>
            {{yield min to="min"}}
          </:min>
          <:valuePrepend>
            {{yield to="valuePrepend"}}
          </:valuePrepend>
          <:value>
            {{yield to="value"}}
          </:value>
          <:valueAppend>
            {{yield to="valueAppend"}}
          </:valueAppend>
          <:max as |max|>
            {{yield max to="max"}}
          </:max>
          <:append as |classes|>
            {{yield classes to="append"}}
          </:append>
        </EuiRange>
      </EuiFormRow>
    {{/let}}
  </template>
}
