export const baseClass = 'euiBottomBar';

const paddingSizeMapping = {
  none: '',
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`
};

const positionTypeMapping = {
  fixed: `${baseClass}--fixed`,
  sticky: `${baseClass}--sticky`,
  static: `${baseClass}--static`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    paddingSize: paddingSizeMapping,
    positionType: positionTypeMapping
  }
};

export default mapping;
