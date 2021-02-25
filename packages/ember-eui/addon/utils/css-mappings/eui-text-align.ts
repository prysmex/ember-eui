export const baseClass: string = 'euiTextAlign';

export const alignMapping = {
  left: `${baseClass}--left`,
  center: `${baseClass}--center`,
  right: `${baseClass}--right`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    textAlign: alignMapping,
  },
};

export default mapping;
