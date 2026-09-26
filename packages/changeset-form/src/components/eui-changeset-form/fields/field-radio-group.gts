import { action } from '@ember/object';
import { EuiFormRow, EuiRadioGroup } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import randomId from '../../../-private/random-id.ts';
import Base from './base.gts';

import type { BaseSignature } from './base';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiRadioGroupSignature } from '@ember-eui/core/components/eui-radio-group';

/**
 * A radio group in an EuiFormRow bound to `@fieldName` of the form's changeset.
 * Takes EuiFormRow's and the control's args.
 */
export interface EuiChangesetFormFieldRadioGroupSignature {
  Element: EuiRadioGroupSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiRadioGroupSignature['Args'] & {
      /** Called with the chosen option's id, after setting it on the changeset. */
      onChange?: (value: string) => void;
      /** Classes for the control. */
      fieldClasses?: string;
      /** Accessible label of the control. */
      ariaLabel?: string;
      /** Focuses the control on render. */
      autofocus?: boolean;
      /** Placeholder text. */
      placeholder?: string;
      /** The radio's own label (next to it); `@label` is the row's label. */
      radioLabel?: string;
    };

  Blocks: {};
}

export default class EuiChangesetFormFieldRadioGroup extends Base<EuiChangesetFormFieldRadioGroupSignature> {
  @action
  handleChange(idSelected: string) {
    this.args.changeset.set(this.args.fieldName, idSelected);
    this.validate();
    this.args.onChange?.(idSelected);
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
        <EuiRadioGroup
          class={{@fieldClasses}}
          @formId={{@formId}}
          aria-label={{@ariaLabel}}
          @disabled={{@disabled}}
          @valueKey={{@valueKey}}
          @labelKey={{@labelKey}}
          @compressed={{@compressed}}
          @name={{@name}}
          @options={{@options}}
          @idSelected={{this.value}}
          @legend={{@legend}}
          {{!template-lint-disable}}
          @onChange={{this.handleChange}}
          autofocus={{@autofocus}}
          ...attributes
        />
      </EuiFormRow>
    {{/let}}
  </template>
}
