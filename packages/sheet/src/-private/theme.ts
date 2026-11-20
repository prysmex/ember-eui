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
export const sheetThemeVars = ({
  euiTheme,
  colorMode
}: EuiThemeStyleContext) => {
  const colors = euiTheme.colors;
  const dark = colorMode === 'DARK';
  return {
    label: 'euiSheetTheme',
    '--euiSheet-primary': colors.primary,
    // V03 batch 1: the range tint is the primary at 12 % (light) / 20 %
    // (dark); EUI's backgroundBaseInteractiveSelect (about rgb(241, 246,
    // 255) on white) was barely visible. Borealis' backgroundLightPrimary
    // is the same token in dark, so it is not stronger.
    '--euiSheet-selected': withAlpha(colors.primary, dark ? 0.2 : 0.12),
    // checked rows: lighter than a range, about hover strength
    '--euiSheet-checked': withAlpha(colors.primary, dark ? 0.1 : 0.06),
    // the open cell editor's elevation (dark needs a stronger shadow)
    '--euiSheet-elevation': withAlpha(colors.shadow, dark ? 0.6 : 0.25),
    '--euiSheet-hover': colors.backgroundBaseInteractiveHover,
    '--euiSheet-plain': colors.backgroundBasePlain,
    '--euiSheet-subdued': colors.backgroundBaseSubdued,
    // V03 batch 3b: group header rows (opaque). Not backgroundBaseSubdued:
    // that is the row-number column's colour (light) and darker than the
    // records in dark, so a header did not stand out; FormsPrepend is one
    // step from the records in both modes
    '--euiSheet-group': colors.backgroundBaseFormsPrepend,
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
    '--euiSheet-star': colors.textWarning,
    // V03 10.2: row colour bars, by name
    '--euiSheet-rowPrimary': colors.primary,
    '--euiSheet-rowAccent': colors.accent,
    '--euiSheet-rowSuccess': colors.success,
    '--euiSheet-rowWarning': colors.warning,
    '--euiSheet-rowDanger': colors.danger,
    '--euiSheet-rowNeutral': colors.textSubdued
  };
};
