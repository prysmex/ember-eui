import classNames from '../helpers/class-names.ts';

import type { paddingMapping } from '../utils/css-mappings/eui-popover-title.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPopoverTitleSignature {
  Element: HTMLDivElement;
  Args: {
    paddingSize?: keyof typeof paddingMapping;
  };
  Blocks: {
    default: [];
  };
}

const EuiPopoverTitle: TemplateOnlyComponent<EuiPopoverTitleSignature> =
  <template>
    <div
      class={{classNames
        paddingSize=@paddingSize
        componentName="EuiPopoverTitle"
      }}
      ...attributes
    >
      {{yield}}
    </div>
  </template>;

export default EuiPopoverTitle;
