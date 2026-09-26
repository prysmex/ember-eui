import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import EuiFormControlLayout from './eui-form-control-layout.gts';

import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFieldTextSignature {
  Element: HTMLInputElement;
  Args: {
    /** Id of the input, e.g. to match an `EuiFormRow`'s label. Defaults to a random id. */
    id?: string;
    /** The value. Update it from `{{on "input" …}}` on the component. */
    value?: string;
    /** Placeholder text. */
    placeholder?: string;
    /** Icon inside the input (left side), anything `EuiIcon`'s `@type` accepts. */
    icon?: EuiFormControlLayoutSignature['Args']['icon'];
    /** Stretches the input to its container's width. */
    fullWidth?: boolean;
    /** Shows a spinner in the input. */
    isLoading?: boolean;
    /** Shorter input, for dense forms. */
    compressed?: boolean;
    /** Makes the input read-only. */
    readOnly?: boolean;
    /** Disables the input. */
    disabled?: boolean;
    /** Shows a clear ("x") button calling this function; empty the value there. */
    clear?: () => void;
    /**
     * Renders just the `<input>`, without the layout (icon, clear button,
     * prepend/append). Best used inside EuiFormControlLayoutDelimited.
     */
    controlOnly?: boolean;
    /** Shows the invalid state and marks the input invalid for native form validation. */
    isInvalid?: boolean;
    /** Called with the `<input>` element once rendered (only with `@controlOnly`). */
    inputRef?: (element: HTMLInputElement | null) => void;
    /** @private Ignore the `<:prepend>` block. */
    isFakePrependBlock?: boolean;
    /** @private Ignore the `<:append>` block. */
    isFakeAppendBlock?: boolean;
  };
  Blocks: {
    /** Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. */
    prepend: [...EuiFormControlLayoutSignature['Blocks']['prepend'], string];
    /** Content after the input; yields the class to put on it and the input id. */
    append: [...EuiFormControlLayoutSignature['Blocks']['append'], string];
  };
}

const EuiFieldText: TemplateOnlyComponent<EuiFieldTextSignature> = <template>
  {{#let
    (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
    (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
    (argOrDefault @id (randomId))
    as |hasPrepend hasAppend inputId|
  }}
    {{#let
      (classNames
        (if @icon "euiFieldText--withIcon")
        (if @fullWidth "euiFieldText--fullWidth")
        (if @compressed "euiFieldText--compressed")
        (if (or hasPrepend hasAppend) "euiFieldText--inGroup")
        (if @isLoading "euiFieldText--isLoading")
        "euiFieldText"
      )
      as |classes|
    }}
      {{#if @controlOnly}}
        <input
          id={{inputId}}
          value={{@value}}
          class={{classes}}
          disabled={{@disabled}}
          type="text"
          placeholder={{@placeholder}}
          readonly={{@readOnly}}
          ...attributes
          {{validatableControl @isInvalid}}
          {{didInsert (optional @inputRef)}}
        />
      {{else}}
        <EuiFormControlLayout
          @icon={{@icon}}
          @clear={{@clear}}
          @fullWidth={{@fullWidth}}
          @isLoading={{@isLoading}}
          @compressed={{@compressed}}
          @readOnly={{@readOnly}}
          @disabled={{@disabled}}
          @useGroup={{or hasPrepend hasAppend}}
        >
          <:prepend as |prependClasses|>
            {{yield prependClasses inputId to="prepend"}}
          </:prepend>
          <:field>
            <input
              id={{inputId}}
              value={{@value}}
              class={{classes}}
              disabled={{@disabled}}
              type="text"
              placeholder={{@placeholder}}
              readonly={{@readOnly}}
              ...attributes
              {{validatableControl @isInvalid}}
            />
          </:field>
          <:append as |appendClasses|>
            {{yield appendClasses inputId to="append"}}
          </:append>
        </EuiFormControlLayout>
      {{/if}}
    {{/let}}
  {{/let}}
</template>;

export default EuiFieldText;
