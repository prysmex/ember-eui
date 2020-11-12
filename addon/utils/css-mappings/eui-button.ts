export const baseClass: string = 'euiButton'

export const sizeMapping = {
  s: `${baseClass}--small`
}

export const colorMapping = {
  primary: `${baseClass}--primary`,
  secondary: `${baseClass}--secondary`,
  warning: `${baseClass}--warning`,
  danger: `${baseClass}--danger`,
  ghost: `${baseClass}--ghost`,
  text: `${baseClass}--text`,
}

export const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping,
    size: sizeMapping
  }
}

export default mapping;