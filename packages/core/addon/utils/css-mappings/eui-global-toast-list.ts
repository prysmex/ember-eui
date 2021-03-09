export const baseClass: string = 'euiGlobalToastList';

export const sideMapping = {
  left: `${baseClass}--left`,
  right: `${baseClass}--right`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    side: sideMapping,
  },
};

export default mapping;
