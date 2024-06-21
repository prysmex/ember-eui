import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { marginMapping, sizeMapping } from '../utils/css-mappings/eui-horizontal-rule.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiHorizontalRuleSignature {
  Element: HTMLHRElement;
  Args: {
    margin?: keyof typeof marginMapping;
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
