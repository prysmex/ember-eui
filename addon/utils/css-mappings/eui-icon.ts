export const baseClass: string = 'euiIcon';

export const sizeToClassNameMap = {
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  l: `${baseClass}--large`,
  xl: `${baseClass}--xLarge`,
  xxl: `${baseClass}--xxLarge`,
};

export const colorToClassMap = {
  primary: `${baseClass}--primary`,
  secondary: `${baseClass}--secondary`,
  success: `${baseClass}--success`,
  accent: `${baseClass}--accent`,
  warning: `${baseClass}--warning`,
  danger: `${baseClass}--danger`,
  text: `${baseClass}--text`,
  subdued: `${baseClass}--subdued`,
  ghost: `${baseClass}--ghost`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeToClassNameMap,
    color: colorToClassMap
  }
};

export default mapping;
