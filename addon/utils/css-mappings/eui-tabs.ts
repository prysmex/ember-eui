export const baseClass: string = 'euiTabs';

export const displayMapping = {
  condensed: `${baseClass}--condensed`,
  default: '',
};

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: '',
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping,
    display: displayMapping
  }
};

export default mapping;
