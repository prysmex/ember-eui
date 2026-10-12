/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * EuiSuggest styles on Borealis tokens.
 *
 * Upstream removed EuiSuggest in EUI 89.0.0 (#7263, "We recommend using
 * EuiSelectable or EuiComboBox instead"), before it was converted to Emotion,
 * so EUI 123.1.0 has no style factory for it. This is a translation of the
 * last upstream styles (EUI 88.5.4 `components/suggest/_suggest_item.scss`,
 * `_suggest_input.scss`, `_variables.scss`) to the Borealis theme, using the
 * extracted upstream helpers where Sass used mixins:
 *
 * - `$euiFontSizeXS` / `$euiSize` line height → `euiFontSize(xs)` font size
 *   and `size.base` line height; `$euiCodeFontFamily` → `font.familyCode`.
 * - `$euiTextColor` / `$euiTextSubduedColor` → `textParagraph` / `textSubdued`.
 * - `$euiFocusBackgroundColor` (hover/focus of clickable items) → the
 *   Borealis list hover `backgroundBaseInteractiveHover`, as EuiListItemLayout.
 * - Type colors `tint0`–`tint9` → `colors.vis.euiColorVis0`–`9`, `tint10` →
 *   `colors.darkShade`; background `tintOrShade(color, 82%, 70%)` and text
 *   `makeHighContrastColor(color, background)` as in Sass.
 * - `euiTextTruncate` / `euiTextBreakWord` are the upstream JS mixins.
 */
import { serializeStyles } from '@emotion/serialize';

import {
  euiFontSize,
  euiTextBreakWord,
  euiTextTruncate,
  logicalCSS,
  makeHighContrastColor as _makeHighContrastColor,
  shade,
  tint
} from './styles.generated.ts';

import type { SerializedStyles } from '@emotion/serialize';
import type { EuiBorealisContext } from './theme.ts';

// reads its optional ratio from `arguments`, so the inferred type drops it
const makeHighContrastColor = _makeHighContrastColor as (
  foreground: string,
  ratio?: number
) => (background: string) => string;

const css = (...args: unknown[]): SerializedStyles =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

export const SUGGEST_ITEM_TINTS = [
  'tint0',
  'tint1',
  'tint2',
  'tint3',
  'tint4',
  'tint5',
  'tint6',
  'tint7',
  'tint8',
  'tint9',
  'tint10'
] as const;

export type EuiSuggestItemTint = (typeof SUGGEST_ITEM_TINTS)[number];

export const SUGGEST_LABEL_WIDTHS = [
  '20',
  '30',
  '40',
  '50',
  '60',
  '70',
  '80',
  '90'
] as const;

export type EuiSuggestLabelWidth = (typeof SUGGEST_LABEL_WIDTHS)[number];

/** `tintOrShade($color, 82%, 70%)` and its high contrast text color. */
export function suggestTypeColors(
  euiThemeContext: EuiBorealisContext,
  tintName: EuiSuggestItemTint
): { backgroundColor: string; color: string } {
  const { euiTheme, colorMode } = euiThemeContext;
  const vis = euiTheme.colors.vis as unknown as Record<string, string>;
  const base =
    tintName === 'tint10'
      ? euiTheme.colors.darkShade
      : vis[`euiColorVis${tintName.slice(4)}`]!;
  const backgroundColor =
    colorMode === 'DARK' ? shade(base, 0.7) : tint(base, 0.82);
  const color = makeHighContrastColor(base, 4.5)(backgroundColor);
  return { backgroundColor, color };
}

export const euiSuggestItemStyles = (euiThemeContext: EuiBorealisContext) => {
  const { euiTheme } = euiThemeContext;
  const { fontSize } = euiFontSize(euiThemeContext, 'xs', undefined);
  const labelWidths = Object.fromEntries(
    SUGGEST_LABEL_WIDTHS.map((width) => [
      width,
      css(
        `flex-basis:calc(${width}% - ${euiTheme.size.base});`,
        `min-width:calc(${width}% - ${euiTheme.size.base});`,
        `label:width${width};`
      )
    ])
  ) as Record<EuiSuggestLabelWidth, SerializedStyles>;
  const types = Object.fromEntries(
    SUGGEST_ITEM_TINTS.map((name) => {
      const { backgroundColor, color } = suggestTypeColors(
        euiThemeContext,
        name
      );
      return [
        name,
        css(
          `background-color:${backgroundColor};color:${color};label:${name};`
        )
      ];
    })
  ) as Record<EuiSuggestItemTint, SerializedStyles>;
  const textPart = `
    ${euiTextBreakWord()}
    display: inline-block;
    padding: ${euiTheme.size.s};
    flex-grow: 1;
  `;

  return {
    euiSuggestItem: css(
      `display:flex;align-items:flex-start;font-size:${fontSize};`,
      `line-height:${euiTheme.size.base};color:${euiTheme.colors.textParagraph};`,
      'flex:1 1 100%;max-width:100%;label:euiSuggestItem;'
    ),
    truncate: css(
      `.euiSuggestItem__label,.euiSuggestItem__description{${euiTextTruncate()}}`,
      'label:truncate;'
    ),
    // `button.euiSuggestItem` (with `@onClick`)
    isClickable: css(
      logicalCSS('width', '100%'),
      'text-align:start;',
      `&:hover,&:focus{cursor:pointer;background-color:${euiTheme.colors.backgroundBaseInteractiveHover};`,
      '.euiSuggestItem__label{text-decoration:underline;}}',
      'label:isClickable;'
    ),
    euiSuggestItem__type: css(
      'display:flex;flex:0 0 auto;justify-content:center;align-items:flex-start;',
      logicalCSS('padding-top', euiTheme.size.s),
      logicalCSS('width', euiTheme.size.xl),
      logicalCSS('min-height', euiTheme.size.xl),
      'align-self:stretch;label:euiSuggestItem__type;'
    ),
    types,
    euiSuggestItem__label: css(
      textPart,
      `font-family:${euiTheme.font.familyCode};label:euiSuggestItem__label;`
    ),
    labelWidths,
    labelExpand: css('flex-basis:auto;label:expand;'),
    euiSuggestItem__description: css(
      textPart,
      `color:${euiTheme.colors.textSubdued};`,
      logicalCSS('padding-top', `calc(${euiTheme.size.s} + 1px)`),
      'flex-basis:auto;align-self:baseline;label:euiSuggestItem__description;'
    ),
    descriptionWrap: css(
      euiTextBreakWord(),
      'white-space:normal;label:wrap;'
    )
  };
};
