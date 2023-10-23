export const baseClass = 'euiHeaderSectionItem';

export const borderSizeMappping = {
  none: '',
  left: `${baseClass}--borderLeft`,
  right: `${baseClass}--borderRight`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    borderSide: borderSizeMappping
  }
};

export default mapping;
