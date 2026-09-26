import argOrDefault from '../../helpers/arg-or-default.ts';
import EuiPanel from '../eui-panel.gts';

import type { EuiPanelSignature } from '../eui-panel';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** One section of an EuiSplitPanelOuter, e.g. a header or footer with its own color. */
export interface EuiSplitPanelInnerSignature {
  Element: EuiPanelSignature['Element'];
  Args: {
    /** Adds a shadow. Defaults to `false`. */
    hasShadow?: EuiPanelSignature['Args']['hasShadow'];
    /** Background, any `EuiPanel` color. Defaults to `'transparent'`. */
    color?: EuiPanelSignature['Args']['color'];
    /** Border radius. Defaults to `'none'`. */
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    /** Adds a border. Defaults to `false`. */
    hasBorder?: EuiPanelSignature['Args']['hasBorder'];
    /** Padding, any `EuiPanel` padding size. */
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
  };
  Blocks: {
    /** The section's content. */
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
