import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The legend of an EuiFormFieldset. */
export interface EuiFormLegendSignature {
  Element: HTMLLegendElement;
  Args: {
    /** `'hidden'` keeps it for screen readers only. Defaults to `'visible'`. */
    display?: 'hidden' | 'visible';
    /** Smaller legend, for compressed forms. */
    compressed?: boolean;
  };
  Blocks: {
    /** The legend text. */
    default: [];
  };
}

const EuiFormLegend: TemplateOnlyComponent<EuiFormLegendSignature> = <template>
  {{#let (argOrDefault @display "visible") as |display|}}
    <legend
      class={{classNames
        (if (eq display "hidden") "euiFormLegend-isHidden")
        (if @compressed "euiFormLegend--compressed")
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
