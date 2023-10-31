import type { TemplateOnlyComponent } from '@ember/component/template-only';
import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import { sizeMapping } from '../utils/css-mappings/eui-spacer';

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
