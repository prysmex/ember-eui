export const baseClass = 'euiStat';

export const textAlignMapping = {
  left: `${baseClass}--leftAligned`,
  center: `${baseClass}--centerAligned`,
  right: `${baseClass}--rightAligned`
};

export const colorMapping = {
  default: '',
  subdued: `${baseClass}__title--subdued`,
  primary: `${baseClass}__title--primary`,
  success: `${baseClass}__title--success`,
  danger: `${baseClass}__title--danger`,
  accent: `${baseClass}__title--accent`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    textAlign: textAlignMapping,
    color: colorMapping
  }
};

export default mapping;
