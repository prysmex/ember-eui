import { modifier } from 'ember-modifier';
import { typeOf } from '@ember/utils';

export default modifier(function validatableControl(
  element: HTMLObjectElement,
  [isInvalid]: [boolean]
) {
  if (typeOf(element.setCustomValidity) !== 'function') {
    return;
  }
  if (isInvalid) {
    element.setCustomValidity('Invalid');
  } else {
    element.setCustomValidity('');
  }
});
