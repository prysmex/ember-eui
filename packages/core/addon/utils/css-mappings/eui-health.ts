

export const baseClass = 'euiHealth';


export const sizeToClassNameMap = {
  xs: `${baseClass}--textSizeXS`,
  s: `${baseClass}--textSizeS`,
  m: `${baseClass}--textSizeM`,
  inherit: `${baseClass}--textSizeInherit`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    textSize: sizeToClassNameMap,
  }
};

export default mapping;
