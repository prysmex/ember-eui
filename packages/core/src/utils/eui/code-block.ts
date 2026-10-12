/*
 * Ported from @elastic/eui 123.1.0 `components/code/code_block_line.styles.js`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 * Parity with upstream is checked in scripts/eui-upstream-parity.test.mjs.
 *
 * Why this is a hand port: upstream uses `css` from `@emotion/css` (class
 * names registered in Emotion's global cache, applied to highlighted DOM
 * nodes) instead of `@emotion/react`. The body below is upstream's with the
 * same call shapes, serialized instead of registered, so the styles (and so
 * the hashes) are identical; components register them in the provider cache.
 */
import { serializeStyles } from '@emotion/serialize';

import { mathWithUnits } from './styles.generated.ts';

import type { SerializedStyles } from '@emotion/serialize';
import type { EuiBorealisContext } from './theme.ts';

const css = (...args: unknown[]): SerializedStyles =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

const math = mathWithUnits as (
  values: unknown,
  callback: (...values: number[]) => number
) => string;

/** Upstream `euiCodeBlockLineStyles`. */
export function euiCodeBlockLineStyles(euiThemeContext: EuiBorealisContext) {
  const { euiTheme, highContrastMode } = euiThemeContext;
  const lineMargins = euiTheme.size.m;
  const lineWidth = euiTheme.border.width.thin;
  // Increase highlight border width in high contrast modes
  const highlightWidth = highContrastMode
    ? math(euiTheme.border.width.thick, (x) => x * 1.5)
    : euiTheme.border.width.thick;
  const highlightOffset = math(
    [lineMargins, lineWidth, highlightWidth],
    (x, y, z) => x! + y! - z!
  );
  return {
    euiCodeBlock__line: css({
      name: 'yn676d-euiCodeBlock__line',
      styles: 'display:block;label:euiCodeBlock__line;'
    }),
    hasLineNumbers: css({
      name: '156gjef-hasLineNumbers',
      styles: 'display:flex;user-select:none;label:hasLineNumbers;'
    }),
    lineText: {
      euiCodeBlock__lineText: css(
        'flex-grow:1;display:inline-block;padding-inline-start:',
        lineMargins,
        ';border-inline-start:',
        lineWidth,
        ' solid ',
        euiTheme.border.color,
        ';user-select:text;;label:euiCodeBlock__lineText;'
      ),
      isHighlighted: css(
        'background:',
        euiTheme.colors.backgroundBasePrimary,
        ';border-inline-start:',
        highlightWidth,
        ' solid ',
        euiTheme.colors.primary,
        ';padding-inline-start:',
        highlightOffset,
        ';;label:isHighlighted;'
      )
    },
    lineNumber: {
      euiCodeBlock__lineNumberWrapper: css(
        'position:relative;flex-grow:0;flex-shrink:0;user-select:none;padding-inline-end:',
        lineMargins,
        ';box-sizing:content-box;;label:euiCodeBlock__lineNumberWrapper;'
      ),
      euiCodeBlock__lineNumber: css(
        'color:',
        euiTheme.colors.textSubdued,
        ';text-align:end;display:block;&::before{content:attr(data-line-number);};label:euiCodeBlock__lineNumber;'
      )
    }
  };
}

