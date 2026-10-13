/*
 * Ported from @elastic/eui 123.1.0 `services/hooks/useEuiDisabledElement.ts`
 * (the event prevention of the hook, as an Ember modifier).
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 */
import { modifier } from 'ember-modifier';

/**
 * Events a custom (`aria-disabled`) disabled element swallows, like upstream
 * `DISABLED_ELEMENT_EVENTS`. Focus and blur are kept, so the element stays
 * focusable (e.g. for a tooltip).
 */
export const DISABLED_ELEMENT_EVENTS = [
  'click',
  'mousedown',
  'mouseup',
  'mouseenter',
  'mouseleave',
  'mouseout',
  'mousemove',
  'mouseover',
  'pointerdown',
  'pointerup',
  'pointerenter',
  'pointerleave',
  'pointermove',
  'pointerover',
  'touchstart',
  'touchend',
  'touchmove',
  'keydown',
  'keyup',
  'keypress',
  'submit'
] as const;

/** Keys that still work on a custom disabled element (upstream `keys.TAB`, `keys.ESCAPE`). */
const ALLOWED_KEY_EVENTS = ['Tab', 'Escape'];

const isAllowedKeyEvent = (event: Event) =>
  event instanceof KeyboardEvent && ALLOWED_KEY_EVENTS.includes(event.key);

const EVENTS = new Set<string>(DISABLED_ELEMENT_EVENTS);

function preventEvent(event: Event) {
  if (isAllowedKeyEvent(event)) return;
  event.stopImmediatePropagation();
  event.preventDefault();
  event.stopPropagation();
}

/**
 * Upstream `useEuiDisabledElement` for `hasAriaDisabled`: while the element
 * is disabled with `aria-disabled`, mouse, pointer, touch, keyboard (except
 * Tab and Escape) and submit events are stopped in the capture phase, and
 * programmatic `click()` / `dispatchEvent()` of those events do nothing.
 * Restores the element when it is enabled again or removed.
 *
 * Usage: `{{euiDisabledElement this.isDisabled this.hasAriaDisabled}}`.
 */
const euiDisabledElement = modifier(function euiDisabledElement(
  target: Element,
  [isDisabled, hasAriaDisabled]: [boolean | undefined, boolean | undefined]
) {
  if (!(isDisabled && hasAriaDisabled)) return;
  const element = target as HTMLElement;

  const original = {
    click: element.click,
    dispatchEvent: element.dispatchEvent
  };

  for (const type of DISABLED_ELEMENT_EVENTS) {
    element.addEventListener(type, preventEvent, { capture: true });
  }
  element.click = () => {};
  element.dispatchEvent = (event: Event) => {
    if (EVENTS.has(event.type) && !isAllowedKeyEvent(event)) return false;
    return original.dispatchEvent.call(element, event);
  };

  return () => {
    for (const type of DISABLED_ELEMENT_EVENTS) {
      element.removeEventListener(type, preventEvent, { capture: true });
    }
    element.click = original.click;
    element.dispatchEvent = original.dispatchEvent;
  };
});

export default euiDisabledElement;
