export const baseClass = '';

export const disabledMapping = {
  true: 'euiContextMenuItem-isDisabled'
};

export const layoutAlignMapping = {
  primary: `${baseClass}--primary`,
  accent: `${baseClass}--accent`,
  text: `${baseClass}--text`
};

export const sizeMapping = {
  s: 'euiContextMenuItem--small'
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    disabled: disabledMapping,
    layoutAlign: layoutAlignMapping,
    size: sizeMapping,
  }
};

export default mapping;