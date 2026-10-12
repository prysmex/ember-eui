import Component from '@glimmer/component';
import { or } from 'ember-truth-helpers';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import EuiFormLegend from './eui-form-legend.gts';

import type { CSSObject } from '@emotion/css/create-instance';
import type { EuiFormLegendSignature } from './eui-form-legend';

/**
 * Upstream fieldsets have no styles of their own; React's global reset
 * removes the browser's border, padding, margin and min-content width.
 */
export const euiFieldsetReset: CSSObject = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  border: 'none',
  minInlineSize: 'auto'
};

/** Groups related controls (e.g. radios) under a legend. */
export interface EuiFormFieldsetSignature {
  Element: HTMLFieldSetElement;
  Args: {
    /** The legend describing the group. Use the `<:legend>` block for markup. */
    legend?: string;
    /** Smaller space under the legend, for compressed forms. */
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

export default class EuiFormFieldset extends Component<EuiFormFieldsetSignature> {
  get classes() {
    return euiClass(getEuiThemeContext(this), euiFieldsetReset);
  }

  <template>
    <fieldset class={{this.classes}} ...attributes>
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
  </template>
}
