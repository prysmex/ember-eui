import { modifier } from 'ember-modifier';

type Target = Element | string | null;

type OnEventSimulateEventOptions = { target: Target; event: Event };

export default modifier(function onEventSimulateEvent(
  element,
  [eventName]: [string],
  { target, event }: OnEventSimulateEventOptions
): void | (() => unknown) {
  let _target: EventTarget | null;
  if (target && typeof target === 'string') {
    _target = element.querySelector(target);
  }

  function dispatch(e: MouseEvent): void {
    if (_target && typeof target === 'string') {
      // Prevent a recursive behavior catched by the browser
      if (e.target instanceof Element && e.target.closest(target)) {
        _target.dispatchEvent(event);
      }
    }
  }

  if (target) {
    element.addEventListener(eventName, dispatch);
    return (): void => {
      element.removeEventListener(eventName, dispatch);
    };
  }
});
