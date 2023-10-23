export const baseClass = 'euiPageContentBody';

export const paddingSizeMapping = {
  none: '',
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    paddingSize: paddingSizeMapping
  }
};

export default mapping;
