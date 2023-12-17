export const baseClass = 'euiHeaderLinks__list';

export const gutterSizeMapping = {
  none: '',
  xs: `${baseClass}--gutterXS`,
  s: `${baseClass}--gutterS`,
  m: `${baseClass}--gutterM`,
  l: `${baseClass}--gutterL`
};

export const mobileGutterSizeMapping = {
  none: '',
  xs: 'euiHeaderLinks__mobileList--gutterXS',
  s: 'euiHeaderLinks__mobileList--gutterS',
  m: 'euiHeaderLinks__mobileList--gutterM',
  l: 'euiHeaderLinks__mobileList--gutterL'
};

const mapping: ComponentMapping = {
  base: '',
  properties: {
    gutterSize: gutterSizeMapping,
    mobileGutterSize: mobileGutterSizeMapping
  }
};

export default mapping;
