import Base from './base';
import type { BaseSignature } from './base';
import { EuiFormRow, EuiFieldText } from '@ember-eui/core/components';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiFieldTextSignature } from '@ember-eui/core/components/eui-field-text';
import { argOrDefault } from '@ember-eui/core/helpers';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';
import { action } from '@ember/object';
import { not } from 'ember-truth-helpers';
import { on } from '@ember/modifier';

export interface EuiChangesetFormFieldTextSignature {
  Element: EuiFieldTextSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiFieldTextSignature['Args'] & {
      onInput?: (value: string, event: Event) => void;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
    };
  Blocks: {
    prepend: EuiFieldTextSignature['Blocks']['prepend'];
    append: EuiFieldTextSignature['Blocks']['append'];
  };
}

export default class EuiChangesetFormFieldText extends Base<EuiChangesetFormFieldTextSignature> {
  form: HTMLFormElement | null = null;

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
        {{!template-lint-disable}}
        <EuiFieldText
          class={{@fieldClasses}}
          aria-label={{@ariaLabel}}
          form={{@formId}}
          @value={{this.value}}
          @icon={{@icon}}
          @isInvalid={{this.isInvalid}}
          @fullWidth={{@fullWidth}}
          @isLoading={{@isLoading}}
          @readOnly={{@readOnly}}
          @inputRef={{@inputRef}}
          @controlOnly={{@controlOnly}}
          @compressed={{@compressed}}
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
        </EuiFieldText>
      </EuiFormRow>
    {{/let}}
  </template>
}
