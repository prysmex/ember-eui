export const baseClass = '';

export const disabledMapping = {
  true: 'euiContextMenuItem-isDisabled'
};

export const layoutAlignMapping = {
  center: '',
  top: 'euiContextMenu__itemLayout--top',
  bottom: 'euiContextMenu__itemLayout--bottom'
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