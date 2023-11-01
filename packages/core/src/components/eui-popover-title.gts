import classNames from '../helpers/class-names';

import { paddingMapping } from '../utils/css-mappings/eui-popover-title';

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
