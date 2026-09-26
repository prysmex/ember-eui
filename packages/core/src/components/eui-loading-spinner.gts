import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { sizeMapping } from '../utils/css-mappings/eui-loading-spinner.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A spinning circle, for loading content or actions in progress. */
export interface EuiLoadingSpinnerSignature {
  Element: HTMLSpanElement;
  Args: {
    /** `'s'`, `'m'`, `'l'` or `'xl'`. Defaults to `'m'`. */
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
