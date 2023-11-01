import classNames from '../helpers/class-names';
import simpleStyle from '../modifiers/simple-style';
import inlineStyles from '../helpers/inline-styles';
import { hash } from '@ember/helper';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiRangeHighlightSignature {
  Element: HTMLDivElement;
  Args: {
    showTicks?: boolean;
    compressed?: boolean;
    hasFocus?: boolean;
    lowerValue?: number;
    min?: number;
    max?: number;
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
