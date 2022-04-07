export const baseClass = 'euiPageBody';

export const paddingSizeMapping = {
  none: '',
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`
};

export const borderRadiusMapping = {
  none: `${baseClass}--borderRadiusNone`,
  s: `${baseClass}--borderRadiusSmall`,
  m: `${baseClass}--borderRadiusMedium`,
  l: `${baseClass}--borderRadiusLarge`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    borderRadiusSize: borderRadiusMapping,
    paddingSize: paddingSizeMapping
  }
};

export default mapping;
