import classNames from '../helpers/class-names.ts';

import type { paddingMapping } from '../utils/css-mappings/eui-popover-title.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The title of an EuiPopover (separated by a border). */
export interface EuiPopoverTitleSignature {
  Element: HTMLDivElement;
  Args: {
    /** Padding: `'none'`, `'s'`, `'m'` or `'l'`. Should match the popover's. */
    paddingSize?: keyof typeof paddingMapping;
  };
  Blocks: {
    /** The title text. */
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
