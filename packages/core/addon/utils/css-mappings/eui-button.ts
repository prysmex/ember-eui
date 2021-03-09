export const baseClass = 'euiButton';

const sizeMapping = {
  s: `${baseClass}--small`
};

const colorMapping = {
  primary: `${baseClass}--primary`,
  secondary: `${baseClass}--secondary`,
  warning: `${baseClass}--warning`,
  danger: `${baseClass}--danger`,
  ghost: `${baseClass}--ghost`,
  text: `${baseClass}--text`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping,
    size: sizeMapping
  }
};

export default mapping;
