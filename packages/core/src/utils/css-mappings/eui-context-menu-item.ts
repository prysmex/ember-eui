export const baseClass = '';

const disabledMapping = {
  true: 'euiContextMenuItem-isDisabled'
};

const layoutAlignMapping = {
  primary: `${baseClass}--primary`,
  accent: `${baseClass}--accent`,
  text: `${baseClass}--text`
};

const sizeMapping = {
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