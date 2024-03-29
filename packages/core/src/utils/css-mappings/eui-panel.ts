export const baseClass = 'euiPanel';

export const paddingSizeMapping = {
  none: '',
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`
};

export const borderRadiusMapping = {
  none: `${baseClass}--borderRadiusNone`,
  m: `${baseClass}--borderRadiusMedium`
};

export const colorMapping = {
  transparent: `${baseClass}--transparent`,
  plain: `${baseClass}--plain`,
  subdued: `${baseClass}--subdued`,
  accent: `${baseClass}--accent`,
  primary: `${baseClass}--primary`,
  success: `${baseClass}--success`,
  warning: `${baseClass}--warning`,
  danger: `${baseClass}--danger`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    paddingSize: paddingSizeMapping,
    borderRadius: borderRadiusMapping,
    color: colorMapping
  }
};

export default mapping;
