export const baseClass = 'euiPopoverFooter';

export const paddingMapping = {
  none: `${baseClass}--paddingNone`,
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    paddingSize: paddingMapping
  }
};

export default mapping;
