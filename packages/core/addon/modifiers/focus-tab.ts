import { modifier } from 'ember-modifier';

export default modifier(function focusTab(
  _element: HTMLElement,
  [selectedTabId, isDisabled, focusFn]: [Tab, boolean, (...args: unknown[]) => void, boolean]
) {
  if (selectedTabId === undefined && !isDisabled) {
    focusFn();
  }
});
