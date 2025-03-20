import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { EuiFieldPassword, EuiFormRow } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../../-private/random-id';
import Base from './base';

import type { BaseSignature } from './base';
import type { EuiFieldPasswordSignature } from '@ember-eui/core/components/eui-field-password';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface EuiChangesetFormFieldPasswordSignature {
  Element: EuiFieldPasswordSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiFieldPasswordSignature['Args'] & {
      onInput?: (value: string, event: Event) => void;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      placeholder?: string;
      radioLabel?: string;
    };

  Blocks: {
    prepend: EuiFieldPasswordSignature['Blocks']['prepend'];
    append: EuiFieldPasswordSignature['Blocks']['append'];
  };
}

export default class EuiChangesetFormFieldPassword extends Base<EuiChangesetFormFieldPasswordSignature> {
  @action
  handleInput(e: Event) {
    const value = (e.target as HTMLInputElement).value;

    this.args.changeset.set(this.args.fieldName, value);

    this.args.onInput?.(value, e);
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
        <EuiFieldPassword
          class={{@fieldClasses}}
          form={{@formId}}
          aria-label={{@ariaLabel}}
          @isInvalid={{this.isInvalid}}
          @fullWidth={{@fullWidth}}
          @isLoading={{@isLoading}}
          @compressed={{@compressed}}
          @inputRef={{@inputRef}}
          @value={{this.value}}
          @type={{@type}}
          {{!template-lint-disable}}
          @id={{theId}}
          @isFakePrependBlock={{not (has-block "prepend")}}
          @isFakeAppendBlock={{not (has-block "append")}}
          @disabled={{@disabled}}
          autofocus={{@autofocus}}
          placeholder={{@placeholder}}
          {{on "blur" this.validate}}
          {{on "input" this.handleInput}}
          ...attributes
        >
          <:prepend as |classes inputId|>
            {{yield classes inputId to="prepend"}}
          </:prepend>
          <:append as |classes inputId|>
            {{yield classes inputId to="append"}}
          </:append>
        </EuiFieldPassword>
      </EuiFormRow>
    {{/let}}
  </template>
}
