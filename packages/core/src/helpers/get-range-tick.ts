import { helper } from '@ember/component/helper';

import { EUI_THUMB_SIZE } from '../utils/range';

import type { EuiRangeTick } from '../components/eui-range-ticks';

export function calculateOffset(
  position: number,
  value: number,
  bound: number
) {
  const threshold = 30;
  let offset = value === bound ? 0 : EUI_THUMB_SIZE / 2;

  if (offset !== 0) {
    // Estimating offset by eye. Trying to account for range scaling at both ends.
    offset =
      position <= threshold ? offset + (1 / position) * threshold : offset;
    offset =
      position >= 100 - threshold
        ? offset - (1 / (100 - position)) * threshold
        : offset;
  }

  return offset;
}

export function calculateThumbPosition(
  value: number,
  min: number,
  max: number,
  width: number,
  thumbSize: number = EUI_THUMB_SIZE
): number {
  // Calculate the left position based on value
  const decimal = (value - min) / (max - min);
  // Must be between 0-100%
  let valuePosition = decimal <= 1 ? decimal : 1;

  valuePosition = valuePosition >= 0 ? valuePosition : 0;

  const trackWidth = width ?? 0;
  const thumbToTrackRatio = thumbSize / trackWidth;
  const trackPositionScale = (1 - thumbToTrackRatio) * 100;

  return valuePosition * trackPositionScale;
}

export function getRangeTick([
  ticks,
  tickValue,
  min,
  max,
  percentageWidth,
  trackWidth = 0
]: [EuiRangeTick[], number, number, number, number, number]) {
  let tickStyle: string = '';
  let customTick;

  if (ticks) {
    customTick = ticks.find((o) => o.value === tickValue);

    if (customTick) {
      tickStyle = `left: ${((customTick.value - min) / (max - min)) * 100}%;`;
    }
  } else {
    let position = calculateThumbPosition(tickValue, min, max, trackWidth);

    tickStyle = `left: calc(${position}% + ${EUI_THUMB_SIZE / 2}px);`;
    tickStyle += `width: ${percentageWidth}%;`;
  }

  return {
    style: tickStyle,
    customTick,
    label: customTick ? customTick.label : tickValue
  };
}

export default helper(getRangeTick);
