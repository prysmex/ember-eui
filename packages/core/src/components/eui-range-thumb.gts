import castTo from '../helpers/cast-to.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private A draggable thumb of EuiDualRange. */
export interface EuiRangeThumbSignature {
  Element: HTMLButtonElement;
  Args: {
    /** Lowest value. */
    min?: number;
    /** Highest value. */
    max?: number;
    /** The value. */
    value?: number;
    /** Disabled styling. */
    disabled?: boolean;
    /** `tabindex` of the control. */
    tabIndex?: number;
    /** Leaves room for ticks under the track. */
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
