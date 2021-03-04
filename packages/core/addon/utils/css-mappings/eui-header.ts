export const baseClass: string = 'euiHeader';

export const themeMapping = {
  dark: `${baseClass}--dark`,
  default: `${baseClass}--default`,
};

export const positionMapping = {
  static: `${baseClass}--static`,
  fixed: `${baseClass}--fixed`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    theme: themeMapping,
    position: positionMapping,
  },
};

export default mapping;
