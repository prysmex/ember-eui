import Base from './base';
import type { BaseSignature } from './base';
import { EuiFormRow, EuiSelect } from '@ember-eui/core/components';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type { EuiSelectSignature } from '@ember-eui/core/components/eui-select';
import { argOrDefault } from '@ember-eui/core/helpers';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';
import { action } from '@ember/object';
import { not } from 'ember-truth-helpers';
import { on } from '@ember/modifier';

export interface EuiChangesetFormFieldSelectSignature {
  Element: EuiSelectSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiSelectSignature['Args'] & {
      onChange?: (value: string, event: Event) => void;
      fieldClasses?: string;
      ariaLabel?: string;
      autofocus?: boolean;
      placeholder?: string;
    };

  Blocks: {
    prepend?: EuiSelectSignature['Blocks']['prepend'];
    append?: EuiSelectSignature['Blocks']['append'];
  };
}

export default class EuiChangesetFormFieldSelect extends Base<EuiChangesetFormFieldSelectSignature> {
  form: HTMLFormElement | null = null;

  @action
  handleInput(e: Event) {
    const value = (e.target as HTMLInputElement).value;
    this.args.changeset.set(this.args.fieldName, value);

    this.args.onChange?.(value, e);
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
        <EuiSelect
          aria-label={{@ariaLabel}}
          class={{@fieldClasses}}
          form={{@formId}}
          @options={{@options}}
          @isInvalid={{this.isInvalid}}
          @fullWidth={{@fullWidth}}
          @isLoading={{@isLoading}}
          @hasNoInitialSelection={{@hasNoInitialSelection}}
          @inputRef={{@inputRef}}
          @value={{this.value}}
          @compressed={{@compressed}}
          @isFakePrependBlock={{not (has-block "prepend")}}
          @isFakeAppendBlock={{not (has-block "append")}}
          {{!template-lint-disable}}
          @id={{theId}}
          @disabled={{@disabled}}
          autofocus={{@autofocus}}
          {{on "blur" this.validate}}
          {{on "change" this.handleInput}}
          ...attributes
        >
          <:prepend as |classes inputId|>
            {{yield classes inputId to="prepend"}}
          </:prepend>
          <:append as |classes inputId|>
            {{yield classes inputId to="append"}}
          </:append>
        </EuiSelect>
      </EuiFormRow>
    {{/let}}
  </template>
}
