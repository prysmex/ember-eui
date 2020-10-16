export const baseClass: string = 'euiAvatar';

export const sizeMapping = {
  s: `${baseClass}--s`,
  m: `${baseClass}--m`,
  l: `${baseClass}--l`,
  xl: `${baseClass}--xl`
};

export const typeMapping = {
  space: `${baseClass}--space`,
  user: `${baseClass}--user`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping,
    type: typeMapping
  }
};

export default mapping;