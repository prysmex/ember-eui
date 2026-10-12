/*
 * Ember glue for the page layout family, following @elastic/eui 123.1.0
 * `components/page/*`, `components/page_template/*` and
 * `components/bottom_bar/*`, and the `euiScreenReaderOnly` mixin
 * (`components/accessibility/screen_reader_only/screen_reader_only.styles.js`)
 * and `useEuiPaddingCSS` (`global_styling/mixins/_padding.js`).
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 * Upstream factories are extracted into styles.generated.ts; this file only
 * holds what upstream does inside React components or hooks.
 */
import {
  euiBreakpoint,
  euiPaddingSize,
  setStyleForRestrictedPageWidth
} from './styles.generated.ts';

import type { CSSObject } from '@emotion/css/create-instance';
import type { EuiBorealisContext } from './theme.ts';

export type EuiPagePaddingSize = 'none' | 'xs' | 's' | 'm' | 'l' | 'xl';
export type EuiPageBreakpoint = 'xs' | 's' | 'm' | 'l' | 'xl';
export type EuiPageRestrictWidth = boolean | number | string;

/**
 * Upstream `euiScreenReaderOnly` mixin. EuiScreenReaderOnly is not
 * migrated, so its vendor class has no styles without legacy CSS.
 */
export const euiScreenReaderOnlyCss: CSSObject = {
  position: 'absolute',
  insetBlockStart: 'auto',
  insetInlineStart: '-10000px',
  inlineSize: '1px',
  blockSize: '1px',
  clip: 'rect(0 0 0 0)',
  clipPath: 'inset(50%)',
  overflow: 'hidden',
  margin: '-1px'
};

/** Stands in for React EUI's global `box-sizing` reset. */
export const euiPageBoxSizing: CSSObject = { boxSizing: 'border-box' };

const PADDING_SIDES = {
  all: 'padding',
  horizontal: 'paddingInline',
  vertical: 'paddingBlock',
  top: 'paddingBlockStart',
  bottom: 'paddingBlockEnd'
} as const;

/** `useEuiPaddingCSS(side)[size]` without the hook. */
export function euiPagePadding(
  context: EuiBorealisContext,
  size: EuiPagePaddingSize | undefined,
  side: keyof typeof PADDING_SIDES = 'all'
): CSSObject | undefined {
  const value = size ? euiPaddingSize(context, size) : undefined;
  return value ? { [PADDING_SIDES[side]]: value } : undefined;
}

/**
 * Upstream `setStyleForRestrictedPageWidth`: `true` is upstream's
 * `PAGE_MAX_WIDTH` (1200px); numbers are pixels (React adds the unit).
 */
export function euiPageRestrictWidthStyle(
  restrictWidth: EuiPageRestrictWidth | undefined,
  style?: Record<string, unknown>
): Record<string, string> {
  const width =
    typeof restrictWidth === 'number' ? `${restrictWidth}px` : restrictWidth;
  return setStyleForRestrictedPageWidth(width ?? false, style ?? {});
}

/** Whether `restrictWidth` centers the element (anything but `false`/unset). */
export function isRestricted(restrictWidth: EuiPageRestrictWidth | undefined) {
  return restrictWidth !== undefined && restrictWidth !== false;
}

function orderedBreakpoints(context: EuiBorealisContext): EuiPageBreakpoint[] {
  const breakpoints = context.euiTheme.breakpoint as Record<string, number>;
  return (Object.keys(breakpoints) as EuiPageBreakpoint[]).sort(
    (a, b) => breakpoints[a]! - breakpoints[b]!
  );
}

/**
 * A media query matching exactly the given theme breakpoints, like
 * upstream's `useIsWithinBreakpoints(sizes)` but evaluated by CSS. Upstream
 * `euiBreakpoint` covers one contiguous range, so non-contiguous sizes
 * are joined as a media query list. `undefined` when `sizes` is empty.
 */
export function euiBreakpointsMedia(
  context: EuiBorealisContext,
  sizes: readonly EuiPageBreakpoint[]
): string | undefined {
  const order = orderedBreakpoints(context);
  const wanted = order.filter((size) => sizes.includes(size));
  if (!wanted.length) return undefined;
  const runs: EuiPageBreakpoint[][] = [];
  for (const size of wanted) {
    const run = runs[runs.length - 1];
    const previous = run?.[run.length - 1];
    if (run && previous && order.indexOf(previous) === order.indexOf(size) - 1)
      run.push(size);
    else runs.push([size]);
  }
  const queries = runs.map((run) =>
    // Upstream sorts its argument in place; pass a copy.
    (euiBreakpoint(context, [...run]) as string).replace(/^@media /, '')
  );
  return `@media ${queries.join(', ')}`;
}

/** The complementary query: every theme breakpoint not in `sizes`. */
export function euiOutsideBreakpointsMedia(
  context: EuiBorealisContext,
  sizes: readonly EuiPageBreakpoint[]
): string | undefined {
  return euiBreakpointsMedia(
    context,
    orderedBreakpoints(context).filter((size) => !sizes.includes(size))
  );
}

/**
 * Upstream composes a parent's `css` after the child's own styles in one
 * Emotion class. Ember applies the parent's styles as a second class on the
 * child's root, so doubling the class selector restores upstream's order.
 */
export function composedOver(...styles: unknown[]): CSSObject {
  return { '&&': styles as CSSObject[] } as unknown as CSSObject;
}
