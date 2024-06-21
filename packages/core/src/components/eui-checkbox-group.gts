import { concat } from '@ember/helper';
import { get } from '@ember/helper';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import { or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import EuiCheckbox from './eui-checkbox.gts';
import EuiFormFieldset from './eui-form-fieldset.gts';

import type { EuiCheckboxSignature } from './eui-checkbox';
import type { EuiFormFieldsetSignature } from './eui-form-fieldset';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiCheckboxGroupSignature {
  Element: HTMLDivElement;
  Args: {
    valueKey?: string;
    labelKey?: string;
    isInvalid?: boolean;
    legend?: EuiFormFieldsetSignature['Args']['legend'];
    compressed?: EuiFormFieldsetSignature['Args']['compressed'];
    options: {
      value: string;
      label: string;
      disabled?: boolean;
      className?: string;
    }[];
    formId?: string;
    label?: EuiCheckboxSignature['Args']['label'];
    disabled?: EuiCheckboxSignature['Args']['disabled'];
    onChange: (value: any) => void;
    idToSelectedMap: Record<string, boolean>;
  };
}

const EuiCheckboxGroup: TemplateOnlyComponent<EuiCheckboxGroupSignature> =
  <template>
    {{#let
      (argOrDefault @valueKey "id") (argOrDefault @labelKey "label")
      as |valueKey labelKey|
    }}
      {{!template-lint-disable}}
      <input
        tabindex="-1"
        style="opacity: 0px; width:0px; height:0px; position: absolute; top: 40%; border:solid 1px transparent !important; margin:0px !important;"
        class="fake-input-for-html-form-validity"
        {{validatableControl @isInvalid}}
      />
      {{!template-lint-enable}}
      {{#if @legend}}
        <EuiFormFieldset @legend={{@legend}} @compressed={{@compressed}}>
          {{#each @options key=valueKey as |option|}}
            <EuiCheckbox
              form={{@formId}}
              class={{concat "euiCheckboxGroup__item" option.className}}
              {{!@glint-expect-error}}
              @checked={{get @idToSelectedMap (get option valueKey)}}
              @disabled={{or @disabled option.disabled}}
              @compressed={{@compressed}}
              {{!@glint-expect-error}}
              @label={{get option labelKey}}
              {{on "change" (fn @onChange (get option valueKey))}}
            />
          {{/each}}
        </EuiFormFieldset>
      {{else}}
        <div ...attributes>
          {{#each @options key=valueKey as |option|}}
            <EuiCheckbox
              form={{@formId}}
              class={{concat "euiCheckboxGroup__item" option.className}}
              {{!@glint-expect-error}}
              @checked={{get @idToSelectedMap (get option valueKey)}}
              @disabled={{or @disabled option.disabled}}
              @compressed={{@compressed}}
              {{!@glint-expect-error}}
              @label={{get option labelKey}}
              {{on "change" (fn @onChange (get option valueKey))}}
            />
          {{/each}}
        </div>
      {{/if}}
    {{/let}}
  </template>;

export default EuiCheckboxGroup;
