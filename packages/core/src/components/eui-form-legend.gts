import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import screenReaderOnly from '../modifiers/screen-reader-only';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFormLegendSignature {
  Element: HTMLLegendElement;
  Args: {
    display?: 'hidden' | 'visible';
    compressed?: boolean;
  };
  Blocks: {
    default: [];
  };
}

const EuiFormLegend: TemplateOnlyComponent<EuiFormLegendSignature> = <template>
  {{#let (argOrDefault @display "visible") as |display|}}
    <legend
      class={{classNames
        (if (eq display "hiddden") "euiFormLengend--isHidden")
        (if @compressed "euiFormLegend--compresed")
        "euiFormLegend"
      }}
      ...attributes
    >
      {{#if (eq display "hidden")}}
        <span {{screenReaderOnly}}>
          {{yield}}
        </span>
      {{else}}
        {{yield}}
      {{/if}}
    </legend>
  {{/let}}
</template>;

export default EuiFormLegend;
