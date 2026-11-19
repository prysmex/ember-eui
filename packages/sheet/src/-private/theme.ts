/**
 * The sheet's colours as custom properties, from the resolved EUI theme
 * (V02-DESIGN.md 4.3). One Emotion class on the wrapper defines them; the
 * static CSS of `styles.ts` reads them with light fallbacks, so a surface
 * without the class (portaled) falls back to light colours, not broken ones.
 */
import type { EuiThemeStyleContext } from '@ember-eui/core/theming';

/** `#rrggbb` (or `#rgb`) with an alpha; any other colour as it is. */
function withAlpha(color: string, alpha: number): string {
  const short = /^#([\da-f])([\da-f])([\da-f])$/i.exec(color);
  const long = /^#([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i.exec(color);
  const parts = short
    ? short.slice(1).map((digit) => parseInt(digit + digit, 16))
    : long
      ? long.slice(1).map((pair) => parseInt(pair, 16))
      : null;
  return parts ? `rgba(${parts.join(', ')}, ${alpha})` : color;
}

/** Module scope, so `useEuiBorealisStyles` memoizes it per resolved theme. */
export const sheetThemeVars = ({ euiTheme }: EuiThemeStyleContext) => {
  const colors = euiTheme.colors;
  return {
    label: 'euiSheetTheme',
    '--euiSheet-primary': colors.primary,
    '--euiSheet-selected': colors.backgroundBaseInteractiveSelect,
    '--euiSheet-hover': colors.backgroundBaseInteractiveHover,
    '--euiSheet-plain': colors.backgroundBasePlain,
    '--euiSheet-subdued': colors.backgroundBaseSubdued,
    '--euiSheet-text': colors.textParagraph,
    '--euiSheet-textSubdued': colors.textSubdued,
    '--euiSheet-danger': colors.danger,
    '--euiSheet-textDanger': colors.textDanger,
    '--euiSheet-dangerFilled': colors.backgroundFilledDanger,
    '--euiSheet-textInverse': colors.textInverse,
    '--euiSheet-border': colors.borderBaseSubdued,
    // the theme's shadow colour is opaque; the error box's shadow is light
    '--euiSheet-shadow': withAlpha(colors.shadow, 0.2),
    '--euiSheet-highlight': colors.backgroundLightText,
    // batch 5: link text (url, email, phone, file names) and rating stars
    '--euiSheet-link': colors.textPrimary,
    '--euiSheet-star': colors.textWarning
  };
};
