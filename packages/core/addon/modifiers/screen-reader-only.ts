import { modifier } from 'ember-modifier';

export default modifier(function screenReaderOnly(
  element: HTMLObjectElement,
  [showOnFocus = false]: [boolean]
) {
  !showOnFocus && element.classList.add('euiScreenReaderOnly');
  showOnFocus && element.classList.add('euiScreenReaderOnly--showOnFocus');
});
