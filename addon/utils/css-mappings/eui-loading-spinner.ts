export const baseClass: string = 'euiLoadingSpinner';

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  l: `${baseClass}--large`,
  xl: `${baseClass}--xLarge`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping
  }
};

export default mapping;
