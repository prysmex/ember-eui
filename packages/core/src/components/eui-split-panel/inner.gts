import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { euiSplitPanelContext } from '../../-private/eui-split-panel-context.ts';
import argOrDefault from '../../helpers/arg-or-default.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import {
  euiBreakpoint,
  euiSplitPanelInnerStyles
} from '../../utils/eui/styles.generated.ts';
import EuiPanel from '../eui-panel.gts';

import type { EuiCss } from '../../utils/eui/styles.ts';
import type { EuiPanelSignature } from '../eui-panel';

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
    /** Padding, any `EuiPanel` padding size. Defaults to `'m'`. */
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
    /** Grows to share the outer panel's space. Defaults to `true`. */
    grow?: EuiPanelSignature['Args']['grow'];
    /**
     * Extra styles composed last into the panel's class (like upstream's
     * `css` prop).
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The section's content. */
    default: [];
  };
}

// Undoes the row divider where a responsive row has collapsed to a column.
const NO_ROW_DIVIDER = '&:not(:last-child){border-inline-end:none;}';

/** Upstream `EuiSplitPanel.Inner` (EUI 123.1.0). */
export default class EuiSplitPanelInner extends Component<EuiSplitPanelInnerSignature> {
  @cached
  get css(): EuiCss {
    const outer = euiSplitPanelContext(this);
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSplitPanelInnerStyles);
    const direction = outer?.borderDirection;
    // A collapsed responsive row draws column dividers instead.
    const collapse =
      direction === 'row'
        ? outer!.collapseOn
            .map(
              (size) =>
                `${euiBreakpoint(context.upstream, [size])}{${
                  styles.highContrastBorders.column
                }${context.upstream.highContrastMode === 'preferred' ? NO_ROW_DIVIDER : ''}}`
            )
            .join('')
        : undefined;
    return [
      styles.euiSplitPanelInner,
      direction && styles.highContrastBorders[direction],
      collapse,
      this.args.css
    ];
  }

  <template>
    <EuiPanel
      class="euiSplitPanel__inner"
      @css={{this.css}}
      @hasShadow={{argOrDefault @hasShadow false}}
      @color={{argOrDefault @color "transparent"}}
      @borderRadius={{argOrDefault @borderRadius "none"}}
      @hasBorder={{argOrDefault @hasBorder false}}
      @paddingSize={{@paddingSize}}
      @grow={{@grow}}
      ...attributes
    >
      {{yield}}
    </EuiPanel>
  </template>
}
