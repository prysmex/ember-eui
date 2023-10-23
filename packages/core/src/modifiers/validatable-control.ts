import { modifier } from 'ember-modifier';
import { typeOf } from '@ember/utils';

export default modifier(function validatableControl(
  element: HTMLObjectElement,
  [isInvalid, errorMessage]: [boolean, string]
) {
  if (typeOf(element.setCustomValidity) !== 'function') {
    return;
  }
  if (isInvalid) {
    element.setCustomValidity(errorMessage || 'Invalid');
  } else {
    element.setCustomValidity('');
  }
});
