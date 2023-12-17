export const baseClass = 'euiSpacer';

export const sizeMapping = {
  xs: `${baseClass}--xs`,
  s: `${baseClass}--s`,
  m: `${baseClass}--m`,
  l: `${baseClass}--l`,
  xl: `${baseClass}--xl`,
  xxl: `${baseClass}--xxl`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping
  }
};

export default mapping;
