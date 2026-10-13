import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { provide } from 'ember-provide-consume-context';

import argOrDefault from '../../helpers/arg-or-default.ts';
import { EUI_SPLIT_PANEL_CONTEXT } from '../../-private/eui-split-panel-context.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import {
  euiBreakpoint,
  euiSplitPanelOuterStyles
} from '../../utils/eui/styles.generated.ts';
import EuiPanel from '../eui-panel.gts';

import type { EuiSplitPanelContext } from '../../-private/eui-split-panel-context.ts';
import type { EuiBreakpointSize } from '../../utils/breakpoint.ts';
import type { EuiCss } from '../../utils/eui/styles.ts';
import type { EuiPanelSignature } from '../eui-panel';

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
    responsive?: EuiBreakpointSize[] | false;
    /** Grows to fill a flex parent. Defaults to `false`. */
    grow?: boolean;
    /** Padding of the outer panel. Defaults to `'none'`. */
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
    /** Adds a shadow (only without a border). Defaults to `false`. */
    hasShadow?: EuiPanelSignature['Args']['hasShadow'];
    /** Background, any `EuiPanel` color. Defaults to `'plain'`. */
    color?: EuiPanelSignature['Args']['color'];
    /** Border radius. Defaults to `'m'`. */
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    /** Adds a border. Defaults to `true` (EuiPanel's default). */
    hasBorder?: EuiPanelSignature['Args']['hasBorder'];
    /**
     * Extra styles composed last into the panel's class (like upstream's
     * `css` prop).
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The `EuiSplitPanelInner` sections. */
    default: [];
  };
}

const DEFAULT_SIZES: EuiBreakpointSize[] = ['xs', 's'];

/**
 * Upstream `EuiSplitPanel.Outer` (EUI 123.1.0). Upstream picks the direction
 * in JS with `useIsWithinBreakpoints`; here the responsive collapse is a
 * media query per breakpoint (same widths), so it needs no resize listener.
 */
export default class EuiSplitPanelOuter
  extends Component<EuiSplitPanelOuterSignature>
  implements EuiSplitPanelContext
{
  @provide(EUI_SPLIT_PANEL_CONTEXT)
  get splitPanelContext(): EuiSplitPanelContext {
    return this;
  }

  get direction(): 'row' | 'column' {
    return this.args.direction === 'row' ? 'row' : 'column';
  }

  get collapseOn(): readonly EuiBreakpointSize[] {
    if (this.direction !== 'row') return [];
    const responsive = this.args.responsive ?? DEFAULT_SIZES;
    return responsive === false ? [] : responsive;
  }

  /** Upstream `_canRenderHighContrastBorder` on the outer panel's own props. */
  get borderDirection(): 'row' | 'column' | undefined {
    return this.args.color === 'transparent' && !this.args.hasBorder
      ? undefined
      : this.direction;
  }

  @cached
  get css(): EuiCss {
    const upstream = getEuiThemeContext(this).upstream;
    const styles = euiSplitPanelOuterStyles;
    const collapse = Object.fromEntries(
      this.collapseOn.map((size) => [
        euiBreakpoint(upstream, [size]),
        styles.column
      ])
    );
    return [
      styles.euiSplitPanelOuter,
      styles[this.direction],
      collapse,
      this.args.css
    ];
  }

  <template>
    <EuiPanel
      class="euiSplitPanel"
      @css={{this.css}}
      @grow={{argOrDefault @grow false}}
      @paddingSize={{argOrDefault @paddingSize "none"}}
      @hasShadow={{@hasShadow}}
      @color={{@color}}
      @borderRadius={{@borderRadius}}
      @hasBorder={{@hasBorder}}
      ...attributes
    >
      {{yield}}
    </EuiPanel>
  </template>
}
