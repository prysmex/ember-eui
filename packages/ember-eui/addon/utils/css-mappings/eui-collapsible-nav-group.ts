export const baseClass: string = 'euiCollapsibleNavGroup';

export const backgroundColorMapping = {
  none: '',
  light: `${baseClass}--light`,
  dark: `${baseClass}--dark`,
};

export const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    backgroundColor: backgroundColorMapping,
  },
};

export default mapping;
