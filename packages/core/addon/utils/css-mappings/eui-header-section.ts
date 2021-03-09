export const baseClass = 'euiHeaderSection';

export const growMapping = {
  false: `${baseClass}--dontGrow`,
  true: `${baseClass}--grow`
};

export const alignMapping = {
  left: `${baseClass}--left`,
  right: `${baseClass}--right`
};

export const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    grow: growMapping,
    alignItems: alignMapping
  }
};

export default mapping;
