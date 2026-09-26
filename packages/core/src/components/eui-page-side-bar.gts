import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { paddingSizeMapping } from '../utils/css-mappings/eui-page-side-bar.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The side column of an EuiPage, e.g. with an `EuiSideNav`. */
export interface EuiPageSideBarSignature {
  Element: HTMLDivElement;
  Args: {
    /** Keeps the side bar in view while the page scrolls. */
    sticky?: boolean;
    /** Padding: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'l'`. */
    paddingSize?: keyof typeof paddingSizeMapping;
  };
  Blocks: {
    /** The side bar content. */
    default: [];
  };
}

const EuiPageSideBar: TemplateOnlyComponent<EuiPageSideBarSignature> =
  <template>
    <div
      class={{classNames
        (if @sticky "euiPageSideBar--sticky" "")
        componentName="EuiPageSideBar"
        paddingSize=(argOrDefault @paddingSize "l")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  </template>;

export default EuiPageSideBar;
