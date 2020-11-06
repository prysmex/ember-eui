const baseClass: string = 'euiToolTip';

const paddingMapping = {
  none: '',
  xs: `${baseClass}__padding--xs`,
  s: `${baseClass}__padding--s`,
  m: `${baseClass}__padding--m`,
  l: `${baseClass}__padding--l`,
  xl: `${baseClass}__padding--xl`
};

const positionMapping = {
  top: `${baseClass}--top`,
  right: `${baseClass}--right`,
  bottom: `${baseClass}--bottom`,
  left: `${baseClass}--left`,
};

const displayMapping = {
  inlineBlock: '',
  block: 'euiToolTipAnchor--displayBlock',
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    padding: paddingMapping,
    display: displayMapping,
    position: positionMapping
  }
};

export default mapping;
