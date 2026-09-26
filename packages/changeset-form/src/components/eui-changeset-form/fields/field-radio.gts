import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { EuiFormRow, EuiRadio } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not, or } from 'ember-truth-helpers';

import randomId from '../../../-private/random-id.ts';
import Base from './base.gts';

import type { BaseSignature } from './base';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiRadioSignature } from '@ember-eui/core/components/eui-radio';

/**
 * A radio in an EuiFormRow bound to `@fieldName` of the form's changeset.
 * Takes EuiFormRow's and the control's args.
 */
export interface EuiChangesetFormFieldRadioSignature {
  Element: EuiRadioSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiRadioSignature['Args'] & {
      /** Called with the new checked state and the event, after setting it on the changeset. */
      onChange?: (value: boolean, event: Event) => void;
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

  Blocks: {
    label?: EuiRadioSignature['Blocks']['label'];
  };
}

export default class EuiChangesetFormFieldRadio extends Base<EuiChangesetFormFieldRadioSignature> {
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
        <EuiRadio
          class={{@fieldClasses}}
          form={{@formId}}
          aria-label={{@ariaLabel}}
          @label={{@radioLabel}}
          @isFakeLabelBlock={{not (has-block "label")}}
          @id={{theId}}
          @checked={{or this.value false}}
          @compressed={{@compressed}}
          @name={{@name}}
          @disabled={{@disabled}}
          @inputRef={{@inputRef}}
          ...attributes
          {{on "change" this.handleChange}}
        >
          <:label>
            {{yield to="label"}}
          </:label>
        </EuiRadio>
      </EuiFormRow>
    {{/let}}
  </template>
}
