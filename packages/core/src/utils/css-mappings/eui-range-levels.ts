import {
  calculateOffset,
  calculateThumbPosition} from '../../helpers/get-range-tick';

export const baseClass = 'euiRangeLevels';

export function inlineStyles({
  min,
  max,
  level,
  trackWidth
}: {
  min: number;
  max: number;
  level: { min: number; max: number };
  trackWidth: number;
}): Record<string, unknown> {
  const left =
    level.min === min
      ? 0
      : calculateThumbPosition(level.min, min, max, trackWidth);
  const right =
    level.max === max
      ? 100
      : calculateThumbPosition(level.max, min, max, trackWidth);
  const leftOffset = calculateOffset(left, level.min, min);
  const rightOffset = calculateOffset(right, level.max, max);

  return {
    left: `calc(${left}% + ${leftOffset}px)`,
    right: `calc(${100 - right}% - ${rightOffset}px)`
  };
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {},
  inlineStyles
};

export default mapping;
