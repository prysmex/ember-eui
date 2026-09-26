import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { sizeMapping } from '../utils/css-mappings/eui-spacer.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** Vertical space between elements. */
export interface EuiSpacerSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * `'xs'` (4px), `'s'` (8px), `'m'` (16px), `'l'` (24px), `'xl'` (32px)
     * or `'xxl'` (40px). Defaults to `'l'`.
     */
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
