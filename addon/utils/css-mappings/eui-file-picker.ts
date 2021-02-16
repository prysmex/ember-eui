export const baseClass: string = 'euiFilePicker';

export const displayMapping = {
  none: ``,
  large: `${baseClass}--large`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    display: displayMapping,
  },
};

export default mapping;
