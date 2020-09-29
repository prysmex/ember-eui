export const baseClass: string = 'euiPanel';

export const paddingMapping = {
  none: ``,
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    padding: paddingMapping
  }
};

export default mapping;
