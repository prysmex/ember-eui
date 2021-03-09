export const baseClass = 'euiBadgeGroup';

export const gutterSize = {
  xs: `${baseClass}--gutterExtraSmall`,
  s: `${baseClass}--gutterSmall`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    gutterSize: gutterSize
  }
};

export default mapping;
