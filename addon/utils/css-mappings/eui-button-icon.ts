export const baseClass: string = 'euiButtonIcon';

const colorMapping = {
  accent: `${baseClass}--accent`,
  danger: `${baseClass}--danger`,
  ghost: `${baseClass}--ghost`,
  primary: `${baseClass}--primary`,
  subdued: `${baseClass}--subdued`,
  success: `${baseClass}--success`,
  text: `${baseClass}--text`,
  warning: `${baseClass}--warning`
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping
  }
};

export default mapping;