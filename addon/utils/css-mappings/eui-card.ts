export const baseClass: string = 'euiCard';

export const textAlignMapping = {
  left: `${baseClass}--leftAligned`,
  center: `${baseClass}--centerAligned`,
  right: `${baseClass}--rightAligned`,
}

export const paddingSizeMapping = {
  none: `${baseClass}--paddingNone`,
  s: `${baseClass}--paddingSmall`,
  m: `${baseClass}--paddingMedium`,
  l: `${baseClass}--paddingLarge`,
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    textAlign: textAlignMapping,
    padding: paddingSizeMapping,
  }
};

export default mapping;