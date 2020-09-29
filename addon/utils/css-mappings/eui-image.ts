export const baseClass: string = 'euiImage';

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  l: `${baseClass}--large`,
  xl: `${baseClass}--xlarge`,
  fullWidth: `${baseClass}--fullWidth`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping
  }
};

export default mapping;