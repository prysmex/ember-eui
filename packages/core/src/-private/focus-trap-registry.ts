import { createFocusTrap } from 'focus-trap';

import type { FocusTrap, Options } from 'focus-trap';

/**
 * Upstream's focus traps (react-focus-on) treat React-portalled children as
 * inside the trap, so a popover or combo box list opened from a modal or
 * flyout stays usable. DOM focus traps only know their container: focusing
 * an input in a portalled panel pulled focus back into the modal (and closed
 * the combo box list). Traps created here are tracked, and portalled surfaces
 * join every active trap that contains their anchor while they are open.
 */
interface Entry {
  trap: FocusTrap;
  base: HTMLElement[];
  extra: Set<HTMLElement>;
}

const active = new Set<Entry>();

const containersOf = (entry: Entry) => [...entry.base, ...entry.extra];

/** Drop-in for `createFocusTrap`; pass it as ember-focus-trap's `_createFocusTrap`. */
export function createRegisteredFocusTrap(
  elements: HTMLElement | HTMLElement[],
  options: Options = {}
): FocusTrap {
  const entry = {
    base: Array.isArray(elements) ? elements : [elements],
    extra: new Set<HTMLElement>()
  } as Entry;

  entry.trap = createFocusTrap(elements, {
    ...options,
    onActivate() {
      active.add(entry);
      options.onActivate?.();
    },
    onDeactivate() {
      active.delete(entry);
      options.onDeactivate?.();
    }
  });

  return entry.trap;
}

/**
 * Makes `surface` (a portalled panel) part of every active focus trap that
 * contains `anchor` (directly or through another attached surface). Returns
 * the cleanup.
 */
export function attachToFocusTraps(
  anchor: Element | null | undefined,
  surface: HTMLElement
): () => void {
  if (!anchor) return () => {};

  const owners = [...active].filter((entry) =>
    containersOf(entry).some(
      (container) => container !== surface && container.contains(anchor)
    )
  );

  for (const entry of owners) {
    entry.extra.add(surface);
    entry.trap.updateContainerElements(containersOf(entry));
  }

  return () => {
    for (const entry of owners) {
      if (!entry.extra.delete(surface)) continue;
      if (active.has(entry)) {
        entry.trap.updateContainerElements(containersOf(entry));
      }
    }
  };
}

/**
 * `createRegisteredFocusTrap` typed as ember-focus-trap declares its private
 * `_createFocusTrap` argument (`() => void`); it is called with the trap's
 * elements and options at runtime.
 */
export const focusTrapFactory =
  createRegisteredFocusTrap as unknown as () => void;
