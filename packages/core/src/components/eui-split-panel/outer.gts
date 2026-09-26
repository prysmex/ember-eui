import { eq, not } from 'ember-truth-helpers';

import argOrDefault from '../../helpers/arg-or-default.ts';
import classNames from '../../helpers/class-names.ts';
import useState from '../../helpers/use-state.ts';
import useIsWithinBreakpoints from '../../modifiers/use-is-within-breakpoints.ts';
import EuiPanel from '../eui-panel.gts';

import type { Named } from '../../modifiers/use-is-within-breakpoints.ts';
import type { EuiPanelSignature } from '../eui-panel';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A panel split into sections (`EuiSplitPanelInner`) with different colors or padding. */
export interface EuiSplitPanelOuterSignature {
  Element: EuiPanelSignature['Element'];
  Args: {
    /** `'column'` stacks the sections, `'row'` puts them side by side. Defaults to `'column'`. */
    direction?: 'column' | 'row';
    /**
     * Screen sizes on which a `'row'` split panel stacks its sections.
     * Defaults to `['xs', 's']`; pass `false` to never stack.
     */
    responsive?: Named['sizes'];
    /** Grows to fill a flex parent. Defaults to `false`. */
    grow?: boolean;
    /** Padding of the outer panel. Defaults to `'none'`. */
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
    /** Adds a shadow. */
    hasShadow?: EuiPanelSignature['Args']['hasShadow'];
    /** Background, any `EuiPanel` color. */
    color?: EuiPanelSignature['Args']['color'];
    /** Border radius. */
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    /** Adds a border. */
    hasBorder?: EuiPanelSignature['Args']['hasBorder'];
  };
  Blocks: {
    /** The `EuiSplitPanelInner` sections. */
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
