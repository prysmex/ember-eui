import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { borderSizeMappping } from '../utils/css-mappings/eui-header-section-item.ts';
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
