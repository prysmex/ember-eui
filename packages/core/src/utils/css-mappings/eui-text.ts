export const baseClass = 'euiText';

export const sizeMapping = {
  xs: `${baseClass}--extraSmall`,
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  relative: `${baseClass}--relative`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping
  }
};

export default mapping;
