import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { EuiCheckbox } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not, or } from 'ember-truth-helpers';

import randomId from '../../../-private/random-id.ts';
import Base from './base.gts';

import type { BaseSignature } from './base';
import type { EuiCheckboxSignature } from '@ember-eui/core/components/eui-checkbox';

export interface EuiChangesetFormFieldCheckboxSignature {
  Element: EuiCheckboxSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiCheckboxSignature['Args'] & {
      onChange?: (value: boolean, event: Event) => void;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      placeholder?: string;
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
