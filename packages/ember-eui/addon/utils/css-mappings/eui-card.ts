export const baseClass: string = 'euiCard';

export const textAlignMapping = {
  left: `${baseClass}--leftAligned`,
  center: `${baseClass}--centerAligned`,
  right: `${baseClass}--rightAligned`,
};

export const paddingSizeMapping = {
  none: `${baseClass}--paddingNone`,
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`,
};

export const selectableColor = {
  primary: `${baseClass}--isSelectable--primary`,
  danger: `${baseClass}--isSelectable--danger`,
  text: `${baseClass}--isSelectable--text`,
  ghost: `${baseClass}--isSelectable--ghost`,
  success: `${baseClass}--isSelectable--success`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    textAlign: textAlignMapping,
    paddingSize: paddingSizeMapping,
    color: selectableColor,
  },
};

export default mapping;
