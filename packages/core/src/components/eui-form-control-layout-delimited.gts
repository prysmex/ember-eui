import { and, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import EuiFormControlLayout from './eui-form-control-layout.gts';
import EuiText from './eui-text.gts';

import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * Two controls in one field with a delimiter between them, e.g. a number
 * range ("0 → 100") or start and end dates.
 */
export interface EuiFormControlLayoutDelimitedSignature {
  Args: {
    /** Icon at the start of the control, anything `EuiIcon`'s `@type` accepts. */
    icon?: string;
    /** Shows a clear ("x") button calling this function. */
    clear?: EuiFormControlLayoutSignature['Args']['clear'];
    /** Stretches the control to its container's width. */
    fullWidth?: EuiFormControlLayoutSignature['Args']['fullWidth'];
    /** Shows a spinner. */
    isLoading?: EuiFormControlLayoutSignature['Args']['isLoading'];
    /** Shorter control, for dense forms. */
    compressed?: EuiFormControlLayoutSignature['Args']['compressed'];
    /** Read-only styling. */
    readOnly?: EuiFormControlLayoutSignature['Args']['readOnly'];
    /** Disabled styling. */
    disabled?: EuiFormControlLayoutSignature['Args']['disabled'];
    /** Text between the two controls. Defaults to `'→'`. */
    delimiter?: string;
    /** Styles it as a group with `<:prepend>` / `<:append>`. Defaults to `true`. */
    useGroup?: boolean;
  };
  Blocks: {
    /** Content before the controls; yields the class to put on it. */
    prepend: EuiFormControlLayoutSignature['Blocks']['prepend'];
    /**
     * The first control, e.g. an `EuiFieldNumber @controlOnly={{true}}`;
     * yields the class to put on it.
     */
    startControl: [classes: string];
    /** Custom delimiter content, instead of `@delimiter`. */
    delimiter: [];
    /** The second control; yields the class to put on it. */
    endControl: [classes: string];
    /** Content after the controls; yields the class to put on it. */
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
