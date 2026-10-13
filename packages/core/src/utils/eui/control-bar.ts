/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * EuiControlBar styles on Borealis tokens.
 *
 * Upstream removed EuiControlBar after EUI 91.3.1 (92.0.0 ships no
 * `components/control_bar`), before it was converted to Emotion, so EUI
 * 123.1.0 has no style factory for it. This is a translation of the last
 * upstream styles (EUI 91.3.1 `components/control_bar/_control_bar.scss` and
 * `_variables.scss`) to the Borealis theme, using the extracted upstream
 * helpers where Sass used mixins. Like upstream 91.3.1, which wrapped the bar
 * in `EuiThemeProvider colorMode="dark"`, the bar itself is styled from the
 * dark theme (`euiControlBarStyles`); the content area and the active tab
 * were styled with the *page* colors (`$euiPageBackgroundColor`,
 * `$euiColorDarkestShade`, primary), so they come from the surrounding theme
 * (`euiControlBarPageStyles`).
 *
 * - `$euiControlBarBackground` (`darkestShade` / `ink`) → the dark theme's
 *   `components.bottomBarBackground`, as the other dark bar (EuiBottomBar).
 * - `$euiControlBarText` → dark `colors.textParagraph`.
 * - `$euiControlBarBorderColor` (`transparentize(ghost, .8)`) → dark
 *   `border.color`.
 * - `$euiControlBarInitialHeight` (`$euiSizeXXL`) → `size.xxl`; max height
 *   `calc(100vh - size.base * 5)`; heights `s`/`m` = `size.base` × 15 / 30,
 *   `l` = 100vh.
 * - `$euiZMask` (fixed) → `levels.mask`; `$euiZLevel1` (absolute, 1000) →
 *   `levels.header` (the same level in Borealis).
 * - `$euiPageBackgroundColor` → page `colors.body`; `$euiColorDarkestShade`
 *   content text → page `colors.textParagraph`; active tab
 *   `makeHighContrastColor($euiColorPrimary, $euiColorLightestShade)` →
 *   page `colors.textPrimary`.
 * - `euiScrollBar`, `euiTextTruncate`, `euiFontSizeS` and
 *   `euiBreakpoint('xs', 's')` are the upstream JS mixins (`euiScrollBarStyles`,
 *   `euiTextTruncate`, `euiFontSize(s)`, `euiMaxBreakpoint(m)`).
 * - Animations are guarded by `euiCanAnimate` (Sass had no reduced motion
 *   guard); the open transform is also set statically so a bar that does
 *   not animate still ends in its open position.
 * - Not translated: the per-color link/button/button icon/breadcrumb
 *   `makeHighContrastColor` overrides. The controls render inside the dark
 *   provider, whose Borealis tokens are already contrast checked against
 *   the dark bar.
 */
import { serializeStyles } from '@emotion/serialize';

import {
  euiCanAnimate,
  euiFontSize,
  euiMaxBreakpoint,
  euiScrollBarStyles,
  euiTextTruncate,
  logicalCSS
} from './styles.generated.ts';

import type { SerializedStyles } from '@emotion/serialize';
import type { EuiBorealisContext } from './theme.ts';

const css = (...args: unknown[]): SerializedStyles =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

/** Same shape as Emotion's `keyframes` (and the generated upstream helper). */
const keyframes = (...args: unknown[]) => {
  const value = css(...args);
  const name = `animation-${value.name}`;
  return {
    name,
    styles: `@keyframes ${name}{${value.styles}}`,
    anim: 1,
    toString() {
      return `_EMO_${name}_${this.styles}_EMO_`;
    }
  };
};

export const CONTROL_BAR_SIZES = ['s', 'm', 'l'] as const;
export type EuiControlBarSize = (typeof CONTROL_BAR_SIZES)[number];

export const CONTROL_BAR_POSITIONS = ['fixed', 'absolute', 'relative'] as const;
export type EuiControlBarPosition = (typeof CONTROL_BAR_POSITIONS)[number];

/** `$euiControlBarInitialHeight`, `$euiControlBarMaxHeight`, `$euiControlBarHeights`. */
export const euiControlBarVariables = ({ euiTheme }: EuiBorealisContext) => {
  const base = parseFloat(euiTheme.size.base);
  return {
    initialHeight: euiTheme.size.xxl,
    maxHeight: `calc(100vh - ${base * 5}px)`,
    heights: {
      s: `${base * 15}px`,
      m: `${base * 30}px`,
      l: '100vh'
    } as Record<EuiControlBarSize, string>
  };
};

/** The bar, controls and control types; call it with the bar's (dark) theme. */
export const euiControlBarStyles = (euiThemeContext: EuiBorealisContext) => {
  const { euiTheme } = euiThemeContext;
  const { initialHeight, maxHeight, heights } =
    euiControlBarVariables(euiThemeContext);
  const background = euiTheme.components.bottomBarBackground;
  const text = euiTheme.colors.textParagraph;
  const border = euiTheme.border.color;
  const fontS = euiFontSize(euiThemeContext, 's', {});

  const open = (size: EuiControlBarSize) => {
    // Accounts for the initial height offset from the top (large only).
    const from =
      size === 'l' ? `calc((${initialHeight} * 3) * -1)` : `-${initialHeight}`;
    const animation = keyframes(
      '0%{transform:translateY(',
      from,
      ');}100%{transform:translateY(-',
      heights[size],
      ');}'
    );
    return css(
      logicalCSS('height', size === 'l' ? maxHeight : heights[size]),
      'bottom:-',
      heights[size],
      ';transform:translateY(-',
      heights[size],
      ');',
      euiCanAnimate,
      '{animation:',
      animation,
      ' ',
      euiTheme.animation.normal,
      ' ',
      euiTheme.animation.resistance,
      ' forwards;}',
      `;label:${size === 'l' ? 'large' : size === 'm' ? 'medium' : 'small'};`
    );
  };

  return {
    euiControlBar: css(
      'box-sizing:border-box;background:',
      background,
      ';color:',
      text,
      ';display:flex;flex-direction:column;',
      // This large box shadow helps prevent a flicker of the page
      // background when the content is shown and hidden.
      'box-shadow:inset 0 ',
      initialHeight,
      ' 0 ',
      background,
      ',inset 0 600rem 0 var(--euiControlBarPageBackground, ',
      euiTheme.colors.body,
      ');bottom:0;transform:translateY(0);',
      logicalCSS('height', initialHeight),
      logicalCSS('max-height', maxHeight),
      euiMaxBreakpoint(euiThemeContext, 'm'),
      '{display:none;}',
      ';label:euiControlBar;'
    ),
    showOnMobile: css(
      euiMaxBreakpoint(euiThemeContext, 'm'),
      '{display:flex;};label:showOnMobile;'
    ),
    fixed: css(
      'position:fixed;z-index:',
      euiTheme.levels.mask,
      ';;label:fixed;'
    ),
    absolute: css(
      'position:absolute;z-index:',
      euiTheme.levels.header,
      ';;label:absolute;'
    ),
    relative: css('position:relative;;label:relative;'),
    open: {
      s: open('s'),
      m: open('m'),
      l: open('l')
    } as Record<EuiControlBarSize, SerializedStyles>,
    euiControlBar__controls: css(
      'box-sizing:border-box;',
      logicalCSS('height', initialHeight),
      logicalCSS('width', '100%'),
      'display:flex;align-items:center;',
      // Ensures the movement of buttons in :focus don't cause scrollbars
      'overflow-y:hidden;overflow-x:auto;',
      logicalCSS('padding-vertical', 0),
      logicalCSS('padding-horizontal', euiTheme.size.m),
      // EuiButton takes no `@css` yet: its layout comes from here.
      '& > .euiControlBar__button{flex-shrink:0;',
      logicalCSS('margin-left', euiTheme.size.xs),
      '}& > .euiControlBar__button:last-child{',
      logicalCSS('margin-right', euiTheme.size.xs),
      '}',
      ';label:euiControlBar__controls;'
    ),
    euiControlBar__icon: css(
      'flex-shrink:0;',
      logicalCSS('margin-horizontal', euiTheme.size.s),
      ';label:euiControlBar__icon;'
    ),
    euiControlBar__buttonIcon: css(
      'flex-shrink:0;',
      logicalCSS('min-width', initialHeight),
      logicalCSS('min-height', initialHeight),
      ';label:euiControlBar__buttonIcon;'
    ),
    euiControlBar__spacer: css(
      'flex-grow:1;',
      logicalCSS('height', '100%'),
      ';label:euiControlBar__spacer;'
    ),
    euiControlBar__divider: css(
      'flex-shrink:0;',
      logicalCSS('height', '100%'),
      logicalCSS('width', euiTheme.border.width.thin),
      'background-color:',
      border,
      ';;label:euiControlBar__divider;'
    ),
    euiControlBar__text: css(
      euiTextTruncate(),
      'font-size:',
      fontS.fontSize,
      ';line-height:',
      fontS.lineHeight,
      ';',
      logicalCSS('padding-vertical', 0),
      logicalCSS('padding-horizontal', euiTheme.size.s),
      'color:',
      text,
      ';&:last-child{',
      logicalCSS('padding-right', 0),
      '};label:euiControlBar__text;'
    ),
    euiControlBar__tab: css(
      // React global button reset
      'box-sizing:border-box;margin:0;border:none;background:none;font-family:inherit;font-weight:inherit;',
      euiTextTruncate(),
      'font-size:',
      fontS.fontSize,
      ';line-height:',
      fontS.lineHeight,
      ';color:',
      text,
      ';',
      logicalCSS('padding-vertical', 0),
      logicalCSS('padding-horizontal', euiTheme.size.base),
      'text-align:center;',
      logicalCSS('height', '100%'),
      'flex-shrink:0;&:hover,&:focus{text-decoration:underline;cursor:pointer;}',
      ';label:euiControlBar__tab;'
    )
  };
};

/** Parts styled with the page (surrounding) theme. */
export const euiControlBarPageStyles = (euiThemeContext: EuiBorealisContext) => {
  const { euiTheme } = euiThemeContext;
  const { initialHeight } = euiControlBarVariables(euiThemeContext);
  const showContent = keyframes('0%{opacity:0;}100%{opacity:1;}');
  return {
    /** On the bar: the page color its flicker-guard shadow shows. */
    pageBackground: css(
      '--euiControlBarPageBackground:',
      euiTheme.colors.body,
      ';;label:pageBackground;'
    ),
    euiControlBar__content: css(
      'box-sizing:border-box;',
      euiScrollBarStyles(euiThemeContext),
      'overflow-y:auto;',
      logicalCSS('width', '100%'),
      logicalCSS('height', `calc(100% - ${initialHeight})`),
      'background-color:',
      euiTheme.colors.body,
      ';color:',
      euiTheme.colors.textParagraph,
      ';',
      euiCanAnimate,
      '{animation:',
      showContent,
      ' ',
      euiTheme.animation.slow,
      ' ',
      euiTheme.animation.resistance,
      ' 1;}',
      ';label:euiControlBar__content;'
    ),
    activeTab: css(
      'background-color:',
      euiTheme.colors.body,
      ';box-shadow:inset 0 ',
      euiTheme.size.xs,
      ' 0 ',
      euiTheme.colors.textPrimary,
      ';color:',
      euiTheme.colors.textPrimary,
      ';;label:active;'
    )
  };
};
