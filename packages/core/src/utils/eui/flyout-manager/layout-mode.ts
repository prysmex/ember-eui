/*
 * Ported from @elastic/eui 123.1.0 `components/flyout/manager/layout_mode.ts`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 *
 * The `useMemo` body of upstream's `useApplyFlyoutLayoutMode` as a pure
 * function; the `eui-flyout-manager` service tracks the reference width and
 * applies the result (upstream's effects).
 */
import { LAYOUT_MODE_SIDE_BY_SIDE, LAYOUT_MODE_STACKED } from './const.ts';

import type { EuiFlyoutLayoutMode, EuiFlyoutManagerState } from './types.ts';

/** Thresholds to prevent thrashing near the breakpoint. */
const THRESHOLD_TO_SIDE_BY_SIDE = 85;
const THRESHOLD_TO_STACKED = 95;

/**
 * Convert a flyout `size` value to a pixel width.
 * When `referenceWidth` is provided, named sizes are calculated as a percentage
 * of that width (container-relative). Otherwise falls back to `window.innerWidth`.
 */
export const getWidthFromSize = (
  size: string | number,
  referenceWidth?: number
): number => {
  if (typeof size === 'number') {
    return size;
  }

  if (typeof size === 'string') {
    const parsed = parseInt(size, 10);

    if (!Number.isNaN(parsed)) {
      return parsed;
    }

    const refWidth =
      referenceWidth ?? (typeof window !== 'undefined' ? window.innerWidth : 0);

    // Size is a function of a percentage of the reference width,
    // matching the proportions defined in `composeFlyoutSizing`
    switch (size) {
      case 's':
        return Math.round(refWidth * 0.25);
      case 'm':
        return Math.round(refWidth * 0.5);
      case 'l':
        return Math.round(refWidth * 0.75);
      case 'fill':
        return Math.round(refWidth * 0.9);
      default:
        break;
    }
  }
  return 0;
};

/**
 * The layout mode the current session needs (`null` when no flyout is open):
 * stacked below `breakpointS * 1.4`, otherwise side-by-side unless the main
 * and child flyouts together take 95% of the reference width (and back to
 * side-by-side under 85%).
 */
export const getDesiredLayoutMode = (
  state: EuiFlyoutManagerState | null | undefined,
  referenceWidth: number,
  breakpointS: number
): EuiFlyoutLayoutMode | null => {
  const sessions = state?.sessions;
  const currentSession = sessions
    ? (sessions[sessions.length - 1] ?? null)
    : null;
  const parentFlyoutId = currentSession?.mainFlyoutId;
  const childFlyoutId = currentSession?.childFlyoutId;

  const parentFlyout = parentFlyoutId
    ? (state?.flyouts.find((f) => f.flyoutId === parentFlyoutId) ?? null)
    : null;
  const childFlyout = childFlyoutId
    ? (state?.flyouts.find((f) => f.flyoutId === childFlyoutId) ?? null)
    : null;

  const parentWidth = parentFlyout?.width;
  const childWidth = childFlyout?.width;
  const currentLayoutMode = state?.layoutMode;

  // Skip calculation if no flyouts open
  if (!parentFlyoutId) {
    return null;
  }

  // If the reference width is too small, set the mode to stacked.
  //
  // The value is based on the maximum width of a flyout in
  // `composeFlyoutSizing` in `flyout.styles.ts` multiplied
  // by 2 (open flyouts side-by-side).
  if (referenceWidth < Math.round(breakpointS * 1.4)) {
    return LAYOUT_MODE_STACKED;
  }

  if (!childFlyoutId) {
    return LAYOUT_MODE_SIDE_BY_SIDE;
  }

  const isFillParent = parentFlyout?.size === 'fill';
  const isFillChild = childFlyout?.size === 'fill';
  const hasFill = isFillParent || isFillChild;

  let parentWidthValue = parentWidth;
  let childWidthValue = childWidth;

  // Resolve unmeasured widths. For fill-size flyouts, estimate as
  // (90% of referenceWidth − sibling width) rather than a flat 90%.
  if (!parentWidthValue && parentFlyout?.size) {
    if (isFillParent && childWidthValue) {
      parentWidthValue = Math.max(
        0,
        Math.round(referenceWidth * 0.9 - childWidthValue)
      );
    } else {
      parentWidthValue = getWidthFromSize(parentFlyout.size, referenceWidth);
    }
  }

  if (!childWidthValue && childFlyout?.size) {
    if (isFillChild && parentWidthValue) {
      childWidthValue = Math.max(
        0,
        Math.round(referenceWidth * 0.9 - parentWidthValue)
      );
    } else {
      childWidthValue = getWidthFromSize(childFlyout.size, referenceWidth);
    }
  }

  if (!parentWidthValue || !childWidthValue) {
    return LAYOUT_MODE_SIDE_BY_SIDE;
  }

  const combinedWidth = parentWidthValue + childWidthValue;
  const combinedWidthPercentage = (combinedWidth / referenceWidth) * 100;

  // Fill flyouts defeat the hysteresis thresholds, so use the
  // reference-width breakpoint alone to decide the layout mode.
  if (hasFill) {
    return referenceWidth >= Math.round(breakpointS * 1.4)
      ? LAYOUT_MODE_SIDE_BY_SIDE
      : LAYOUT_MODE_STACKED;
  }

  if (currentLayoutMode === LAYOUT_MODE_STACKED) {
    return combinedWidthPercentage <= THRESHOLD_TO_SIDE_BY_SIDE
      ? LAYOUT_MODE_SIDE_BY_SIDE
      : LAYOUT_MODE_STACKED;
  } else {
    return combinedWidthPercentage >= THRESHOLD_TO_STACKED
      ? LAYOUT_MODE_STACKED
      : LAYOUT_MODE_SIDE_BY_SIDE;
  }
};
