export const baseClass: string = 'euiFilePicker';

export const displayMapping = {
  default: ``,
  large: `${baseClass}--large`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    display: displayMapping,
  },
};

export default mapping;
