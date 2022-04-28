export const baseClass = 'euiPage';

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

export const paddingSizeMapping = {
  none: '',
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`
};

export const directionMapping = {
  row: '',
  column: `${baseClass}--column`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    paddingSize: paddingSizeMapping,
    direction: directionMapping
  }
};

export default mapping;
