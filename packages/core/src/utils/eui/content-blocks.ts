/*
 * Ember composition helpers for the content-blocks family (EuiCallOut,
 * EuiEmptyPrompt). Upstream renders these as an `EuiPanel` with extra `css`,
 * which Emotion merges into one class. Ember cannot pass Emotion styles into
 * EuiPanel, and two separate classes would make the winner depend on
 * insertion order, so the panel slots are composed here in upstream's order
 * (EUI 123.1.0 `panel.js`) ahead of the component's own styles.
 */
import { useEuiBorealisStyles } from './styles.ts';
import {
  euiPanelStyles,
  euiBackgroundColor,
  euiBorderColor
} from './styles.generated.ts';

import type { CSSInterpolation, CSSObject } from '@emotion/css/create-instance';
import type { EuiThemeContext } from '../emotion/context.ts';

export interface EuiPanelSurfaceOptions {
  color: string;
  hasBorder: boolean;
  borderRadius: 'none' | 'm';
  grow: boolean;
}

/** The scoped reset `eui-panel.gts` uses in place of React's global reset. */
const PANEL_RESET: CSSObject = {
  boxSizing: 'border-box',
  display: 'block',
  padding: 0,
  border: 'none',
  borderRadius: 0,
  boxShadow: 'none',
  font: 'inherit',
  textAlign: 'start'
};

/**
 * EuiPanel's surface (`paddingSize="none"`, no shadow) plus its scoped reset,
 * in upstream's order. Factories go through `useEuiBorealisStyles`.
 */
export function euiPanelSurfaceCss(
  context: EuiThemeContext,
  { color, hasBorder, borderRadius, grow }: EuiPanelSurfaceOptions
): CSSInterpolation[] {
  const upstream = context.upstream;
  const styles = useEuiBorealisStyles(context, euiPanelStyles);
  const canHaveBorder = color === 'plain' || color === 'transparent';
  return [
    PANEL_RESET,
    { color: upstream.euiTheme.colors.textParagraph },
    styles.euiPanel,
    grow && styles.grow,
    styles.radius[borderRadius],
    { backgroundColor: euiBackgroundColor(upstream, color) },
    canHaveBorder && hasBorder && styles.hasBorder,
    upstream.highContrastMode &&
      !(color === 'transparent' && !hasBorder) && {
        border: upstream.euiTheme.border.thin,
        borderColor: euiBorderColor(upstream, color)
      }
  ];
}
