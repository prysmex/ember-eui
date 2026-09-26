import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { EuiFieldText,EuiFormRow } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import randomId from '../../../-private/random-id.ts';
import Base from './base.gts';

import type { BaseSignature } from './base';
import type { EuiFieldTextSignature } from '@ember-eui/core/components/eui-field-text';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

/**
 * A text input in an EuiFormRow bound to `@fieldName` of the form's changeset.
 * Takes EuiFormRow's and the control's args.
 */
export interface EuiChangesetFormFieldTextSignature {
  Element: EuiFieldTextSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiFieldTextSignature['Args'] & {
      /** Called with the input's value and the event, after setting it on the changeset. */
      onInput?: (value: string, event: Event) => void;
      /** Classes for the control. */
      fieldClasses?: string;
      /** Accessible label of the control. */
      ariaLabel?: string;
      /** Focuses the control on render. */
      autofocus?: boolean;
    };
  Blocks: {
    prepend: EuiFieldTextSignature['Blocks']['prepend'];
    append: EuiFieldTextSignature['Blocks']['append'];
  };
}

export default class EuiChangesetFormFieldText extends Base<EuiChangesetFormFieldTextSignature> {
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
