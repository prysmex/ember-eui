import { concat } from '@ember/helper';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiRangeLabelSignature {
  Args: {
    side?: 'min' | 'max';
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
