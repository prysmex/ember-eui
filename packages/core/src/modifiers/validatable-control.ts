import { typeOf } from '@ember/utils';

import { modifier } from 'ember-modifier';

function validatableControl(
  element: HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement,
  [isInvalid, errorMessage]: [boolean | undefined, (string | undefined)?]
) {
  if (typeOf(element.setCustomValidity) !== 'function') {
    return;
  }

  if (isInvalid) {
    element.setCustomValidity(errorMessage || 'Invalid');
  } else {
    element.setCustomValidity('');
  }
}

export default modifier(validatableControl);
