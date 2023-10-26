// Types for compiled templates
declare module '@ember-eui/core/templates/*' {
  import type { TemplateFactory } from 'htmlbars-inline-precompile';
  const tmpl: TemplateFactory;
  export default tmpl;
}

declare module 'ember-cli-string-helpers/helpers/*' {
  const humanize: (positionalParams: string[]) => string;
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

interface Styling {
  [i: string]: string | null;
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

interface Tab {
  id: string | number;
  name: string;
  content: string;
}

type HEX = string;

interface Select {
  selected: any;
  actions: {
    search: (str: string) => void;
    choose: (opt: any, select: Select) => void;
  };
}
