import { hash } from '@ember/helper';

import { focusTrap } from 'ember-focus-trap';

import EuiOverlayMask from '../eui-overlay-mask.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface FullScreenDisplaySignature {
  Element: HTMLDivElement;
  Args: {};
  Blocks: {
    default: [];
  };
}

const FullScreenDisplay: TemplateOnlyComponent<FullScreenDisplaySignature> =
  <template>
    <EuiOverlayMask>
      <div
        class="euiCodeBlock--fontLarge euiCodeBlock--paddingLarge euiCodeBlock-isFullScreen"
        {{focusTrap
          isActive=true
          focusTrapOptions=(hash clickOutsideDeactivates=true)
        }}
        ...attributes
      >
        {{yield}}
      </div>
    </EuiOverlayMask>
  </template>;

export default FullScreenDisplay;
