import { assert } from '@ember/debug';
import { isArray } from '@ember/array';
import { get, set } from '@ember/object';
import { validate } from 'ember-validators';
import buildMessage from './validation-errors';
import { typeOf } from '@ember/utils';

/**
 * Based on ember-paper validation-mixin
 * @param {string} property - property to grab the currentValue from
 * @returns
 */
export function buildValidationMessages(property) {
  const messages = [];

  let emberValidatorConfig = this.validations || {};
  let emberValidatorsConfigKeys = Object.keys(emberValidatorConfig);

  // execute ember-validators validations
  let currentValue = get(this, property);
  emberValidatorsConfigKeys.forEach((configKey) => {
    const config = emberValidatorConfig[configKey];
    try {
      let isError = validate(
        configKey,
        currentValue,
        config,
        config.model,
        config.attribute
      );
      if (isError !== true) {
        messages.push(
          buildMessage(config.attribute ? config.attribute : null, isError)
        );
      }
    } catch (error) {
      console.log(error);
    }
  });

  // custom validations
  let customValidators = this.customValidations;

  assert('`customValidations` must be an array', isArray(customValidators));

  customValidators.forEach((validator) => {
    assert(
      'validation.validate must be a function',
      typeOf(validator?.validate === 'function')
    );
    let isError = validator.validation(currentValue, validator.params);

    if (isError !== true) {
      messages.push(buildMessage(null, isError));
    }
  });

  // error messages array
  let errors = this.args.errors || [];

  assert('`errors` must be an array', isArray(errors));

  messages.push(...errors);

  return messages;
}

export function notifyValidityChange() {
  const isValid = this.isValid;
  const lastIsValid = this.lastIsValid;
  const isTouched = this.isTouched;
  const lastIsTouched = this.lastIsTouched;
  const isInvalidAndTouched = this.isInvalidAndTouched;

  if (lastIsValid !== isValid || lastIsTouched !== isTouched) {
    this.args.onValidityChange?.({
      child: this,
      isValid,
      isTouched,
      isInvalidAndTouched
    });

    set(this, 'lastIsValid', isValid);
    set(this, 'lastIsTouched', isTouched);
  }
}

export default {
  buildValidationMessages,
  notifyValidityChange
};
