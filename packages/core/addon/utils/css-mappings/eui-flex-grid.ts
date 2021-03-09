export const baseClass = 'euiFlexGrid';

export const directionMapping = {
  row: '',
  column: `${baseClass}--directionColumn`
};

export const gutterSizeMapping = {
  none: `${baseClass}--gutterNone`,
  s: `${baseClass}--gutterSmall`,
  m: `${baseClass}--gutterMedium`,
  l: `${baseClass}--gutterLarge`,
  xl: `${baseClass}--gutterXLarge`
};

export const columnsMapping = {
  0: `${baseClass}--wrap`,
  1: `${baseClass}--single`,
  2: `${baseClass}--halves`,
  3: `${baseClass}--thirds`,
  4: `${baseClass}--fourths`
};

export const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    direction: directionMapping,
    gutterSize: gutterSizeMapping,
    columns: columnsMapping
  }
};

export default mapping;
