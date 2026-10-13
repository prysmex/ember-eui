import { modifier } from 'ember-modifier';

/** Calls `callback` on every window resize while the element is rendered. */
const onWindowResize = modifier(
  (_element: Element, [callback]: [() => void]) => {
    window.addEventListener('resize', callback);
    return () => window.removeEventListener('resize', callback);
  }
);

export default onWindowResize;
