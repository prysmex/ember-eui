import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { alignMapping } from '../utils/css-mappings/eui-header-section.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A group of `EuiHeaderSectionItem`s on one side of the header. */
export interface EuiHeaderSectionSignature {
  Element: HTMLDivElement;
  Args: {
    /** `'left'` or `'right'`. Defaults to `'left'`. */
    side?: keyof typeof alignMapping;
    /** Takes the remaining space, e.g. for a search bar. Defaults to `false`. */
    grow?: boolean;
  };
  Blocks: {
    /** The `EuiHeaderSectionItem`s. */
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
