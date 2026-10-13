/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

import dateMath from '@elastic/datemath';
import moment from 'moment';

import { isRelativeToNow } from './index.ts';
import { prettyInterval } from './pretty-interval.ts';

import type EuiI18n from '../../../services/eui-i18n';
import type { ApplyTime, ShortDate } from '../types/global';

export const ZOOM_FACTOR_DEFAULT = 0.5;
export const ZOOM_DELTA_FALLBACK_MS = 500;

/** Upstream `EuiTimeWindowButtonsConfig`. */
export interface EuiTimeWindowButtonsConfig {
  /** Show the "Zoom out" button. Defaults to `true`. */
  showZoomOut?: boolean;
  /** Show the "Zoom in" button. Defaults to `false`. */
  showZoomIn?: boolean;
  /** Show the "Previous" and "Next" buttons. Defaults to `true`. */
  showShiftArrows?: boolean;
  /**
   * How much zooming grows or shrinks the window: a number between 0 and 1
   * (`0.25`) or a percentage string (`'25%'`). Defaults to `0.5`.
   */
  zoomFactor?: number | string;
}

/**
 * Port of upstream `useEuiTimeWindow`: shifts the window by its own
 * duration, or zooms it by `zoomFactor` (split over both ends).
 */
export function useEuiTimeWindow(
  euiI18n: EuiI18n,
  start: ShortDate,
  end: ShortDate,
  apply: ApplyTime,
  options?: { zoomFactor?: EuiTimeWindowButtonsConfig['zoomFactor'] }
) {
  const min = dateMath.parse(start);
  // `roundUp: true` gives an inclusive end (23:59:59.999 for 'now/d')
  const max = dateMath.parse(end, { roundUp: true });
  const isInvalid = !min || !min.isValid() || !max || !max.isValid();
  // An end at .999ms is an inclusive boundary: add 1ms to the duration so
  // steps keep clean boundaries instead of drifting by 1ms.
  const isInclusiveBoundary = !isInvalid && max.milliseconds() === 999;
  const endBoundary = !isInvalid
    ? isInclusiveBoundary
      ? moment(max).add(1, 'ms')
      : moment(max)
    : null;
  const windowDuration =
    isInvalid || !endBoundary ? -1 : endBoundary.diff(min);
  const isWindowDurationZero = windowDuration === 0;
  const zoomFactor = getPercentageMultiplier(
    options?.zoomFactor ?? ZOOM_FACTOR_DEFAULT
  );
  // Added to each end, hence split in half
  const zoomDelta = windowDuration * (zoomFactor / 2);
  const interval = prettyInterval(euiI18n, false, windowDuration);
  let displayInterval = isInvalid ? '' : interval;

  if (
    !isInvalid &&
    !isRelativeToNow(start, end) &&
    !isExactMinuteRange(windowDuration)
  ) {
    displayInterval = `~${displayInterval}`;
  }

  function stepForward() {
    if (isInvalid || isWindowDurationZero) return;
    apply({
      // The exclusive max (+1ms) starts the next window for inclusive ends
      start: (isInclusiveBoundary ? endBoundary! : moment(max)).toISOString(),
      end: moment(max).add(windowDuration, 'ms').toISOString()
    });
  }

  function stepBackward() {
    if (isInvalid || isWindowDurationZero) return;
    apply({
      start: moment(min).subtract(windowDuration, 'ms').toISOString(),
      end: (isInclusiveBoundary
        ? moment(min).subtract(1, 'ms')
        : moment(min)
      ).toISOString()
    });
  }

  function expandWindow() {
    if (isInvalid) return;
    // a zero window stays zero unless it gets a little help
    const addition = zoomDelta === 0 ? ZOOM_DELTA_FALLBACK_MS : zoomDelta;
    apply({
      start: moment(min).subtract(addition, 'ms').toISOString(),
      end: moment(max).add(addition, 'ms').toISOString()
    });
  }

  function shrinkWindow() {
    if (isInvalid || isWindowDurationZero) return;
    apply({
      start: moment(min).add(zoomDelta, 'ms').toISOString(),
      end: moment(max).subtract(zoomDelta, 'ms').toISOString()
    });
  }

  return {
    displayInterval,
    isInvalid,
    stepForward,
    stepBackward,
    expandWindow,
    shrinkWindow,
    isWindowDurationZero
  };
}

/** `'50%'` → 0.5; other strings are parsed as numbers. */
function getPercentageMultiplier(value: number | string) {
  if (typeof value === 'string' && value.includes('%')) {
    const parsed = parseFloat(value.replace('%', '').trim());

    if (isNaN(parsed)) {
      throw new TypeError('Invalid percentage string');
    }

    return parsed / 100;
  }

  const result = typeof value === 'number' ? value : parseFloat(String(value));

  if (isNaN(result)) {
    throw new TypeError(
      'Please provide a valid number or percentage string e.g. "25%"'
    );
  }

  return result;
}

/** Whether to leave out the `~` in the description. */
function isExactMinuteRange(diffMs: number) {
  return diffMs % (60 * 1000) === 0;
}
