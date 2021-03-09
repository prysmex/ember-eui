export const baseClass = 'euiListGroupItem';

export const sizeMapping = {
  xs: `${baseClass}--xSmall`,
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  l: `${baseClass}--large`
};

export const colorMapping = {
  inherit: '',
  primary: `${baseClass}--primary`,
  text: `${baseClass}--text`,
  subdued: `${baseClass}--subdued`,
  ghost: `${baseClass}--ghost`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping,
    color: colorMapping
  }
};

export default mapping;
