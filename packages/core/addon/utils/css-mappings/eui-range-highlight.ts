export const baseClass = 'euiRangeHighlight';

export function inlineStyles({
  lowerValue,
  upperValue,
  min,
  max,
  background
}: {
  lowerValue: number;
  upperValue: number;
  min: number;
  max: number;
  background?: string;
}): Record<string, unknown> {
  const leftPosition = (lowerValue - min) / (max - min);
  const rangeWidth = (upperValue - lowerValue) / (max - min);
  return {
    background: background,
    'margin-left': `${leftPosition * 100}%`,
    width: `${rangeWidth * 100}%`
  };
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {},
  inlineStyles
};

export default mapping;
