export const baseClass = 'euiImage';

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  l: `${baseClass}--large`,
  xl: `${baseClass}--xlarge`,
  fullWidth: `${baseClass}--fullWidth`
};

export const marginMapping = { 
  s: `${baseClass}--marginSmall`,
  m: `${baseClass}--marginMedium`,
  l: `${baseClass}--marginLarge`,
  xl: `${baseClass}--marginXlarge`,
};

export const floatMapping ={

  left: `${baseClass}--floatLeft`,
  right: `${baseClass}--floatRight`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping,
    float: floatMapping,
    margin: marginMapping,
  }
};

export default mapping;
