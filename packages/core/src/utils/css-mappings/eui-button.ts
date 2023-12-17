export const baseClass = 'euiButton';

const sizeMapping = {
  s: `${baseClass}--small`,
  m: ''
};

export const colors = {
  primary: `--primary`,
  accent: `--accent`,
  success: `--success`,
  warning: `--warning`,
  danger: `--danger`,
  ghost: `--ghost`,
  text: `--text`
};

const colorMapping = {
  primary: `${baseClass}${colors.primary}`,
  accent: `${baseClass}${colors.accent}`,
  success: `${baseClass}${colors.success}`,
  warning: `${baseClass}${colors.warning}`,
  danger: `${baseClass}${colors.danger}`,
  ghost: `${baseClass}${colors.ghost}`,
  text: `${baseClass}${colors.text}`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping,
    size: sizeMapping
  }
};

export default mapping;
