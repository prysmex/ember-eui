import { getOwner } from '@ember/application';
import { isArray } from '@ember/array';
import { assert } from '@ember/debug';
import { get, set } from '@ember/object';
import { typeOf } from '@ember/utils';

import { validate } from 'ember-validators';

import getMessages from './get-messages';
import buildMessage from './validation-errors';

/**
 * Based on ember-paper validation-mixin
 * @param {string} property - property to grab the currentValue from
 * @returns
 */
export function buildValidationMessages(property) {
  const messages = [];

  let messageBuilder = getMessages(getOwner(this));
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
          buildMessage(
            messageBuilder,
            config.attribute ? config.attribute : null,
            isError
          )
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
      messages.push(buildMessage(messageBuilder, null, isError));
    }
  });

  // error messages array
  let errors = this.errors || [];

  assert('`errors` must be an array', isArray(errors));

  messages.push(...errors);

  return messages;
}

export function notifyValidityChange(ctx, onValidityChange) {
  const isValid = ctx.isValid;
  const lastIsValid = ctx.lastIsValid;
  const isTouched = ctx.isTouched;
  const lastIsTouched = ctx.lastIsTouched;
  const isInvalidAndTouched = ctx.isInvalidAndTouched;

  if (lastIsValid !== isValid || lastIsTouched !== isTouched) {
    onValidityChange?.({
      child: ctx,
      isValid,
      isTouched,
      isInvalidAndTouched
    });

    set(ctx, 'lastIsValid', isValid);
    set(ctx, 'lastIsTouched', isTouched);
  }
}

export default {
  buildValidationMessages,
  notifyValidityChange
};
