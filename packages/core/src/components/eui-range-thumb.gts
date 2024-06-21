import castTo from '../helpers/cast-to.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiRangeThumbSignature {
  Element: HTMLButtonElement;
  Args: {
    min?: number;
    max?: number;
    value?: number;
    disabled?: boolean;
    tabIndex?: number;
    showTicks?: boolean;
  };
}

const EuiRangeThumb: TemplateOnlyComponent<EuiRangeThumbSignature> = <template>
  {{! template-lint-disable }}
  <button
    type="button"
    class={{classNames
      "euiRangeThumb"
      (if @showTicks "euiRangeThumb--hasTicks")
    }}
    aria-valuemin={{@min}}
    aria-valuemax={{@max}}
    aria-valuenow={{castTo @value to="number"}}
    aria-diabled={{@disabled}}
    tabindex={{if @disabled -1 (if @tabIndex @tabIndex 0)}}
    ...attributes
  >
    <div
      role="slider"
      aria-valuemin={{@min}}
      aria-valuemax={{@max}}
      aria-valuenow={{castTo @value to="number"}}
      aria-diabled={{@disabled}}
      tabindex={{if @disabled -1 (if @tabIndex 0)}}
    ></div>
  </button>
  {{! template-lint-enable }}
</template>;

export default EuiRangeThumb;
