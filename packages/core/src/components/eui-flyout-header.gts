import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The top of an EuiFlyout, usually with an `EuiTitle`. */
export interface EuiFlyoutHeaderSignature {
  Element: HTMLDivElement;
  Args: {
    /** Adds a border between the header and the body. */
    hasBorder?: boolean;
  };
  Blocks: {
    /** The title, e.g. `<EuiTitle @size="m"><h2>Details</h2></EuiTitle>`. */
    default: [];
  };
}

const EuiFlyoutHeader: TemplateOnlyComponent<EuiFlyoutHeaderSignature> =
  <template>
    <div
      class={{classNames
        "euiFlyoutHeader"
        (if @hasBorder "euiFlyoutHeader--hasBorder")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  </template>;

export default EuiFlyoutHeader;
