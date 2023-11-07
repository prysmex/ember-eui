import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

import {
  alignMapping,
  growMapping
} from '../utils/css-mappings/eui-header-section';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiHeaderSectionSignature {
  Element: HTMLDivElement;
  Args: {
    side?: keyof typeof alignMapping;
    grow?: keyof typeof growMapping;
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
