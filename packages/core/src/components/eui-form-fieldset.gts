import { or } from 'ember-truth-helpers';

import EuiFormLegend from './eui-form-legend.gts';

import type { EuiFormLegendSignature } from './eui-form-legend';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFormFieldsetSignature {
  Element: HTMLFieldSetElement;
  Args: {
    legend?: string;
    compressed?: boolean;
    display?: EuiFormLegendSignature['Args']['display'];
  };
  Blocks: {
    default?: [];
    legend?: [];
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
