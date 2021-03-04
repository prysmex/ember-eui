export const baseClass: string = 'euiToolTip';

export const positionMapping = {
  top: `${baseClass}--top`,
  right: `${baseClass}--right`,
  bottom: `${baseClass}--bottom`,
  left: `${baseClass}--left`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    position: positionMapping,
  },
};

export default mapping;
