/**
 * Public theming API: `import { … } from '@ember-eui/core/theming'`.
 *
 * Build your own theme-aware components the way EUI's are built:
 *
 * ```gts
 * import Component from '@glimmer/component';
 * import { cached } from '@glimmer/tracking';
 * import {
 *   euiClass,
 *   getEuiThemeContext,
 *   useEuiBorealisStyles,
 *   type EuiThemeStyleContext
 * } from '@ember-eui/core/theming';
 *
 * const cardStyles = ({ euiTheme }: EuiThemeStyleContext) => ({
 *   root: { padding: euiTheme.size.m, color: euiTheme.colors.textParagraph }
 * });
 *
 * export default class MyCard extends Component {
 *   @cached get classes() {
 *     const context = getEuiThemeContext(this);
 *     return euiClass(context, useEuiBorealisStyles(context, cardStyles).root);
 *   }
 *   <template><div class={{this.classes}} ...attributes>{{yield}}</div></template>
 * }
 * ```
 */
export { getEuiThemeContext } from './utils/emotion/consume.ts';
export {
  euiClass,
  memoizedStyles,
  resolveEuiCss,
  useEuiBorealisStyles
} from './utils/eui/styles.ts';
export {
  euiCssVar,
  euiCssVariableName,
  euiThemeCssVariables
} from './utils/eui/css-variables.ts';
export {
  EUI_UPSTREAM_VERSIONS,
  resolveBorealisTheme
} from './utils/eui/theme.ts';
export { EuiThemeContext } from './utils/emotion/context.ts';

export type { EuiCss, EuiCssFunction } from './utils/eui/styles.ts';
export type { EuiCssVariables } from './utils/eui/css-variables.ts';
export type {
  EuiBorealisContext,
  EuiBorealisContext as EuiThemeStyleContext,
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides,
  EuiHighContrastModeArg
} from './utils/eui/theme.ts';
export type { EuiColorMode } from './utils/emotion/theme.ts';

import {
  euiContainerCSS as _euiContainerCSS,
  euiContainerQuery as _euiContainerQuery,
  euiFullHeight as _euiFullHeight,
  euiScrollBarStyles as _euiScrollBarStyles,
  euiYScroll as _euiYScroll,
  euiYScrollWithShadows as _euiYScrollWithShadows
} from './utils/eui/styles.generated.ts';
import type { SerializedStyles } from '@emotion/serialize';
import type { EuiBorealisContext as _Context } from './utils/eui/theme.ts';

/** `container-type` values accepted by `euiContainerCSS`. */
export type EuiContainerType = 'normal' | 'size' | 'inline-size';

/**
 * Establishes a containment context for container queries (upstream's
 * `euiContainerCSS`): pass the result as `@css`.
 */
export const euiContainerCSS = _euiContainerCSS as (
  type: EuiContainerType,
  name?: string,
  scrollState?: boolean
) => SerializedStyles;

/**
 * An `@container` query rule opener (upstream's `euiContainerQuery`), used
 * in a style string: `${euiContainerQuery('(width < 300px)')} { … }`.
 */
export const euiContainerQuery = _euiContainerQuery as (
  conditions: string,
  containerName?: string
) => string;

/** Options of `euiScrollBarStyles`. */
export interface EuiScrollBarOptions {
  thumbColor?: string;
  trackColor?: string;
  width?: 'thin' | 'auto' | 'none';
  size?: string;
  corner?: string;
}

/** The minimal scroll bar style (upstream's `euiScrollBarStyles`). */
export const euiScrollBarStyles = _euiScrollBarStyles as (
  context: _Context,
  options?: EuiScrollBarOptions
) => string;

/** Vertical scrolling with the minimal scroll bar (upstream's `euiYScroll`). */
export const euiYScroll = _euiYScroll as (
  context: _Context,
  options?: { height?: string }
) => string;

/**
 * Vertical scrolling that masks the scrolled edges (upstream's
 * `euiYScrollWithShadows`).
 */
export const euiYScrollWithShadows = _euiYScrollWithShadows as (
  context: _Context,
  options?: {
    height?: string;
    side?: 'both' | 'start' | 'end';
    hasAnimatedOverflowShadow?: boolean;
  }
) => string;

/** `height: 100%; flex: 1 1 auto; overflow: hidden` (upstream's `euiFullHeight`). */
export const euiFullHeight = _euiFullHeight as () => string;
