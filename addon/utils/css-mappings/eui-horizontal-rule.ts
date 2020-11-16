export const baseClass: string = 'euiHorizontalRule';

export const sizeMapping = {
  full: `${baseClass}--full`,
  half: `${baseClass}--half`,
  quarter: `${baseClass}--quarter`
}

export const marginMapping = {
  none: '',
  xs: `${baseClass}--marginXSmall`,
  s: `${baseClass}--marginSmall`,
  m: `${baseClass}--marginMedium`,
  l: `${baseClass}--marginLarge`,
  xl: `${baseClass}--marginXLarge`,
  xxl: `${baseClass}--marginXXLarge`
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping,
    margin: marginMapping
  }
}

export default mapping;