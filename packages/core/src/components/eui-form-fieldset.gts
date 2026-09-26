import { or } from 'ember-truth-helpers';

import EuiFormLegend from './eui-form-legend.gts';

import type { EuiFormLegendSignature } from './eui-form-legend';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** Groups related controls (e.g. radios) under a legend. */
export interface EuiFormFieldsetSignature {
  Element: HTMLFieldSetElement;
  Args: {
    /** The legend describing the group. Use the `<:legend>` block for markup. */
    legend?: string;
    /** Smaller legend, for compressed forms. */
    compressed?: boolean;
    /**
     * `'hidden'` keeps the legend for screen readers only.
     * Defaults to `'visible'`.
     */
    display?: EuiFormLegendSignature['Args']['display'];
  };
  Blocks: {
    /** The controls. */
    default?: [];
    /** The legend, instead of `@legend`. */
    legend?: [];
    /** The controls; same as the default block. */
    fieldset?: [];
  };
}

const EuiFormFieldset: TemplateOnlyComponent<EuiFormFieldsetSignature> =
  <template>
    <fieldset ...attributes>
      {{#if (or @legend (has-block "legend"))}}
        <EuiFormLegend @compressed={{@compressed}} @display={{@display}}>
          {{#if (has-block "legend")}}
            {{yield to="legend"}}
          {{else}}
            {{@legend}}
          {{/if}}
        </EuiFormLegend>
      {{/if}}
      {{#if (has-block "fieldset")}}
        {{yield to="fieldset"}}
      {{else}}
        {{yield}}
      {{/if}}
    </fieldset>
  </template>;

export default EuiFormFieldset;
