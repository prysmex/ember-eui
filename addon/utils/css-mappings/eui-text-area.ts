export const baseClass: string = 'euiTextArea';

export const resizeMapping = {
  vertical: `${baseClass}--resizeVertical`,
  horizontal: `${baseClass}--resizeHorizontal`,
  both: `${baseClass}--resizeBoth`,
  none: `${baseClass}--resizeNone`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    resize: resizeMapping,
  },
};

export default mapping;
