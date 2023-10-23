import Component from '@glimmer/component';
import { scheduleOnce } from '@ember/runloop';
import { modifier } from 'ember-modifier';

const focusTabModifier = modifier(function focusTab(
  _element: HTMLElement,
  [tabId, selectedTabId, isDisabled, focusFn, onFocusFn]: [
    string | number,
    Tab,
    boolean,
    (...args: unknown[]) => any,
    (...args: unknown[]) => any
  ]
) {
  if (selectedTabId === undefined && !isDisabled) {
    scheduleOnce('afterRender', null, focusFn, tabId);
    scheduleOnce('afterRender', null, onFocusFn, tabId);
  }
});

export default class EuiTabComponent extends Component {
  focusTabModifier = focusTabModifier;
}
