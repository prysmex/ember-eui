/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Hand port of EUI 123.1.0 `euiTableStickyCellStyles`
 * (`components/table/table_cells_shared.styles.js`).
 *
 * Upstream keeps the factory module-local and only exports it through the
 * `_useEuiTableStickyCellStyles` hook, so the generator cannot extract it.
 * This port composes the same pieces in the same order; the parity suite
 * (`scripts/eui-upstream-parity.test.mjs`) compares it with the hook's
 * output in every color/contrast mode.
 */
import { serializeStyles } from '@emotion/serialize';

import {
  EUI_TABLE_CSS_CONTAINER_NAME,
  euiContainerQuery
} from './styles.generated.ts';

import type { SerializedStyles } from '@emotion/serialize';
import type { EuiBorealisContext } from './theme.ts';

// Same serialization the generator substitutes for Emotion's `css`.
const css = (...args: unknown[]) =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

/** The side a sticky cell sticks to (upstream `EuiTableStickyCellOptions`). */
export interface EuiTableStickyCellOptions {
  /** `start` is the left side in horizontal writing modes, `end` the right side. */
  side: 'start' | 'end';
}

// Precompiled by upstream's Babel plugin (static styles).
const SIDES: Record<'start' | 'end', SerializedStyles> = {
  start: { name: '1u5b4oq-start', styles: 'inset-inline-start:0;label:start;' },
  end: { name: '10im1kr-end', styles: 'inset-inline-end:0;label:end;' }
};

export const euiTableStickyCellStyles = ({ euiTheme }: EuiBorealisContext) => ({
  root: css(
    'position:sticky;background-color:var(\n        --euiTableCellStickyBackgroundColor,\n        ',
    euiTheme.colors.backgroundBasePlain,
    '\n      );',
    euiContainerQuery(
      'scroll-state(scrollable: right)',
      EUI_TABLE_CSS_CONTAINER_NAME
    ),
    "{&::before{content:'';position:absolute;inset-inline-start:0;inset-block:0;inline-size:",
    euiTheme.border.width.thin,
    ';background-color:',
    euiTheme.border.color,
    ';}};label:root;'
  ),
  side: SIDES
});
