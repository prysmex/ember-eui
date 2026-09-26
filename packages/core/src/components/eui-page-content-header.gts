import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A header row inside EuiPageContent. */
export interface EuiPageContentHeaderSignature {
  Element: HTMLDivElement;
  Args: {
    /** Stacks the sections on small screens. */
    responsive?: boolean;
  };
  Blocks: {
    /** `EuiPageContentHeaderSection`s, e.g. a title and actions. */
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
