import classNames from '../helpers/class-names';
import { eq } from 'ember-truth-helpers';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFormLabelSignature {
  Element: HTMLLabelElement | HTMLLegendElement;
  Args: {
    isFocused?: boolean;
    isInvalid?: boolean;
    type?: 'legend' | 'label';
    for?: string;
    label?: string;
  };
  Blocks: {
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
      <legend class={{classes}} for={{@for}} ...attributes>
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
