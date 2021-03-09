export const baseClass = 'euiFlyout';

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  l: `${baseClass}--large`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping
  }
};

export default mapping;
