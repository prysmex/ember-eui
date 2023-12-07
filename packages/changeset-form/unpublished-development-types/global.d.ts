
declare module 'ember-changeset-validations/*' {
  type Options = {};
  type Validator = (options: Options) => unknown;
  const validatePresence: Validator;
  const validateLength: Validator;
  const validateConfirmation: Validator;
  const validateFormat: Validator;
  const validateNumber: Validator;
  export {
    validatePresence,
    validateLength,
    validateConfirmation,
    validateFormat,
    validateNumber
  };
}
