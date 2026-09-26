import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { marginMapping, sizeMapping } from '../utils/css-mappings/eui-horizontal-rule.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A divider line between sections. */
export interface EuiHorizontalRuleSignature {
  Element: HTMLHRElement;
  Args: {
    /**
     * Space above and below: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'`, `'xl'`
     * or `'xxl'`. Defaults to `'l'`.
     */
    margin?: keyof typeof marginMapping;
    /** Width: `'full'`, `'half'` or `'quarter'`. Defaults to `'full'`. */
    size?: keyof typeof sizeMapping;
  };
}

const EuiHorizontalRule: TemplateOnlyComponent<EuiHorizontalRuleSignature> =
  <template>
    <hr
      class={{classNames
        componentName="EuiHorizontalRule"
        margin=(argOrDefault @margin "l")
        size=(argOrDefault @size "full")
      }}
      ...attributes
    />
  </template>;

export default EuiHorizontalRule;
