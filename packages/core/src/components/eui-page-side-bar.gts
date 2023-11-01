import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import { paddingSizeMapping } from '../utils/css-mappings/eui-page-side-bar';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPageSideBarSignature {
  Element: HTMLDivElement;
  Args: {
    sticky?: boolean;
    paddingSize?: keyof typeof paddingSizeMapping;
  };
  Blocks: {
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
