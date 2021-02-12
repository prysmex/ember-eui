import { modifier } from 'ember-modifier';

export default modifier(function invalidateIndeterminate(
  element: HTMLInputElement,
  [indeterminate]: [boolean]
) {
  if (element) {
    element.indeterminate = indeterminate;
  }
});
