import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, eq, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import useState from '../helpers/use-state.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiFormControlLayout from './eui-form-control-layout.gts';

import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFieldPasswordSignature {
  Element: HTMLInputElement;
  Args: {
    /** The value. Update it from `{{on "input" …}}` on the component. */
    value?: string;
    /** Id of the input, e.g. to match an `EuiFormRow`'s label. Defaults to a random id. */
    id?: string;
    /**
     * `'password'` hides the text, `'text'` shows it, `'dual'` hides it with
     * a button to show it. Defaults to `'dual'`.
     */
    type?: 'dual' | 'text' | 'password';
    /** Stretches the input to its container's width. */
    fullWidth?: boolean;
    /** Shorter input, for dense forms. */
    compressed?: boolean;
    /** Shows a spinner in the input. */
    isLoading?: boolean;
    /** Makes the input read-only. */
    readOnly?: boolean;
    /** Disables the input. */
    disabled?: boolean;
    /** Shows the invalid state and marks the input invalid for native form validation. */
    isInvalid?: boolean;
    /** Shows a clear ("x") button calling this function; empty the value there. */
    clear?: EuiFormControlLayoutSignature['Args']['clear'];
    /** Called with the `<input>` element once rendered. */
    inputRef?: (element: HTMLInputElement) => void;
    /** @private Ignore the `<:prepend>` block. */
    isFakePrependBlock?: boolean;
    /** @private Ignore the `<:append>` block. */
    isFakeAppendBlock?: boolean;
    /** Placeholder text. */
    placeholder?: string;
  };
  Blocks: {
    /** Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. */
    prepend: [unknown, string];
    /** Content after the input; yields the class to put on it and the input id. */
    append: [unknown, string];
  };
}

const EuiFieldPassword: TemplateOnlyComponent<EuiFieldPasswordSignature> =
  <template>
    {{#let
      (argOrDefault @type "dual")
      (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
      (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
      (argOrDefault @id (randomId))
      as |type hasPrepend hasAppend inputId|
    }}
      {{#let
        (useState (if (eq type "dual") "password" type))
        as |inputTypeState|
      }}
        {{#let
          (classNames
            (if @fullWidth "euiFieldPassword--fullWidth")
            (if @compressed "euiFieldPassword--compressed")
            (if
              (or hasPrepend hasAppend (eq type "dual"))
              "euiFieldPassword--inGroup"
            )
            (if @isLoading "euiFieldPassword--isLoading")
            (if (eq type "dual") "euiFieldPassword--withToggle")
            "euiFieldPassword"
          )
          as |classes|
        }}
          {{#let (eq inputTypeState.value "text") as |isVisible|}}
            <EuiFormControlLayout
              @icon="lock"
              @clear={{@clear}}
              @fullWidth={{@fullWidth}}
              @isLoading={{@isLoading}}
              @compressed={{@compressed}}
              @readOnly={{@readOnly}}
              @disabled={{@disabled}}
              @useGroup={{or hasPrepend (or hasAppend (eq type "dual"))}}
            >
              <:prepend as |prependClasses|>
                {{yield prependClasses inputId to="prepend"}}
              </:prepend>
              <:field>
                <input
                  id={{inputId}}
                  class={{classes}}
                  type={{inputTypeState.value}}
                  value={{@value}}
                  disabled={{@disabled}}
                  placeholder={{@placeholder}}
                  {{validatableControl @isInvalid}}
                  {{didInsert (optional @inputRef)}}
                  ...attributes
                />
              </:field>
              <:append as |appendClasses|>
                {{yield appendClasses inputId to="append"}}
                {{#if (eq type "dual")}}
                  <EuiButtonIcon
                    tabindex="-1"
                    @iconType={{if isVisible "eyeClosed" "eye"}}
                    {{on
                      "click"
                      (fn
                        inputTypeState.setState (if isVisible "password" "text")
                      )
                    }}
                  />
                {{/if}}
              </:append>
            </EuiFormControlLayout>
          {{/let}}
        {{/let}}
      {{/let}}
    {{/let}}
  </template>;

export default EuiFieldPassword;
