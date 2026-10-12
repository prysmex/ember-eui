/*
 * Ported from @elastic/eui 123.1.0 `components/token/token.styles.js`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 * Parity with upstream is checked in scripts/eui-upstream-parity.test.mjs.
 *
 * Upstream reads the visualization palette from `EUI_VIS_COLOR_STORE`, a
 * global singleton the React EuiProvider fills with the outermost theme's
 * `colors.vis`. Ember has no such global, so this port reads the same
 * colors from the theme it is given (`euiTheme.colors.vis`). Borealis
 * visualization colors are identical in light and dark mode, so the output
 * equals upstream's for any provider tree without vis overrides. Everything
 * else is upstream's code with its helpers imported from the extracted
 * upstream sources.
 */
import { serializeStyles } from '@emotion/serialize';
import { mathWithUnits } from '@elastic/eui-theme-common';
import chroma from 'chroma-js';

import {
  highContrastModeStyles,
  isColorDark,
  logicalCSS,
  logicalSizeCSS,
  shade,
  tint,
  TOKEN_COLOR_TO_ICON_COLOR_MAP
} from './styles.generated.ts';

import type { SerializedStyles } from '@emotion/serialize';
import type { EuiBorealisContext } from './theme.ts';

export type EuiTokenFill = 'light' | 'dark' | 'none';

export const TOKEN_COLORS = [
  'euiColorVis0',
  'euiColorVis1',
  'euiColorVis2',
  'euiColorVis3',
  'euiColorVis4',
  'euiColorVis5',
  'euiColorVis6',
  'euiColorVis7',
  'euiColorVis8',
  'euiColorVis9',
  'gray'
] as const;

export type EuiTokenColor = (typeof TOKEN_COLORS)[number];

const css = (...args: unknown[]): SerializedStyles =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

type VisColors = Record<string, string>;

function getTokenColor(
  euiThemeContext: EuiBorealisContext,
  fill: EuiTokenFill,
  color: number | 'gray'
): string | undefined {
  const { euiTheme, colorMode, highContrastMode } = euiThemeContext;
  const vis = euiTheme.colors.vis as unknown as VisColors;
  // upstream: euiPaletteColorBlind() / euiPaletteColorBlindBehindText()
  const visColors = Array.from(
    { length: 10 },
    (_, index) => vis[`euiColorVis${index}`] as string
  );
  const visColorsBehindText = visColors;
  const isVizColor = typeof color === 'number';
  const iconColor = isVizColor
    ? (visColors[color] as string)
    : euiTheme.colors.darkShade;
  const isDarkMode = colorMode === 'DARK';
  const backgroundDarkColor = isVizColor
    ? (visColorsBehindText[color] as string)
    : euiTheme.colors.darkShade;
  const backgroundLightColor = isDarkMode
    ? shade(iconColor, 0.9)
    : tint(iconColor, 0.9);
  const getIconVisColor = (theme: typeof euiTheme, index: number) => {
    const iconColorKey = `euiColorVis${index}`;
    const iconColorToken = (
      TOKEN_COLOR_TO_ICON_COLOR_MAP as Record<string, string>
    )[iconColorKey] as string;
    return (theme.colors.vis as unknown as VisColors)[iconColorToken];
  };
  const lightColor = isVizColor
    ? shade(getIconVisColor(euiTheme, color), 0.3)
    : iconColor;
  const boxShadowColor = highContrastMode
    ? iconColor
    : isDarkMode
      ? shade(iconColor, 0.6)
      : tint(iconColor, 0.2);
  const darkColor = isColorDark(...chroma(backgroundDarkColor).rgb())
    ? euiTheme.colors.textGhost
    : euiTheme.colors.textInk;

  switch (fill) {
    case 'none':
      return `
        // Without a background, the fill color should be the graphic color
        color: ${iconColor};
      `;
    case 'light':
      return `
        color: ${lightColor};
        background-color: ${backgroundLightColor};
        ${highContrastModeStyles(euiThemeContext, {
          none: `box-shadow: inset 0 0 0 ${euiTheme.border.width.thin} ${boxShadowColor};`,
          forced: `border: ${euiTheme.border.thin};`
        })}
      `;
    case 'dark':
      return `
        color: ${darkColor};
        background-color: ${backgroundDarkColor};
      `;
  }
}

export function euiTokenStyles(
  euiThemeContext: EuiBorealisContext,
  fill: EuiTokenFill
): Record<string, SerializedStyles> {
  const { euiTheme } = euiThemeContext;
  const halfInline = mathWithUnits(
    euiTheme.border.radius.inline,
    (x: number) => x / 2
  );
  return {
    // Base
    euiToken: css(
      'display:inline-flex;align-items:center;justify-content:center;svg{',
      logicalCSS('height', '100%'),
      ' margin:auto;};label:euiToken;'
    ),
    // Shapes
    circle: css('border-radius:50%;label:circle;'),
    square: css(
      'border-radius:',
      euiTheme.border.radius.inline,
      ';;label:square;'
    ),
    rectangle: css(
      'box-sizing:content-box;border-radius:',
      euiTheme.border.radius.inline,
      ';;label:rectangle;'
    ),
    // Sizes
    xs: css(
      logicalSizeCSS(euiTheme.size.s),
      " &[class*='-square'],&[class*='-rectangle']{border-radius:",
      halfInline,
      ";}&[class*='-rectangle']{",
      logicalCSS('padding-vertical', '1px'),
      ' ',
      logicalCSS('padding-horizontal', euiTheme.size.xs),
      ';};label:xs;'
    ),
    s: css(
      logicalSizeCSS(euiTheme.size.base),
      " &[class*='-rectangle']{",
      logicalCSS('padding-horizontal', euiTheme.size.xs),
      ';};label:s;'
    ),
    m: css(
      logicalSizeCSS(euiTheme.size.l),
      " &[class*='-rectangle']{",
      logicalCSS('padding-horizontal', euiTheme.size.s),
      ';};label:m;'
    ),
    l: css(
      logicalSizeCSS(euiTheme.size.xl),
      " &[class*='-rectangle']{",
      logicalCSS('padding-horizontal', euiTheme.size.s),
      ';};label:l;'
    ),
    // Colors
    ...Object.fromEntries(
      Array.from({ length: 10 }, (_, index) => [
        `euiColorVis${index}`,
        css(
          getTokenColor(euiThemeContext, fill, index),
          `;label:euiColorVis${index};`
        )
      ])
    ),
    gray: css(getTokenColor(euiThemeContext, fill, 'gray'), ';label:gray;'),
    customColor: css(';label:customColor;'),
    // Fills
    light: css(';label:light;'),
    dark: css(';label:dark;'),
    none: css(';label:none;')
  };
}
