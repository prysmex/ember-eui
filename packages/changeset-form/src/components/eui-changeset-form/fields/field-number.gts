import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { EuiFieldNumber,EuiFormRow } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import randomId from '../../../-private/random-id.ts';
import Base from './base.gts';

import type { BaseSignature } from './base';
import type { EuiFieldNumberSignature } from '@ember-eui/core/components/eui-field-number';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

export interface EuiChangesetFormFieldNumberSignature {
  Element: EuiFieldNumberSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiFieldNumberSignature['Args'] & {
      onInput?: (value: string, event: Event) => void;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      placeholder?: string;
      radioLabel?: string;
    };

  Blocks: {
    prepend: EuiFieldNumberSignature['Blocks']['prepend'];
    append: EuiFieldNumberSignature['Blocks']['append'];
  };
}

export default class EuiChangesetFormFieldNumber extends Base<EuiChangesetFormFieldNumberSignature> {
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
        <EuiFieldNumber
          class={{@fieldClasses}}
          form={{@formId}}
          aria-label={{@ariaLabel}}
          @value={{this.value}}
          @icon={{@icon}}
          @isInvalid={{this.isInvalid}}
          @fullWidth={{@fullWidth}}
          @isLoading={{@isLoading}}
          @readOnly={{@readOnly}}
          @min={{@min}}
          @max={{@max}}
          @step={{@step}}
          @inputRef={{@inputRef}}
          @controlOnly={{@controlOnly}}
          @compressed={{@compressed}}
          {{!template-lint-disable}}
          @id={{theId}}
          @disabled={{@disabled}}
          @isPrependProvided={{has-block "prepend"}}
          @isAppendProvided={{has-block "append"}}
          autofocus={{@autofocus}}
          placeholder={{@placeholder}}
          {{on "blur" this.validate}}
          {{on "input" this.handleInput}}
          ...attributes
        >
          <:prepend as |classes|>
            {{yield classes to="prepend"}}
          </:prepend>
          <:append as |classes|>
            {{yield classes to="append"}}
          </:append>
        </EuiFieldNumber>
      </EuiFormRow>
    {{/let}}
  </template>
}
