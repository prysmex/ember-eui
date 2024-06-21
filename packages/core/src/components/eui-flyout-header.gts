import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFlyoutHeaderSignature {
  Element: HTMLDivElement;
  Args: {
    hasBorder?: boolean;
  };
  Blocks: {
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
