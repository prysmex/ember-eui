export const baseClass = 'euiButtonEmpty';

const colorMapping = {
  primary: `${baseClass}--primary`,
  danger: `${baseClass}--danger`,
  text: `${baseClass}--text`,
  ghost: `${baseClass}--ghost`,
  warning: `${baseClass}--warning`,
  success: `${baseClass}--success`
};

const sizeMapping = {
  xs: `${baseClass}--xSmall`,
  s: `${baseClass}--small`,
  m: ''
};

const flushMapping = {
  left: `${baseClass}--flushLeft`,
  right: `${baseClass}--flushRight`,
  both: `${baseClass}--flushBoth`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping,
    size: sizeMapping,
    flush: flushMapping
  }
};

export default mapping;
