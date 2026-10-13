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
