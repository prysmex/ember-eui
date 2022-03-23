export const baseClass = 'euiCodeBlock';

export const fontSizeMapping = {
  s: `${baseClass}--fontSmall`,
  m: `${baseClass}--fontMedium`,
  l: `${baseClass}--fontLarge`
};

export const paddingSizeMapping = {
  none: '',
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    fontSize: fontSizeMapping,
    paddingSize: paddingSizeMapping
  }
};

export default mapping;
