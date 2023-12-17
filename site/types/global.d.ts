// Types for compiled templates
declare module 'site/templates/*' {
  import type { TemplateFactory } from 'htmlbars-inline-precompile';
  const tmpl: TemplateFactory;
  export default tmpl;
}

declare module 'ember-cli-string-helpers/helpers/*' {
  const humanize: (positionalParams: string[]) => string;
  export { humanize };
}
