import { scheduleOnce } from '@ember/runloop';
import { modifier } from 'ember-modifier';

export default modifier(function focusTab(
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
