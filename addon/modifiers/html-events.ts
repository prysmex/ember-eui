import { modifier } from 'ember-modifier';

type Modifier = {
  event: string;
  handler: () => unknown;
};

export default modifier(function htmlEvents(
  element: HTMLElement,
  [events]: [Modifier[]]
): void | (() => void) {
  if (events) {
    events.forEach((mod) => {
      element.addEventListener(mod.event, mod.handler);
    });
    return () => {
      events.forEach((mod) => {
        element.removeEventListener(mod.event, mod.handler);
      });
    };
  }
});
