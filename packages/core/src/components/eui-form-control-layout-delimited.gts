import argOrDefault from '../helpers/arg-or-default';
import { and, or } from 'ember-truth-helpers';
import EuiFormControlLayout from './eui-form-control-layout.gts';
import type { EuiFormControlLayoutSignature } from './eui-form-control-layout.gts';
import EuiText from './eui-text.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFormControlLayoutDelimitedSignature {
  Args: {
    icon?: string;
    clear?: EuiFormControlLayoutSignature['Args']['clear'];
    fullWidth?: EuiFormControlLayoutSignature['Args']['fullWidth'];
    isLoading?: EuiFormControlLayoutSignature['Args']['isLoading'];
    compressed?: EuiFormControlLayoutSignature['Args']['compressed'];
    readOnly?: EuiFormControlLayoutSignature['Args']['readOnly'];
    disabled?: EuiFormControlLayoutSignature['Args']['disabled'];
    delimiter?: string;
    useGroup?: boolean;
  };
  Blocks: {
    prepend: EuiFormControlLayoutSignature['Blocks']['prepend'];
    startControl: [classes: string];
    delimiter: [];
    endControl: [classes: string];
    append: EuiFormControlLayoutSignature['Blocks']['append'];
  };
}

const EuiFormControlLayoutDelimited: TemplateOnlyComponent<EuiFormControlLayoutDelimitedSignature> =
  <template>
    {{#let
      (has-block "prepend")
      (has-block "append")
      (has-block "delimiter")
      (argOrDefault @delimiter "→")
      (argOrDefault @useGroup true)
      as |hasPrepend hasAppend hasDelimeterBlock delimiter useGroup|
    }}
      <EuiFormControlLayout
        class="euiFormControlLayoutDelimited"
        @icon={{@icon}}
        @clear={{@clear}}
        @fullWidth={{@fullWidth}}
        @isLoading={{@isLoading}}
        @compressed={{@compressed}}
        @readOnly={{@readOnly}}
        @disabled={{@disabled}}
        @useGroup={{and useGroup (or hasPrepend hasAppend)}}
      >
        <:prepend as |prependClasses|>
          {{yield prependClasses to="prepend"}}
        </:prepend>
        <:field>
          {{yield "euiFormControlLayoutDelimited__input" to="startControl"}}
          <EuiText
            class="euiFormControlLayoutDelimited__delimeter"
            @size="s"
            @color="subdued"
          >
            {{#if (or delimiter hasDelimeterBlock)}}
              {{#if hasDelimeterBlock}}
                {{yield to="delimiter"}}
              {{else}}
                {{delimiter}}
              {{/if}}
            {{/if}}
          </EuiText>
          {{yield "euiFormControlLayoutDelimited__input" to="endControl"}}
        </:field>
        <:append as |appendClasses|>
          {{yield appendClasses to="append"}}
        </:append>
      </EuiFormControlLayout>
    {{/let}}
  </template>;

export default EuiFormControlLayoutDelimited;
