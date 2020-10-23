import { modifier } from 'ember-modifier';

interface Tab {
  id: string | number;
  name: string;
  content: any;
}

export default modifier(function focusTab(element: HTMLElement, [selectedTabId, isDisabled, focusFn]: [Tab, boolean, (...args: any[]) => any]) {
  if (selectedTabId === undefined && !isDisabled) {
    focusFn()
  }
});
