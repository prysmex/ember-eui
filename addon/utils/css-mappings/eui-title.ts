export const baseClass: string = 'euiTitle';

export const sizeMapping = {
  xxxs: `${baseClass}--xxxsmall`,
  xxs: `${baseClass}--xxsmall`,
  xs: `${baseClass}--xsmall`,
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  l: `${baseClass}--large`,
};

export const transformMapping = {
  uppercase: `${baseClass}--uppercase`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping,
    textTransform: transformMapping,
  },
};

export default mapping;
