import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from 'ember-composable-helpers/helpers/optional';
import { and, eq, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id';
import EuiFormControlLayout from '../components/eui-form-control-layout.gts';
import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import validatableControl from '../modifiers/validatable-control';

import type { EuiFormControlLayoutSignature } from '../components/eui-form-control-layout';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiSelectSignature {
  Element: HTMLSelectElement;
  Args: {
    id?: string;
    options: {
      value: string | number;
      text: string | number;
      disabled?: boolean;
    }[];
    value?: string | number;
    fullWidth?: boolean;
    compressed?: boolean;
    isLoading?: boolean;
    disabled?: boolean;
    hasNoInitialSelection?: boolean;
    isInvalid?: boolean;
    clear?: (v: any) => void;
    inputRef?: (element: HTMLSelectElement) => void;
    isFakePrependBlock?: boolean;
    isFakeAppendBlock?: boolean;
  };
  Blocks: {
    prepend: [...EuiFormControlLayoutSignature['Blocks']['prepend'], string];
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
