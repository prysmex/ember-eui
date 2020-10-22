export const baseClass: string = 'euiButtonEmpty';

export const colorMapping = {
  primary: `${baseClass}--primary`,
  danger: `${baseClass}--danger`,
  text: `${baseClass}--text`,
  ghost: `${baseClass}--ghost`
}

export const sizeMapping = {
  xs: `${baseClass}--xSmall`,
  s: `${baseClass}--small`,
  l: `${baseClass}--large`,
}

export const flushMapping = {
  left: `${baseClass}--flushLeft`,
  right: `${baseClass}--flushRight`,
  both: `${baseClass}--flushBoth`,
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
