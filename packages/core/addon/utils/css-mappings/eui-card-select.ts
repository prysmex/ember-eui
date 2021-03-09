export const baseClass = 'euiCardSelect';

export const colorMapping = {
  primary: `${baseClass}--primary`,
  danger: `${baseClass}--danger`,
  text: `${baseClass}--text`,
  ghost: `${baseClass}--ghost`,
  success: `${baseClass}--success`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping
  }
};

export default mapping;
