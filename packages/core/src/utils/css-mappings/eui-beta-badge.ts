export const baseClass = 'euiBetaBadge';

export const colorMapping = {
  accent: `${baseClass}--accent`,
  subdued: `${baseClass}--subdued`,
  hollow: `${baseClass}--hollow`
};

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: ''
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping,
    size: sizeMapping
  }
};

export default mapping;
