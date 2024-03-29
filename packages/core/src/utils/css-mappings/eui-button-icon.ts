export const baseClass = 'euiButtonIcon';

export const colorMapping = {
  primary: `${baseClass}--primary`,
  accent: `${baseClass}--accent`,
  success: `${baseClass}--success`,
  warning: `${baseClass}--warning`,
  danger: `${baseClass}--danger`,
  ghost: `${baseClass}--ghost`,
  text: `${baseClass}--text`
};

export const displayMapping = {
  base: '',
  empty: `${baseClass}--empty`,
  fill: `${baseClass}--fill`
};

export const sizeMapping = {
  xs: `${baseClass}--xSmall`,
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping,
    display: displayMapping,
    size: sizeMapping
  }
};

export default mapping;
