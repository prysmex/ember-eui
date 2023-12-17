export const baseClass = 'euiFormControlLayoutClearButton';

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: ''
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping
  }
};

export default mapping;
