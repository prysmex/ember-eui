/*
 * Ported from @elastic/eui 123.1.0 `global_styling/reset/global_styles.js`
 * (the body of the React `EuiGlobalStyles` component, without hooks).
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 * Parity with upstream is checked in scripts/eui-upstream-parity.test.mjs.
 */
import {
  euiFocusRing,
  euiScrollBarStyles,
  resetStyles,
  transparentize
} from './styles.generated.ts';

import type { CSSInterpolation } from '@emotion/css/create-instance';
import type { EuiBorealisContext } from './theme.ts';

// Upstream reads its options through `arguments`, so inference sees one parameter.
const scrollBar = euiScrollBarStyles as (
  context: EuiBorealisContext,
  options: { trackColor?: string; width?: string }
) => string;

/**
 * Upstream's global reset and root typography, in upstream's order. The
 * parts are template fragments: spread them (`injectGlobal(...parts)`); an
 * array argument would be joined with `;` and break declarations. The root
 * `font-size` (body scale, 14px in Borealis) is what upstream `rem` sizes
 * are relative to.
 */
export function euiGlobalStyles(
  euiThemeContext: EuiBorealisContext
): CSSInterpolation[] {
  const { euiTheme, colorMode } = euiThemeContext;
  const { base, colors, font } = euiTheme;
  const scrollbarStyles = scrollBar(euiThemeContext, {
    trackColor: euiTheme.components.scrollbarTrackColor,
    width: 'auto'
  });
  const fontBodyScale = font.scale[font.body.scale];
  const fontReset = {
    fontFamily: font.family,
    fontSize: `${font.defaultUnits === 'px' ? fontBodyScale * base : fontBodyScale}${font.defaultUnits}`,
    lineHeight: base / (fontBodyScale * base),
    fontWeight: font.weight[font.body.weight]
  };
  return [
    resetStyles,
    ' html{',
    scrollbarStyles,
    ' ',
    fontReset,
    ' text-size-adjust:100%;font-kerning:normal;',
    'block-size: 100%;',
    ' background-color:',
    colors.body,
    ';color:',
    colors.textParagraph,
    ';}code,pre,kbd,samp{font-family:',
    font.familyCode,
    ';}input,textarea,select{',
    { ...fontReset, fontSize: '1rem' },
    ';}select:disabled{opacity:1;}button{font-family:',
    font.family,
    ';}em{font-style:italic;}strong{font-weight:',
    font.weight.bold,
    ';}*:focus{',
    euiFocusRing(euiThemeContext),
    ';}::selection{background:',
    transparentize(colors.primary, colorMode === 'LIGHT' ? 0.1 : 0.2),
    ';}a{color:',
    colors.textPrimary,
    ';&,&:hover,&:focus{text-decoration:none;}}.euiBody-hasPortalContent{position:relative;};label:styles;'
  ];
}
