import Component from '@glimmer/component';

import { modifier } from 'ember-modifier';

let euiHeaderFixedCounter = 0;

const fixedHeaderModifier = modifier(function fixedHeader(
  _,
  [position]: [string]
): void | (() => unknown) {
  if (position === 'fixed') {
    // Increment fixed header counter for each fixed header
    euiHeaderFixedCounter++;
    document.body.classList.add('euiBody--headerIsFixed');

    return () => {
      // Both decrement the fixed counter AND then check if there are none
      if (--euiHeaderFixedCounter === 0) {
        // If there are none, THEN remove class
        document.body.classList.remove('euiBody--headerIsFixed');
      }
    };
  }
});

export default class EuiHeaderComponent extends Component {
  fixedHeader = fixedHeaderModifier;
}
