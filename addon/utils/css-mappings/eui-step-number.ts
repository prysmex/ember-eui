const baseClass: string = 'euiStepNumber';

const statusToClassMap = {
  incomplete: `${baseClass}--incomplete`,
  disabled: `${baseClass}--disabled`,
  loading: `${baseClass}--loading`,
  warning: `${baseClass}--warning`,
  danger: `${baseClass}--danger`,
  complete: `${baseClass}--complete`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    type: statusToClassMap,
  },
};

export default mapping;
