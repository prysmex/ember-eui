// Types for compiled templates
declare module 'ember-eui/templates/*' {
  import { TemplateFactory } from 'htmlbars-inline-precompile';
  const tmpl: TemplateFactory;
  export default tmpl;
}

declare module 'ember-cli-string-helpers/helpers/*' {
  const humanize: string;
  export { humanize };
}

interface PropertyMapping {
  [size: string]: string;
}

interface ComponentProperty {
  [property: string]: PropertyMapping;
}

interface ComponentMapping {
  base: string;
  properties: ComponentProperty;
  inlineStyles?(styles: Record<string, unknown>): Record<string, unknown>;
}

interface Mapping {
  [componentName: string]: ComponentMapping;
}

type rgbDef = [number, number, number];

interface HSV {
  h: number;
  s: number;
  v: number;
}
interface RGB {
  r: number;
  g: number;
  b: number;
}

type HEX = string;
