import Component from '@glimmer/component';
import { scheduleOnce } from '@ember/runloop';
import { modifier } from 'ember-modifier';

const focusTabModifier = modifier(function focusTab(
  _element: HTMLElement,
  [selectedTabId, isDisabled, focusFn]: [
    Tab,
    boolean,
    (...args: unknown[]) => void,
    boolean
  ]
) {
  if (selectedTabId === undefined && !isDisabled) {
    const fn = () => {
      focusFn();
    };
    scheduleOnce('afterRender', null, fn);
  }
});

export default class EuiTabComponent extends Component {
  focusTabModifier = focusTabModifier;
}
