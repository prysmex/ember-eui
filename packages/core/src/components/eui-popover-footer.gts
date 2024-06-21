import classNames from '../helpers/class-names.ts';

import type { paddingMapping } from '../utils/css-mappings/eui-popover-footer.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPopoverFooterSignature {
  Element: HTMLDivElement;
  Args: {
    paddingSize?: keyof typeof paddingMapping;
  };
  Blocks: {
    default: [];
  };
}

const EuiPopoverFooter: TemplateOnlyComponent<EuiPopoverFooterSignature> =
  <template>
    <div
      class={{classNames
        paddingSize=@paddingSize
        componentName="EuiPopoverFooter"
      }}
      ...attributes
    >
      {{yield}}
    </div>
  </template>;

export default EuiPopoverFooter;
