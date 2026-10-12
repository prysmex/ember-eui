/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Hand ports of EUI 123.1.0 data grid styles the generator cannot extract:
 *
 * - `components/datagrid/controls/fullscreen_selector.styles.js` builds its
 *   classes with vanilla `@emotion/css` (global class names);
 * - `components/datagrid/controls/data_grid_toolbar_control.js` and
 *   `display_selector.js` declare their styles inline next to React hooks.
 *
 * The ports compose the same pure helpers (extracted into
 * `styles.generated.ts`) in the same order; the parity suite
 * (`scripts/eui-upstream-parity.test.mjs`) compares them with upstream.
 */
import { mathWithUnits } from '@elastic/eui-theme-common';
import { serializeStyles } from '@emotion/serialize';

import { logicalCSS } from './styles.generated.ts';

import type { EuiBorealisContext } from './theme.ts';
import type { SerializedStyles } from '@emotion/serialize';

// Same serialization the generator substitutes for Emotion's `css`.
const css = (...args: unknown[]) =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

/** `fullscreen_selector.styles.js` */
export const euiDataGridFullScreenStyles = (
  euiThemeContext: EuiBorealisContext
): {
  'euiDataGrid--fullScreen': SerializedStyles;
  euiDataGrid__restrictBody: SerializedStyles;
} => {
  const { euiTheme } = euiThemeContext;
  const fullScreenZIndex = Number(euiTheme.levels.header) - 2;
  return {
    'euiDataGrid--fullScreen': css(
      'z-index:',
      fullScreenZIndex,
      ';position:fixed;inset:0;background-color:',
      euiTheme.colors.emptyShade,
      ';;label:euiDataGrid--fullScreen;'
    ),
    euiDataGrid__restrictBody: css(
      logicalCSS('height', '100vh'),
      ' overflow:hidden;.euiHeader[data-fixed-header]{z-index:',
      fullScreenZIndex - 1,
      "!important;}.euiOverlayMask[data-relative-to-header='below']{",
      logicalCSS('top', '0'),
      ';}.euiFlyout{',
      logicalCSS('top', '0'),
      ' ',
      logicalCSS('height', '100%'),
      ';};label:euiDataGrid__restrictBody;'
    )
  };
};

/** `data_grid_toolbar_control.js` `interactiveStyles` and `badgeStyles`. */
export const euiDataGridToolbarControlStyles = ({
  euiTheme
}: EuiBorealisContext): {
  interactive: SerializedStyles;
  badge: SerializedStyles;
} => ({
  interactive: css(
    '&:focus,&:hover:not(:disabled){.euiDataGridToolbarControl__badge{background-color:',
    euiTheme.components.filterButtonBadgeBackgroundHover,
    ';}};label:interactiveStyles;'
  ),
  badge: {
    name: '1968nw3-badgeStyles',
    styles: 'cursor:inherit;label:badgeStyles;'
  } as SerializedStyles
});

/** `display_selector.js`: the row height button group's flex basis. */
export const euiDataGridRowHeightControlStyles = {
  name: 'ueqtrq-RowHeightControl',
  styles: 'flex-shrink:0;flex-basis:66.6%;label:RowHeightControl;'
} as SerializedStyles;

/**
 * `display_selector.js`: the display popover panel is the form max width
 * (`euiFormMaxWidth`) plus the `s` panel padding on both sides.
 */
export const euiDataGridDisplayPopoverWidth = ({
  euiTheme
}: EuiBorealisContext): string =>
  mathWithUnits(
    [euiTheme.components.forms.maxWidth, euiTheme.size.s],
    (x: number, y: number) => x + y * 2
  );
