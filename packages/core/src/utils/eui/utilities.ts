/*
 * Ported from @elastic/eui 123.1.0 `components/mark/mark.styles.js` and
 * `components/overlay_mask/overlay_mask.styles.js`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 * Parity with upstream is checked in scripts/eui-upstream-parity.test.mjs.
 *
 * Why these are hand ports: `mark.styles.js` imports `euiScreenReaderOnly`
 * through the React `components/accessibility` barrel, and
 * `overlay_mask.styles.js` uses `@emotion/css` (class names in Emotion's
 * global cache) instead of `@emotion/react`. The bodies below are upstream's,
 * with the same call shapes, so serialization (and so hashes) is identical.
 */
import { serializeStyles } from '@emotion/serialize';
import {
  euiAnimFadeIn,
  euiScreenReaderOnly,
  highContrastModeStyles,
  logicalCSS
} from './styles.generated.ts';

import type { SerializedStyles } from '@emotion/serialize';
import type { EuiBorealisContext } from './theme.ts';

const css = (...args: unknown[]): SerializedStyles =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);

const highContrast = highContrastModeStyles as (
  context: EuiBorealisContext,
  modes: { none?: string; preferred?: string; forced?: string }
) => string;
const logical = logicalCSS as (property: string, value: unknown) => string;
const srOnly = euiScreenReaderOnly as () => string;

/** Upstream `euiMarkStyles`. */
export function euiMarkStyles(euiThemeContext: EuiBorealisContext) {
  const euiTheme = euiThemeContext.euiTheme;
  return {
    euiMark: css(
      highContrast(euiThemeContext, {
        none: '\n          color: '
          .concat(euiTheme.colors.textParagraph, ';\n          background-color: ')
          .concat(euiTheme.components.markBackground, ';\n        '),
        preferred: '\n          color: '
          .concat(euiTheme.colors.emptyShade, ' !important;\n          background-color: ')
          .concat(euiTheme.colors.backgroundFilledPrimary, ';\n        ')
      }),
      ' font-weight:',
      euiTheme.font.weight.bold,
      ';;label:euiMark;'
    )
  };
}

/** Upstream `euiMarkScreenReaderStyles`: announces where a highlight starts and ends. */
export function euiMarkScreenReaderStyles(
  highlightStart: string,
  highlightEnd: string
) {
  return {
    hasScreenReaderHelpText: css(
      '&::before,&::after{',
      srOnly(),
      ";}&::before{content:' [",
      highlightStart,
      "] ';}&::after{content:' [",
      highlightEnd,
      "] ';};label:hasScreenReaderHelpText;"
    )
  };
}

/** Upstream `euiOverlayMaskStyles`, serialized instead of registered in Emotion's global cache. */
export function euiOverlayMaskStyles(euiThemeContext: EuiBorealisContext) {
  const { euiTheme, highContrastMode } = euiThemeContext;
  return {
    euiOverlayMask: css(
      'position:fixed;',
      logical('top', 0),
      ' ',
      logical('left', 0),
      ' ',
      logical('right', 0),
      ' ',
      logical('bottom', 0),
      ' display:flex;align-items:center;justify-content:center;animation:',
      euiAnimFadeIn,
      ' ',
      euiTheme.animation.fast,
      ' ease-in forwards;animation-iteration-count:1;background:',
      highContrastMode
        ? euiTheme.components.overlayMaskBackgroundHighContrast
        : euiTheme.components.overlayMaskBackground,
      ';;label:euiOverlayMask;'
    ),
    aboveHeader: css('z-index:', euiTheme.levels.mask, ';;label:aboveHeader;'),
    belowHeader: css(
      'z-index:',
      euiTheme.levels.maskBelowHeader,
      ';',
      logical('top', 'var(--euiFixedHeadersOffset, 0)'),
      ';;label:belowHeader;'
    ),
    noAnimation: css({
      name: 'lqr4xc-noAnimation',
      styles: 'animation:none;label:noAnimation;'
    })
  };
}

