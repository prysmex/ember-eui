export const baseClass: string = 'euiText';

export const sizeMapping: PropertyMapping = {
  xs: `${baseClass}--extraSmall`,
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping
  }
};

export default mapping;

