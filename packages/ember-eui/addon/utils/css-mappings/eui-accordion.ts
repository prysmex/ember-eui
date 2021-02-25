export const baseClass: string = 'euiAccordion';

export const paddingMapping = {
  none: '',
  xs: `${baseClass}__padding--xs`,
  s: `${baseClass}__padding--s`,
  m: `${baseClass}__padding--m`,
  l: `${baseClass}__padding--l`,
  xl: `${baseClass}__padding--xl`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    paddingSize: paddingMapping,
  },
};

export default mapping;
