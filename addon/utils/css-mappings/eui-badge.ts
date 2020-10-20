export const baseClass: string = 'euiBadge';

export const iconSideMapping = {
  left: `${baseClass}--iconLeft`,
  right: `${baseClass}--iconRight`
}

export const colorMapping = {
  hollow: `${baseClass}--hollow`
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    iconSide: iconSideMapping,
    color: colorMapping
  }
};

export default mapping;