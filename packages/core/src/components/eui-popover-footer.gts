import classNames from '../helpers/class-names.ts';

import type { paddingMapping } from '../utils/css-mappings/eui-popover-footer.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The footer of an EuiPopover (separated by a border). */
export interface EuiPopoverFooterSignature {
  Element: HTMLDivElement;
  Args: {
    /** Padding: `'none'`, `'s'`, `'m'` or `'l'`. Should match the popover's. */
    paddingSize?: keyof typeof paddingMapping;
  };
  Blocks: {
    /** E.g. a full width button. */
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
