import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { borderSizeMappping } from '../utils/css-mappings/eui-header-section-item.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** One item of an EuiHeaderSection, e.g. a logo, links or a button. */
export interface EuiHeaderSectionItemSignature {
  Element: HTMLDivElement;
  Args: {
    /** Divider on the `'left'`, `'right'` or `'none'`. Defaults to `'left'`. */
    border?: keyof typeof borderSizeMappping;
  };
  Blocks: {
    /** The item's content. */
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
