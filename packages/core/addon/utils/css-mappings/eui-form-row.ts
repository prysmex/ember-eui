export const baseClass = 'euiFormRow';

export const displayMappingToClassMapping = {
  row: '',
  rowCompressed: `${baseClass}--compressed`,
  columnCompressed: `${baseClass}--compressed ${baseClass}--horizontal`,
  center: '',
  centerCompressed: `${baseClass}--compressed`,
  columnCompressedSwitch: `${baseClass}--compressed ${baseClass}--horizontal ${baseClass}--hasSwitch`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    display: displayMappingToClassMapping
  }
};

export default mapping;
