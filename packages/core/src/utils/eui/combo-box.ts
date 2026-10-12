/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Pieces of the EUI 123.1.0 combo box that the generator cannot extract.
 *
 * `euiSelectableListGroupLabelStyles` (the combo box group label, from
 * `components/selectable/selectable_list/selectable_list.styles.js`): the
 * upstream module also imports `@emotion/css` (a DOM-backed Emotion
 * instance) for another slot, so extracting it would bundle a second Emotion
 * runtime. This port composes the same pure helpers in the same order; the
 * parity suite (`scripts/eui-upstream-parity.test.mjs`) compares it with the
 * upstream module in every color/contrast mode.
 */
import { mathWithUnits } from '@elastic/eui-theme-common';
import { serializeStyles } from '@emotion/serialize';

import {
  euiFontSize,
  euiListItemVariables,
  logicalCSS
} from './styles.generated.ts';

import type { EuiBorealisContext } from './theme.ts';
import type { CSSObject } from '@emotion/css/create-instance';

// Same serialization the generator substitutes for Emotion's `css`.
const css = (...args: unknown[]) =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

/** Upstream `euiTitle(euiThemeContext, 'xxxs')` (`title.styles.js`). */
const euiTitleXxxs = (euiThemeContext: EuiBorealisContext) => {
  const euiTheme = euiThemeContext.euiTheme;
  return {
    ...euiFontSize(euiThemeContext, 'xs', undefined),
    fontWeight: euiTheme.font.weight[euiTheme.font.title.weight],
    color: euiTheme.colors.textHeading,
    letterSpacing: euiTheme.font.title.letterSpacing
  };
};

export const euiSelectableListGroupLabelStyles = (
  euiThemeContext: EuiBorealisContext
) => {
  const euiTheme = euiThemeContext.euiTheme;
  const itemVars = euiListItemVariables(euiThemeContext);
  const spacingVertical = euiTheme.size.s;
  const borderColor = euiTheme.components.selectableListItemBorderColor;
  return {
    groupLabel: css(
      euiTitleXxxs(euiThemeContext),
      ' position:relative;display:flex;align-items:center;gap:',
      itemVars.spacing.horizontal,
      ';',
      logicalCSS('padding-horizontal', itemVars.textPadding.horizontal),
      ' ',
      logicalCSS('padding-vertical', spacingVertical),
      ' &:not(:first-child){',
      logicalCSS(
        'padding-top',
        mathWithUnits([spacingVertical], (a: number) => a * 3)
      ),
      " &::before{content:'';position:absolute;z-index:-1;inset:0;inset-block-start:",
      spacingVertical,
      ';',
      logicalCSS(
        'border-top',
        `${String(euiTheme.border.width.thin)} solid ${borderColor}`
      ),
      ';}};label:groupLabel;'
    )
  };
};

/**
 * Ember has no React global reset: box sizing for the combo box's own
 * elements (upstream `*` reset) and the list's `button`-free rows.
 */
export const comboBoxBoxReset: CSSObject = {
  boxSizing: 'border-box',
  '& :where(*, *::before, *::after)': { boxSizing: 'border-box' }
};

/** The text of an option: strings as they are, else `label` (or `@searchField`). */
export function comboBoxOptionLabel(option: unknown, searchField?: string): string {
  if (typeof option === 'string') return option;
  if (typeof option === 'number') return String(option);
  if (option && typeof option === 'object') {
    const record = option as Record<string, unknown>;
    const value = record[searchField ?? 'label'] ?? record['label'];

    if (typeof value === 'string' || typeof value === 'number') {
      return String(value);
    }
  }

  return '';
}
