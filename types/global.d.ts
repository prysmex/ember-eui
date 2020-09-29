// Types for compiled templates
declare module 'ember-eui/templates/*' {
  import { TemplateFactory } from 'htmlbars-inline-precompile';
  const tmpl: TemplateFactory;
  export default tmpl;
}

interface PropertyMapping {
  [size: string]: string | null;
}

interface ComponentProperty {
  [property: string]: PropertyMapping;
}

interface ComponentMapping {
  base: string;
  properties: ComponentProperty;
}

interface Mapping {
  [componentName: string]: ComponentMapping;
}
