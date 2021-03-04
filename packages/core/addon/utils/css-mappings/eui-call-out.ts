export const baseClass: string = 'euiCallOut';

export const colorMapping = {
  primary: `${baseClass}--primary`,
  success: `${baseClass}--success`,
  warning: `${baseClass}--warning`,
  danger: `${baseClass}--danger`,
};

export const sizeMapping = {
  s: `${baseClass}--small`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping,
    size: sizeMapping,
  },
};

export default mapping;
