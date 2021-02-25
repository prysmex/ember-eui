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

  function dispatch() {
    _target && _target.dispatchEvent(event);
  }

  if (target) {
    element.addEventListener(eventName, dispatch);
    return () => {
      element.removeEventListener(eventName, dispatch);
    };
  }
});
