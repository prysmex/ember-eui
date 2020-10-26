export const baseClass: string = 'euiFlexGroup'

export const gutterSizeMapping = {
  none: '',
  xs: `${baseClass}--gutterExtraSmall`,
  s: `${baseClass}--gutterSmall`,
  m: `${baseClass}--gutterMedium`,
  l: `${baseClass}--gutterLarge`,
  xl: `${baseClass}--gutterExtraLarge`
}

export const alignItemsMapping = {
  stretch: '',
  flexStart: `${baseClass}--alignItemsFlexStart`,
  flexEnd: `${baseClass}--alignItemsFlexEnd`,
  center: `${baseClass}--alignItemsCenter`,
  baseline: `${baseClass}--alignItemsBaseline`
}

export const justifyContentMapping = {
  flexStart: '',
  flexEnd: `${baseClass}--justifyContentFlexEnd`,
  center: `${baseClass}--justifyContentCenter`,
  spaceBetween: `${baseClass}--justifyContentSpaceBetween`,
  spaceAround: `${baseClass}--justifyContentSpaceAround`,
  spaceEvenly: `${baseClass}--justifyContentSpaceEvenly`
}

export const directionMapping = {
  row: `${baseClass}--directionRow`,
  rowReverse: `${baseClass}--directionRowReverse`,
  column: `${baseClass}--directionColumn`,
  columnReverse: `${baseClass}--directionColumnReverse`,
}

export const mapping: ComponentMapping = {
  base: baseClass,
  properties: {

  }
}

export default mapping;