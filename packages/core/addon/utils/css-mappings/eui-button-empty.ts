export const baseClass: string = 'euiButtonEmpty';

const colorMapping = {
  text: `${baseClass}--text`,
  danger: `${baseClass}--danger`,
  warning: `${baseClass}--warning`,
  ghost: `${baseClass}--ghost`,
  primary: `${baseClass}--primary`,
  success: `${baseClass}--success`,
};

const sizeMapping = {
  xs: `${baseClass}--xSmall`,
  s: `${baseClass}--small`,
  l: `${baseClass}--large`,
};

const flushMapping = {
  left: `${baseClass}--flushLeft`,
  right: `${baseClass}--flushRight`,
  both: `${baseClass}--flushBoth`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping,
    size: sizeMapping,
    flush: flushMapping,
  },
};

export default mapping;
