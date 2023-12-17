export const baseClass = 'euiLink';

export const colorMapping = {
  primary: `${baseClass}--primary`,
  subdued: `${baseClass}--subdued`,
  success: `${baseClass}--success`,
  accent: `${baseClass}--accent`,
  danger: `${baseClass}--danger`,
  warning: `${baseClass}--warning`,
  ghost: `${baseClass}--ghost`,
  text: `${baseClass}--text`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping
  }
};

export default mapping;
