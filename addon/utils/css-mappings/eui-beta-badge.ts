export const baseClass: string = 'euiBetaBadge';

export const type = {
  iconOnly: `${baseClass}--iconOnly`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    type: type,
  }
};

export default mapping;