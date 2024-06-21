import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { sizeMapping } from '../utils/css-mappings/eui-loading-spinner.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiLoadingSpinnerSignature {
  Element: HTMLSpanElement;
  Args: {
    size?: keyof typeof sizeMapping;
  };
}

const EuiLoadingSpinner: TemplateOnlyComponent<EuiLoadingSpinnerSignature> =
  <template>
    <span
      class={{classNames
        componentName="EuiLoadingSpinner"
        size=(argOrDefault @size "m")
      }}
      ...attributes
    ></span>
  </template>;

export default EuiLoadingSpinner;
