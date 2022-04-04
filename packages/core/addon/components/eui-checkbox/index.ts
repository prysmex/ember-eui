import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';

const indeterminateModifier = modifier(function invalidateIndeterminate(
  element: HTMLInputElement,
  [indeterminate]: [boolean]
) {
  if (element) {
    element.indeterminate = indeterminate;
  }
});

export default class EuiCheckboxComponent extends Component {
  indeterminateModifier = indeterminateModifier;
}
