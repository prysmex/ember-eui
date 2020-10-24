import { colorMapping } from "./eui-text-color";

export const baseClass: string = 'euiButtonGroup';

export const sizeMapping = {
  s: `${baseClass}--small`,
  m: `${baseClass}--medium`,
  compressed: `${baseClass}--compressed`
}

export const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size:  sizeMapping
  }
}

export default mapping;