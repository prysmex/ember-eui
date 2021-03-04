export const baseClass: string = 'euiRangeInput';

export function inlineStyles({
  autoSize = true,
  digitTolerance,
}: {
  autoSize: boolean;
  digitTolerance: number;
}): Record<string, unknown> {
  return autoSize ? { width: `${digitTolerance / 1.25 + 2}em` } : {};
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {},
  inlineStyles,
};

export default mapping;
