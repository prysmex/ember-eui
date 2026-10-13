/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Small pieces of the EUI 123.1.0 range family that live inside React
 * component modules (positions, offsets, tick label shifts, aria value text),
 * ported by hand. The styles themselves come from `styles.generated.ts`.
 */
import { htmlSafe } from '@ember/template';

import type { SafeString } from '@ember/template';

/** `range/utils.js` `EUI_THUMB_SIZE`. */
export const EUI_THUMB_SIZE = 16;

/**
 * `range/utils.js` `calculateThumbPosition`: the thumb's start position in %
 * of the track, compensated for the thumb width. Unlike upstream, an
 * unmeasured track (width 0) returns the plain percentage instead of `NaN`.
 */
export function calculateThumbPosition(
  value: number,
  min: number,
  max: number,
  trackWidth: number,
  thumbSize = EUI_THUMB_SIZE
): number {
  const decimal = (value - min) / (max - min);
  let valuePosition = decimal <= 1 ? decimal : 1;
  valuePosition = valuePosition >= 0 ? valuePosition : 0;
  if (!(trackWidth > 0)) return valuePosition * 100;
  const thumbToTrackRatio = thumbSize / trackWidth;
  const trackPositionScale = (1 - thumbToTrackRatio) * 100;
  return valuePosition * trackPositionScale;
}

/** `range_levels.js` `calculateOffset` (estimated by eye upstream). */
export function calculateLevelOffset(
  position: number,
  value: number,
  bound: number
): number {
  const threshold = 30;
  let offset = value === bound ? 0 : EUI_THUMB_SIZE / 2;
  if (offset !== 0) {
    offset =
      position <= threshold ? offset + (1 / position) * threshold : offset;
    offset =
      position >= 100 - threshold
        ? offset - (1 / (100 - position)) * threshold
        : offset;
  }
  return offset;
}

/** `range_levels.js` level element position (left/right) for a track width. */
export function levelPosition(
  level: { min: number; max: number },
  min: number,
  max: number,
  trackWidth: number
): { left: string; right: string } {
  let left = 0;
  let right = 0;
  let leftOffset = 0;
  let rightOffset = 0;
  if (trackWidth > 0) {
    left =
      level.min === min
        ? 0
        : calculateThumbPosition(level.min, min, max, trackWidth);
    leftOffset = calculateLevelOffset(left, level.min, min);
    right =
      level.max === max
        ? 100
        : calculateThumbPosition(level.max, min, max, trackWidth);
    rightOffset = calculateLevelOffset(right, level.max, max);
  }
  return {
    left: `calc(${left}% + ${leftOffset}px)`,
    right: `calc(${100 - right}% - ${rightOffset}px)`
  };
}

/**
 * `range_ticks.js`: long min/max labels shift into the track's reserved
 * margin (`em`). Only string labels have a length (numbers don't shift).
 */
export function tickLabelShift(
  label: unknown,
  isMinTick: boolean,
  isMaxTick: boolean
): number {
  const length = (label as { length?: number } | null | undefined)?.length;
  return (isMinTick || isMaxTick) && typeof length === 'number' && length > 3
    ? Math.min(length * 0.25, 1.25)
    : 0;
}

/** `range.js` `handleAriaValueText`: `"value, (label)"` for a matching tick. */
export function rangeAriaValueText(
  ticks: { value: number; label?: unknown; accessibleLabel?: string }[],
  value: string | number | undefined
): string | undefined {
  if (value === undefined || value === null) return undefined;
  const target = ticks.find(
    (tick) => tick.value.toString() === String(value)
  );
  if (!target) return undefined;
  if (target.accessibleLabel)
    return `${target.value}, (${target.accessibleLabel})`;
  return typeof target.label === 'string'
    ? `${target.value}, (${target.label})`
    : undefined;
}

const LOGICAL: Record<string, string> = {
  left: 'inset-inline-start',
  right: 'inset-inline-end',
  marginLeft: 'margin-inline-start',
  marginRight: 'margin-inline-end',
  width: 'inline-size',
  maxWidth: 'max-inline-size',
  minWidth: 'min-inline-size',
  background: 'background',
  backgroundColor: 'background-color'
};

/**
 * Upstream `logicalStyles(...)` for inline styles: physical keys become
 * logical properties, so positions mirror in RTL. Custom properties
 * (`--name`) pass through. Empty values are skipped.
 */
export function logicalStyle(
  styles: Record<string, string | number | undefined | null>
): SafeString | undefined {
  const declarations = Object.entries(styles)
    .filter(([, value]) => value !== undefined && value !== null && value !== '')
    .map(([key, value]) => {
      const property = key.startsWith('--')
        ? key
        : (LOGICAL[key] ?? key.replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`));
      return `${property}: ${value};`;
    });
  return declarations.length ? htmlSafe(declarations.join(' ')) : undefined;
}
