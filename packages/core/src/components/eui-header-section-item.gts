import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

import { borderSizeMappping } from '../utils/css-mappings/eui-header-section-item';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiHeaderSectionItemSignature {
  Element: HTMLDivElement;
  Args: {
    border: keyof typeof borderSizeMappping;
  };
  Blocks: {
    default: [];
  };
}

const EuiHeaderSectionItem: TemplateOnlyComponent<EuiHeaderSectionItemSignature> =
  <template>
    <div
      class={{classNames
        componentName="EuiHeaderSectionItem"
        borderSide=(argOrDefault @border "left")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  </template>;

export default EuiHeaderSectionItem;
