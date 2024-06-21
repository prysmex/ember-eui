import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPageContentHeaderSignature {
  Element: HTMLDivElement;
  Args: {
    responsive?: boolean;
  };
  Blocks: {
    default: [];
  };
}

const EuiPageContentHeader: TemplateOnlyComponent<EuiPageContentHeaderSignature> =
  <template>
    <div
      class={{classNames
        "euiPageContentHeader"
        (if @responsive "euiPageContentHeader--responsive")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  </template>;

export default EuiPageContentHeader;
