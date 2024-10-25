import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { alignMapping } from '../utils/css-mappings/eui-header-section.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiHeaderSectionSignature {
  Element: HTMLDivElement;
  Args: {
    side?: keyof typeof alignMapping;
    grow?: boolean;
  };
  Blocks: {
    default: [];
  };
}

const EuiHeaderSection: TemplateOnlyComponent<EuiHeaderSectionSignature> =
  <template>
    <div
      class={{classNames
        componentName="EuiHeaderSection"
        alignItems=(argOrDefault @side "left")
        grow=(argOrDefault @grow false)
      }}
      ...attributes
    >
      {{yield}}
    </div>
  </template>;

export default EuiHeaderSection;
