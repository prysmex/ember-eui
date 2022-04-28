export const baseClass = 'euiTabs';

export const displayMapping = {
  condensed: `${baseClass}--condensed`,
  default: ''
};

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: '',
  l: `${baseClass}--large`,
  xl: `${baseClass}--xlarge`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping,
    display: displayMapping
  }
};

export default mapping;
