import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, eq, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import EuiFormControlLayout from '../components/eui-form-control-layout.gts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import validatableControl from '../modifiers/validatable-control.ts';

import type { EuiFormControlLayoutSignature } from '../components/eui-form-control-layout';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A native `<select>` styled like EUI's inputs. For search or multiple values use EuiComboBox. */
export interface EuiSelectSignature {
  Element: HTMLSelectElement;
  Args: {
    /** Id of the select. Defaults to a random id. */
    id?: string;
    /** The options: `[{ value: 'a', text: 'Option A', disabled? }]`. */
    options: {
      value: string | number;
      text: string | number;
      disabled?: boolean;
    }[];
    /** The selected option's `value`. Update it from `{{on "change" …}}`. */
    value?: string | number;
    /** Stretches the select to its container's width. */
    fullWidth?: boolean;
    /** Shorter select, for dense forms. */
    compressed?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
    /** Disables the select. */
    disabled?: boolean;
    /**
     * Adds an empty first option, selected while `@value` is empty, so no
     * option is preselected. Defaults to `false`.
     */
    hasNoInitialSelection?: boolean;
    /** Shows the invalid state and marks it invalid for native form validation. */
    isInvalid?: boolean;
    /** Shows a clear ("x") button calling this function. */
    clear?: (v: any) => void;
    /** Called with the `<select>` element once rendered. */
    inputRef?: (element: HTMLSelectElement) => void;
    /** @private Ignore the `<:prepend>` block. */
    isFakePrependBlock?: boolean;
    /** @private Ignore the `<:append>` block. */
    isFakeAppendBlock?: boolean;
  };
  Blocks: {
    /** Content before the select; yields the class to put on it and the id. */
    prepend: [...EuiFormControlLayoutSignature['Blocks']['prepend'], string];
    /** Content after the select; yields the class to put on it and the id. */
    append: [...EuiFormControlLayoutSignature['Blocks']['append'], string];
  };
}

const EuiSelect: TemplateOnlyComponent<EuiSelectSignature> = <template>
  {{#let
    (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
    (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
    (argOrDefault @id (randomId))
    as |hasPrepend hasAppend inputId|
  }}
    {{#let
      (classNames
        (if @fullWidth "euiSelect--fullWidth")
        (if @compressed "euiSelect--compressed")
        (if (or hasPrepend hasAppend) "euiSelect--inGroup")
        (if @isLoading "euiSelect--isLoading")
        "euiSelect"
      )
      (argOrDefault @hasNoInitialSelection false)
      as |classes hasNoInitialSelection|
    }}

      <EuiFormControlLayout
        @clear={{@clear}}
        @icon="arrowDown"
        @iconSide="right"
        @fullWidth={{@fullWidth}}
        @isLoading={{@isLoading}}
        @compressed={{@compressed}}
        @disabled={{@disabled}}
        @useGroup={{or hasPrepend hasAppend}}
      >
        <:prepend as |prependClasses|>
          {{yield prependClasses inputId to="prepend"}}
        </:prepend>
        <:field>
          <select
            id={{inputId}}
            class={{classes}}
            disabled={{@disabled}}
            {{validatableControl @isInvalid}}
            {{didInsert (optional @inputRef)}}
            ...attributes
          >
            {{#if hasNoInitialSelection}}
              {{! template-lint-disable}}
              <option
                value=""
                disabled
                hidden
                style="display: none"
                selected={{not @value}}
              ></option>
              {{! template-lint-enable}}
            {{/if}}
            {{#each @options as |opt|}}
              <option
                value={{opt.value}}
                selected={{eq @value opt.value}}
                disabled={{eq opt.disabled true}}
              >
                {{opt.text}}
              </option>
            {{/each}}
          </select>
        </:field>
        <:append as |appendClasses|>
          {{yield appendClasses inputId to="append"}}
        </:append>
      </EuiFormControlLayout>
    {{/let}}
  {{/let}}
</template>;

export default EuiSelect;
