export const baseClass = 'euiDescriptionList';

export const typeMapping = {
  row: `${baseClass}--row`,
  inline: `${baseClass}--inline`,
  column: `${baseClass}--column`,
  responsiveColumn: `${baseClass}--responsiveColumn`
};

export const alignMapping = {
  center: `${baseClass}--center`,
  left: ''
};

export const textStyleMapping = {
  center: `${baseClass}--reverse`,
  normal: ''
};

export const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    type: typeMapping,
    align: alignMapping,
    textStyle: textStyleMapping
  }
};

export default mapping;
