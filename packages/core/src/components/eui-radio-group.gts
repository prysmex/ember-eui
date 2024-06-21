import { concat, fn,get } from '@ember/helper';
import { on } from '@ember/modifier';

import { eq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import EuiFormFieldset from './eui-form-fieldset.gts';
import EuiRadio from './eui-radio.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiRadioGroupSignature {
  Element: HTMLDivElement;
  Args: {
    idSelected: string;
    options: Array<{
      id: string;
      label: string;
      value?: string;
      disabled?: boolean;
      className?: string;
    }>;
    name?: string;
    legend?: string;
    compressed?: boolean;
    disabled?: boolean;
    onChange: (id: string, value?: string) => void;
    valueKey?: string;
    labelKey?: string;
    formId?: string;
  };
}

const EuiRadioGroup: TemplateOnlyComponent<EuiRadioGroupSignature> = <template>
  {{#let
    (argOrDefault @valueKey "id") (argOrDefault @labelKey "label")
    as |valueKey labelKey|
  }}
    {{#if @legend}}
      <EuiFormFieldset @legend={{@legend}} @compressed={{@compressed}}>
        {{#each @options key="id" as |option|}}
          <EuiRadio
            class={{concat "euiRadioGroup__item" option.className}}
            form={{@formId}}
            @checked={{eq @idSelected (get option valueKey)}}
            @disabled={{or @disabled option.disabled}}
            @compressed={{@compressed}}
            {{!@glint-expect-error}}
            @label={{get option labelKey}}
            {{!@glint-expect-error}}
            {{on "change" (fn @onChange (get option valueKey) option.value)}}
          />
        {{/each}}
      </EuiFormFieldset>
    {{else}}
      <div ...attributes>
        {{#each @options key="id" as |option|}}
          <EuiRadio
            class={{concat "euiRadioGroup__item" option.className}}
            form={{@formId}}
            @name={{@name}}
            @checked={{eq @idSelected (get option valueKey)}}
            @disabled={{or @disabled option.disabled}}
            @compressed={{@compressed}}
            {{!@glint-expect-error}}
            @label={{get option labelKey}}
            {{!@glint-expect-error}}
            {{on "change" (fn @onChange (get option valueKey) option.value)}}
          />
        {{/each}}
      </div>
    {{/if}}
  {{/let}}
</template>;

export default EuiRadioGroup;
