export const baseClass = 'euiCard';

export const textAlignMapping = {
  left: `${baseClass}--leftAligned`,
  center: `${baseClass}--centerAligned`,
  right: `${baseClass}--rightAligned`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    textAlign: textAlignMapping
  }
};

export default mapping;
