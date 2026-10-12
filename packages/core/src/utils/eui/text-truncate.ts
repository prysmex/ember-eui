/*
 * Ported from @elastic/eui 123.1.0 `components/text_truncate/text_block_truncate.js`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 * Parity with upstream is checked in scripts/eui-upstream-parity.test.mjs.
 *
 * Upstream keeps these styles as a module-local object inside the React
 * component file (which imports React and `cloneElementWithCss`), so the
 * generator cannot extract them. This is the same precompiled serialized
 * style; the line count is set inline (`-webkit-line-clamp`) by the
 * component, like upstream.
 */
import type { SerializedStyles } from '@emotion/serialize';

export const euiTextBlockTruncateStyles: {
  euiTextBlockTruncate: SerializedStyles;
} = {
  euiTextBlockTruncate: {
    name: '1cfm3ge-euiTextBlockTruncate',
    styles:
      'display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:0;overflow:hidden;label:euiTextBlockTruncate;'
  }
};
