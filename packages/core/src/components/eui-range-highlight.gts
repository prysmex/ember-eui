import { hash } from '@ember/helper';

import classNames from '../helpers/class-names.ts';
import inlineStyles from '../helpers/inline-styles.ts';
import simpleStyle from '../modifiers/simple-style.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private The highlighted part of the track of EuiRange / EuiDualRange. */
export interface EuiRangeHighlightSignature {
  Element: HTMLDivElement;
  Args: {
    /** Leaves room for ticks under the track. */
    showTicks?: boolean;
    /** Compressed (smaller) styling. */
    compressed?: boolean;
    /** Focus styling. */
    hasFocus?: boolean;
    /** Start of the highlighted range. */
    lowerValue?: number;
    /** Lowest value. */
    min?: number;
    /** Highest value. */
    max?: number;
    /** End of the highlighted range. */
    upperValue?: number;
  };
}

const EuiRangeHighlight: TemplateOnlyComponent<EuiRangeHighlightSignature> =
  <template>
    <div
      class={{classNames
        "euiRangeHighlight"
        (if @showTicks "euiRangeHighlight--hasTicks")
        (if @compressed "euiRangeHighlight--compressed")
      }}
      ...attributes
    >
      <div
        class={{classNames
          "euiRangeHighlight__progress"
          (if @hasFocus "euiRangeHighlight__progress--hasFocus")
        }}
        {{simpleStyle
          (inlineStyles
            componentName="EuiRangeHighlight"
            componentArgs=(hash
              lowerValue=@lowerValue min=@min max=@max upperValue=@upperValue
            )
          )
        }}
      ></div>
    </div>
  </template>;

export default EuiRangeHighlight;
