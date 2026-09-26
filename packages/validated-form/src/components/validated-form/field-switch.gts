import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import EuiSwitch from '@ember-eui/core/components/eui-switch';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../-private/random-id.ts';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiSwitchSignature } from '@ember-eui/core/components/eui-switch';

/**
 * A validated switch in an EuiFormRow. Takes FieldBase's, EuiFormRow's and
 * the control's args.
 */
export interface FieldSwitchSignature {
  Element: EuiSwitchSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiSwitchSignature['Args'] & {
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
      /** The switch's own label (next to it); `@label` is the row's label. */
      switchLabel?: EuiSwitchSignature['Args']['label'];
      /** Called with the new checked state and the click event. */
      onChange?: (checked: boolean, e: MouseEvent) => void;
    };
  Blocks: {
    label: [];
    helpText: EuiFormRowSignature['Blocks']['helpText'];
    'switch-label': [];
  };
}

export default class ValidatedFormFieldSwitch extends ValidatedFormFieldBase<FieldSwitchSignature> {
  @action
  handleChange(e: MouseEvent) {
    e.preventDefault();

    const checked = (e.target as HTMLInputElement).checked;

    this.args.onChange?.(checked, e);
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
          <EuiSwitch
            class={{@fieldClasses}}
            form={{@formId}}
            aria-label={{@ariaLabel}}
            @id={{theId}}
            @showLabel={{@showLabel}}
            @label={{@switchLabel}}
            @checked={{@value}}
            @onChange={{this.handleChange}}
            @isFakeLabelBlock={{not (has-block "switch-label")}}
            @disabled={{@disabled}}
            @compressed={{@compressed}}
            @type={{@type}}
            ...attributes
          >
            <:label>
              {{yield to="switch-label"}}
            </:label>
          </EuiSwitch>
        </:field>
        <:helpText as |helpText|>
          {{yield helpText to="helpText"}}
        </:helpText>
      </EuiFormRow>
    {{/let}}
  </template>
}
