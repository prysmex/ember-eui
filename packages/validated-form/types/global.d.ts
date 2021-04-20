// Types for compiled templates
declare module '@ember-eui/validated-form/templates/*' {
  import { TemplateFactory } from 'htmlbars-inline-precompile';
  const tmpl: TemplateFactory;
  export default tmpl;
}

interface Validator {
  param: string;
  message: string;
  validate: (value: any, ...params: any[]) => boolean;
}

type ErrorMessages = Record<string, string>;

type ExtraError = { message: string } | string;

interface ValidateableControl {
  customValidations?: Array<Validator>;
  errorMessages?: ErrorMessages;
  errors?: Array<ExtraError>;
}
