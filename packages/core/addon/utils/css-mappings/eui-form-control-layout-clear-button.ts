export const baseClass: string = 'euiFormRow';

export const sizeMapping = {
  s: 'euiFormControlLayoutClearButton--small',
  m: '',
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping,
  },
};

export default mapping;
