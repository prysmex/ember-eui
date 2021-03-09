export const baseClass = 'euiRangeLevels';

export function inlineStyles({
  min,
  max,
  level
}: {
  min: number;
  max: number;
  level: { min: number; max: number };
}): Record<string, unknown> {
  const range = level.max - level.min;
  const width = (range / (max - min)) * 100;
  return { width: `${width}%` };
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {},
  inlineStyles
};

export default mapping;
