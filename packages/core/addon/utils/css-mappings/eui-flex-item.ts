export const baseClass = 'euiFlexItem';

export const growMapping = {
  1: `${baseClass}--flexGrow1`,
  2: `${baseClass}--flexGrow2`,
  3: `${baseClass}--flexGrow3`,
  4: `${baseClass}--flexGrow4`,
  5: `${baseClass}--flexGrow5`,
  6: `${baseClass}--flexGrow6`,
  7: `${baseClass}--flexGrow7`,
  8: `${baseClass}--flexGrow8`,
  9: `${baseClass}--flexGrow9`,
  10: `${baseClass}--flexGrow10`,
  false: `${baseClass}--flexGrowZero`
};

export const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    grow: growMapping
  }
};

export default mapping;
