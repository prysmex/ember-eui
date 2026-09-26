import { concat } from '@ember/helper';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private A min/max label of EuiRange / EuiDualRange (`@showLabels`). */
export interface EuiRangeLabelSignature {
  Args: {
    /** Which end it is for: `'min'` or `'max'`. */
    side?: 'min' | 'max';
    /** Disabled styling. */
    disabled?: boolean;
  };
  Blocks: {
    default: [];
  };
}

const EuiRangeLabel: TemplateOnlyComponent<EuiRangeLabelSignature> = <template>
  <label
    class={{classNames
      "euiRangeLabel"
      (concat "euiRangeLabel--" (argOrDefault @side "max"))
      (if @disabled "euiRangeLabel--isDisabled")
    }}
  >
    {{yield}}
  </label>
</template>;

export default EuiRangeLabel;
