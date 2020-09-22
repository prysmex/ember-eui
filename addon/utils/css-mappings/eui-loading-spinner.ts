export const baseClass = 'euiLoadingSpinner';

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  l: `${baseClass}--large`,
  xl: `${baseClass}--xLarge`,
};

const mapping = {
  base: baseClass,
  properties: {
    size: sizeMapping
  }
};

export default mapping;
