import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import { marginMapping, sizeMapping } from '../utils/css-mappings/eui-horizontal-rule';

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
