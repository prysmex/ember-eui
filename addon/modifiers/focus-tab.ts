import { modifier } from 'ember-modifier';

export default modifier(function focusTab(
  _element: HTMLElement,
  [selectedTabId, isDisabled, focusFn,another]: [Tab, boolean, (...args: any[]) => any, boolean]
) {
      if(selectedTabId === undefined && !isDisabled) {
        focusFn();
  }
});
