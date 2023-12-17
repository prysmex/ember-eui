export const baseClass = 'euiFlyout';

export const paddingSizeMapping = {
  none: `${baseClass}--paddingNone`,
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`
};

export const sideMapping = {
  left: 'euiFlyout--left',
  right: ''
};

export const typeMapping = {
  push: 'euiFlyout--push',
  overlay: ''
};

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  l: `${baseClass}--large`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping,
    padding: paddingSizeMapping,
    side: sideMapping,
    type: typeMapping
  }
};

export default mapping;
