import classNames from '../../helpers/class-names';
import { eq, not } from 'ember-truth-helpers';
import argOrDefault from '../../helpers/arg-or-default';
import EuiPanel from '../eui-panel.gts';
import type { EuiPanelSignature } from '../eui-panel.gts';
import useIsWithinBreakpoints from '../../modifiers/use-is-within-breakpoints';
import type { Named } from '../../modifiers/use-is-within-breakpoints';
import useState from '../../helpers/use-state';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiSplitPanelOuterSignature {
  Element: EuiPanelSignature['Element'];
  Args: {
    direction?: 'column' | 'row';
    responsive?: Named['sizes'];
    grow?: boolean;
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
    hasShadow?: EuiPanelSignature['Args']['hasShadow'];
    color?: EuiPanelSignature['Args']['color'];
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    hasBorder?: EuiPanelSignature['Args']['hasBorder'];
  };
  Blocks: {
    default: [];
  };
}

const DEFAULT_SIZES: Named['sizes'] = ['xs', 's'];

const EuiSplitPanelOuter: TemplateOnlyComponent<EuiSplitPanelOuterSignature> =
  <template>
    {{#let
      (argOrDefault @direction "column")
      (argOrDefault @responsive DEFAULT_SIZES)
      (useState false)
      as |direction responsive isResponsive|
    }}
      <EuiPanel
        class={{classNames
          "euiSplitPanel"
          (if (eq direction "row") "euiSplitPanel--row")
          (if isResponsive.value "euiSplitPanel-isResponsive")
        }}
        @grow={{argOrDefault @grow false}}
        @paddingSize={{argOrDefault @paddingSize "none"}}
        @hasShadow={{@hasShadow}}
        @color={{@color}}
        @borderRadius={{@borderRadius}}
        @hasBorder={{@hasBorder}}
        {{useIsWithinBreakpoints
          sizes=responsive
          isActive=(not (not responsive))
          setIsWithinBreakpointsValue=isResponsive.setState
        }}
        ...attributes
      >
        {{yield}}
      </EuiPanel>
    {{/let}}
  </template>;

export default EuiSplitPanelOuter;
