import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { EuiFormRow, EuiTextArea } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

import Base from './base';

import type { BaseSignature } from './base';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiTextAreaSignature } from '@ember-eui/core/components/eui-text-area';

export interface EuiChangesetFormFieldTextAreaSignature {
  Element: EuiTextAreaSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiTextAreaSignature['Args'] & {
      onInput?: (value: string, event: Event) => void;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      placeholder?: string;
    };
}

export default class EuiChangesetFormFieldTextArea extends Base<EuiChangesetFormFieldTextAreaSignature> {
  @action
  handleInput(e: Event) {
    const value = (e.target as HTMLInputElement).value;

    this.args.changeset.set(this.args.fieldName, value);

    this.args.onInput?.(value, e);
  }

  <template>
    {{#let (argOrDefault @id (uniqueId)) as |theId|}}
      <EuiFormRow
        class={{@rowClasses}}
        @extra={{this.rowExtra}}
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
        <EuiTextArea
          class={{@fieldClasses}}
          form={{@formId}}
          aria-label={{@ariaLabel}}
          @value={{this.value}}
          @isInvalid={{this.isInvalid}}
          @fullWidth={{@fullWidth}}
          @compressed={{@compressed}}
          @resize={{@resize}}
          @inputRef={{@inputRef}}
          @id={{theId}}
          @rows={{@rows}}
          @disabled={{@disabled}}
          autofocus={{@autofocus}}
          placeholder={{@placeholder}}
          ...attributes
          {{on "blur" this.validate}}
          {{on "input" this.handleInput}}
        />
      </EuiFormRow>
    {{/let}}
  </template>
}
