import { modifier } from 'ember-modifier';

export default modifier(function screenReaderOnly(
  element: Element,
  [showOnFocus = false]: [boolean?]
) {
  element.classList.add(
    showOnFocus ? 'euiScreenReaderOnly--showOnFocus' : 'euiScreenReaderOnly'
  );
});
