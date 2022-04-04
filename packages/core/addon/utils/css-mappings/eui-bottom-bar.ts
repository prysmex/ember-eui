export const baseClass = 'euiBottomBar';

const paddingSizeMapping = {
  none: '',
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`
};

const positionMapping = {
  none: '',
  fixed: `${baseClass}--fixed`,
  static: `${baseClass}--static`,
  sticky: `${baseClass}--sticky`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    paddingSize: paddingSizeMapping,
    positionType: positionMapping
  }
};

export default mapping;
