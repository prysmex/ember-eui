export const baseClass = 'euiPageHeader';

export const paddingSizeMapping = {
  none: '',
  s: 'euiPageHeader--paddingSmall',
  m: 'euiPageHeader--paddingMedium',
  l: 'euiPageHeader--paddingLarge'
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    paddingSize: paddingSizeMapping
  }
};

export default mapping;
