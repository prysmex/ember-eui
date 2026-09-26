import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { EuiCheckbox } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not, or } from 'ember-truth-helpers';

import randomId from '../../../-private/random-id.ts';
import Base from './base.gts';

import type { BaseSignature } from './base';
import type { EuiCheckboxSignature } from '@ember-eui/core/components/eui-checkbox';

/**
 * A checkbox in an EuiFormRow bound to `@fieldName` of the form's changeset.
 * Takes EuiFormRow's and the control's args.
 */
export interface EuiChangesetFormFieldCheckboxSignature {
  Element: EuiCheckboxSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiCheckboxSignature['Args'] & {
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
    label?: EuiCheckboxSignature['Blocks']['label'];
  };
}

export default class EuiChangesetFormFieldCheckbox extends Base<EuiChangesetFormFieldCheckboxSignature> {
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
      <EuiCheckbox
        form={{@formId}}
        class={{@fieldClasses}}
        aria-label={{@ariaLabel}}
        @id={{theId}}
        @checked={{or this.value false}}
        @label={{@label}}
        @isFakeLabelBlock={{not (has-block "label")}}
        @disabled={{@disabled}}
        @compressed={{@compressed}}
        @indeterminate={{@indeterminate}}
        @inputRef={{@inputRef}}
        {{on "change" this.handleChange}}
        ...attributes
      >
        <:label>
          {{yield to="label"}}
        </:label>
      </EuiCheckbox>
    {{/let}}
  </template>
}
