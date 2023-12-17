import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

import type { sizeMapping } from '../utils/css-mappings/eui-spacer';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiSpacerSignature {
  Element: HTMLDivElement;
  Args: {
    size?: keyof typeof sizeMapping;
  };
}

const EuiSpacer: TemplateOnlyComponent<EuiSpacerSignature> = <template>
  <div
    class={{classNames componentName="EuiSpacer" size=(argOrDefault @size "l")}}
    ...attributes
  ></div>
</template>;

export default EuiSpacer;
