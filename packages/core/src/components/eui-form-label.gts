import { eq } from 'ember-truth-helpers';

import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The label of a control; EuiFormRow renders it from `@label`. */
export interface EuiFormLabelSignature {
  Element: HTMLLabelElement | HTMLLegendElement;
  Args: {
    /** Focused styling (the control has focus). */
    isFocused?: boolean;
    /** Invalid styling. */
    isInvalid?: boolean;
    /**
     * `'label'` renders a `<label>`, `'legend'` a `<legend>` (for fieldsets).
     * Defaults to `'label'`.
     */
    type?: 'legend' | 'label';
    /** Id of the control it labels. */
    for?: string;
    /** The label text, before the block content. */
    label?: string;
  };
  Blocks: {
    /** The label text. */
    default: [];
  };
}

const EuiFormLabel: TemplateOnlyComponent<EuiFormLabelSignature> = <template>
  {{#let
    (classNames
      (if @isFocused "euiFormLabel-isFocused")
      (if @isInvalid "euiFormLabel-isInvalid")
      "euiFormLabel"
    )
    as |classes|
  }}
    {{#if (eq @type "legend")}}
      <legend class={{classes}} ...attributes>
        {{@label}}
        {{yield}}
      </legend>
    {{else}}
      <label class={{classes}} for={{@for}} ...attributes>
        {{@label}}
        {{yield}}
      </label>
    {{/if}}
  {{/let}}
</template>;

export default EuiFormLabel;
