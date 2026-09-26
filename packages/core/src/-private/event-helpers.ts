import { assert } from '@ember/debug';

type Handler = ((event: Event) => unknown) | undefined | null;

/**
 * Replacements for `ember-event-helpers` (a v1 addon with no v2 release).
 * Same behavior: wrap an optional handler so the event's default action /
 * propagation is stopped before the handler runs.
 *
 *   {{on "click" (preventDefault this.onClick)}}
 */
export function preventDefault(handler?: Handler) {
  assert(
    `Expected '${typeof handler}' to be a function, if present.`,
    !handler || typeof handler === 'function'
  );

  return function (event: Event) {
    assert(
      `Expected '${typeof event}' to be an Event and have a 'preventDefault' method.`,
      event && typeof event.preventDefault === 'function'
    );

    event.preventDefault();

    if (handler) handler(event);
  };
}

export function stopPropagation(handler?: Handler) {
  assert(
    `Expected '${typeof handler}' to be a function, if present.`,
    !handler || typeof handler === 'function'
  );

  return function (event: Event) {
    assert(
      `Expected '${typeof event}' to be an Event and have a 'stopPropagation' method.`,
      event && typeof event.stopPropagation === 'function'
    );

    event.stopPropagation();

    if (handler) handler(event);
  };
}
