export const baseClass = 'euiToast';

export const colorMapping = {
  none: '',
  primary: `${baseClass}--primary`,
  success: `${baseClass}--success`,
  warning: `${baseClass}--warning`,
  danger: `${baseClass}--danger`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping
  }
};

export default mapping;
