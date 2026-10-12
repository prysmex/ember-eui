/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Hand port of EUI 123.1.0 `components/flyout/flyout_menu/flyout_menu.styles.js`.
 *
 * The upstream module imports `euiScreenReaderOnly` from the React
 * `components/accessibility` barrel, so the generator cannot extract it.
 * This port composes the same pure helpers (extracted into
 * `styles.generated.ts`) in the same order, and the parity suite
 * (`scripts/eui-upstream-parity.test.mjs`) compares every slot with the
 * upstream module in every color/contrast mode.
 */
import { mathWithUnits } from '@elastic/eui-theme-common';
import { serializeStyles } from '@emotion/serialize';

import {
  euiScreenReaderOnly,
  highContrastModeStyles,
  logicalCSS
} from './styles.generated.ts';

import type { EuiBorealisContext } from './theme.ts';
import type { SerializedStyles } from '@emotion/serialize';

// Same serialization the generator substitutes for Emotion's `css`.
const css = (...args: unknown[]) =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

// Upstream ships these static slots pre-serialized (Babel's Emotion plugin).
const actions = {
  name: '1kqtial-euiFlyoutMenu__actions',
  styles: 'align-self:center;label:euiFlyoutMenu__actions;'
} as SerializedStyles;
const controls = {
  name: '2o24qf-euiFlyoutMenu__controls',
  styles: 'block-size:100%;label:euiFlyoutMenu__controls;'
} as SerializedStyles;

export const euiFlyoutMenuStyles = (euiThemeContext: EuiBorealisContext) => {
  const euiTheme = euiThemeContext.euiTheme;
  const topOffset = mathWithUnits(
    [euiTheme.size.m, euiTheme.border.width.thin],
    (x: number, y: number) => x + y
  );
  const containerHeight = mathWithUnits(
    [euiTheme.size.base, euiTheme.border.width.thin],
    (x: number, y: number) => x * 3 + y * 2
  );

  return {
    euiFlyoutMenu__container: css(
      'block-size:',
      containerHeight,
      ';flex-shrink:0;padding-block:',
      euiTheme.size.s,
      ';padding-inline:',
      euiTheme.size.s,
      ';border-block-end:',
      euiTheme.border.width.thin,
      ' solid ',
      euiTheme.border.color,
      ';.euiFlyout__closeButton{',
      logicalCSS('top', topOffset),
      ';}.euiTitle{padding-inline:',
      euiTheme.size.s,
      ';};label:euiFlyoutMenu__container;'
    ),
    // Full height in high contrast mode so dividers can bleed to the container edges.
    euiFlyoutMenu__controls: controls,
    euiFlyoutMenu__spacer: css(
      'padding-inline:',
      euiTheme.size.m,
      ';;label:euiFlyoutMenu__spacer;'
    ),
    euiFlyoutMenu__actions: actions,
    euiFlyoutMenu__hiddenTitle: css(
      euiScreenReaderOnly(),
      ';;label:euiFlyoutMenu__hiddenTitle;'
    ),
    euiFlyoutMenu__paginationCounter: css(
      'color:',
      euiTheme.colors.textSubdued,
      ';white-space:nowrap;;label:euiFlyoutMenu__paginationCounter;'
    ),
    // Border (not background) keeps the line visible in Windows high contrast themes.
    euiFlyoutMenu__divider: css(
      'align-self:center;inline-size:0;block-size:',
      euiTheme.size.l,
      ';margin-inline:',
      euiTheme.size.s,
      ';border-inline-start:',
      euiTheme.border.thin,
      ';pointer-events:none;',
      highContrastModeStyles(euiThemeContext, {
        preferred: `
          align-self: stretch;
          block-size: auto;
          margin-block: -${euiTheme.size.s};
        `
      }),
      ';;label:euiFlyoutMenu__divider;'
    )
  };
};
