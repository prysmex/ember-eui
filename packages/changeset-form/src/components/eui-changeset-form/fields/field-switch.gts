import { action } from '@ember/object';
import { EuiFormRow, EuiSwitch } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../../-private/random-id.ts';
import Base from './base.gts';

import type { BaseSignature } from './base';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiSwitchSignature } from '@ember-eui/core/components/eui-switch';

/**
 * A switch in an EuiFormRow bound to `@fieldName` of the form's changeset.
 * Takes EuiFormRow's and the control's args.
 */
export interface EuiChangesetFormFieldSwitchSignature {
  Element: EuiSwitchSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiSwitchSignature['Args'] & {
      /** Called with the new checked state and the event, after setting it on the changeset. */
      onChange?: (value: boolean, event: Event) => void;
      /** Classes for the control. */
      fieldClasses?: string;
      /** Accessible label of the control. */
      ariaLabel?: string;
      /** Focuses the control on render. */
      autofocus?: boolean;
      /** The switch's own label (next to it); `@label` is the row's label. */
      switchLabel?: string;
      /** Placeholder text. */
      placeholder?: string;
    };

  Blocks: {
    label?: EuiSwitchSignature['Blocks']['label'];
  };
}

export default class EuiChangesetFormFieldSwitch extends Base<EuiChangesetFormFieldSwitchSignature> {
  @action
  handleChange(e: Event) {
    e.preventDefault();

    const checked = (e.target as HTMLInputElement).checked;

    this.args.changeset.set(this.args.fieldName, checked);
    this.validate();
    this.args.onChange?.(checked, e);
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
        <EuiSwitch
          class={{@fieldClasses}}
          form={{@formId}}
          aria-label={{@ariaLabel}}
          @id={{theId}}
          @showLabel={{@showLabel}}
          @label={{@switchLabel}}
          @checked={{this.value}}
          @onChange={{this.handleChange}}
          @isFakeLabelBlock={{not (has-block "label")}}
          @disabled={{@disabled}}
          @compressed={{@compressed}}
          @type={{@type}}
          ...attributes
        >
          <:label>
            {{yield to="label"}}
          </:label>
        </EuiSwitch>
      </EuiFormRow>
    {{/let}}
  </template>
}
