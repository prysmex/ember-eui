import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private Wraps the parts of EuiRange / EuiDualRange. */
export interface EuiRangeWrapperSignature {
  Element: HTMLDivElement;
  Args: {
    /** Stretches to the container's width. */
    fullWidth?: boolean;
    /** Compressed (smaller) styling. */
    compressed?: boolean;
  };
  Blocks: {
    default: [];
  };
}

const EuiRangeWrapper: TemplateOnlyComponent<EuiRangeWrapperSignature> =
  <template>
    <div
      class={{classNames
        "euiRangeWrapper"
        (if @fullWidth "euiRangeWrapper--fullWidth")
        (if @compressed "euiRangeWrapper--compressed")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  </template>;

export default EuiRangeWrapper;
