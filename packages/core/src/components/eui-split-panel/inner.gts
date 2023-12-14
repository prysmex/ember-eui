import argOrDefault from '../../helpers/arg-or-default';
import EuiPanel from '../eui-panel.gts';

import type { EuiPanelSignature } from '../eui-panel.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiSplitPanelInnerSignature {
  Element: EuiPanelSignature['Element'];
  Args: {
    hasShadow?: EuiPanelSignature['Args']['hasShadow'];
    color?: EuiPanelSignature['Args']['color'];
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    hasBorder?: EuiPanelSignature['Args']['hasBorder'];
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
  };
  Blocks: {
    default: [];
  };
}

const EuiSplitPanelInner: TemplateOnlyComponent<EuiSplitPanelInnerSignature> =
  <template>
    <EuiPanel
      class="euiSplitPanel__inner"
      @hasShadow={{argOrDefault @hasShadow false}}
      @color={{argOrDefault @color "transparent"}}
      @borderRadius={{argOrDefault @borderRadius "none"}}
      @hasBorder={{argOrDefault @hasBorder false}}
      @paddingSize={{@paddingSize}}
      ...attributes
    >
      {{yield}}
    </EuiPanel>
  </template>;

export default EuiSplitPanelInner;
