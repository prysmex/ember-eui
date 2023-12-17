import { action } from '@ember/object';
import { EuiDualRange,EuiFormRow } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

import Base from './base';

import type { BaseSignature } from './base';
import type {
  EuiDualRangeSignature,
  ValueMember
} from '@ember-eui/core/components/eui-dual-range';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface EuiChangesetFormFieldDualRangeSliderSignature {
  Element: EuiDualRangeSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiDualRangeSignature['Args'] & {
      onInput?: (value: [ValueMember, ValueMember]) => void;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      placeholder?: string;
      radioLabel?: string;
    };

  Blocks: {
    prepend: EuiDualRangeSignature['Blocks']['prepend'];
    append: EuiDualRangeSignature['Blocks']['append'];
    min: EuiDualRangeSignature['Blocks']['min'];
    max: EuiDualRangeSignature['Blocks']['max'];
  };
}

export default class EuiChangesetFormFieldDualRangeSlider extends Base<EuiChangesetFormFieldDualRangeSliderSignature> {
  @action
  handleInput(e: [ValueMember, ValueMember]) {
    this.args.changeset.set(this.args.fieldName, e);

    this.args.onInput?.(e);
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
        <EuiDualRange
          class={{@fieldClasses}}
          form={{@formId}}
          @value={{this.value}}
          @fullWidth={{@fullWidth}}
          @isInvalid={{this.isInvalid}}
          @levels={{@levels}}
          @showLabels={{@showLabels}}
          @showInput={{@showInput}}
          @tickInterval={{@tickInterval}}
          @ticks={{@ticks}}
          aria-label={{@ariaLabel}}
          @compressed={{@compressed}}
          @showRange={{@showRange}}
          @showTicks={{@showTicks}}
          @readOnly={{@readOnly}}
          {{!template-lint-disable}}
          @id={{theId}}
          @step={{@step}}
          @onChange={{this.handleInput}}
          @max={{@max}}
          @min={{@min}}
          @isPrependProvided={{has-block "prepend"}}
          @isAppendProvided={{has-block "append"}}
          @isFakeMinBlock={{not (has-block "min")}}
          @isFakeMaxBlock={{not (has-block "max")}}
          disabled={{@disabled}}
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
      </EuiFormRow>
    {{/let}}
  </template>
}
