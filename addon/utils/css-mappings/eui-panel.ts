export const baseClass: string = 'euiPanel';

export const paddingMapping = {
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`,
};

const borderRadiusMapping = {
  none: `${baseClass}--borderRadiusNone`,
  m: `${baseClass}--borderRadiusMedium`,
};

const colorMapping = {
  transparent: `${baseClass}--transparent`,
  plain: `${baseClass}--plain`,
  subdued: `${baseClass}--subdued`,
  accent: `${baseClass}--accent`,
  primary: `${baseClass}--primary`,
  success: `${baseClass}--success`,
  warning: `${baseClass}--warning`,
  danger: `${baseClass}--danger`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    padding: paddingMapping,
    borderRadius: borderRadiusMapping,
    color: colorMapping,
  },
};

export default mapping;
