import { isDestroyed, isDestroying } from '@ember/destroyable';
import { schedule } from '@ember/runloop';

/**
 * Run `fn` after the current render. Modifiers install during the render
 * transaction, so measurements they take must update tracked state later
 * (Ember forbids updating values already consumed by the same render).
 */
export function afterRender(owner: object, fn: () => void): void {
  schedule('afterRender', () => {
    if (isDestroying(owner) || isDestroyed(owner)) return;
    fn();
  });
}

/**
 * Observe element sizes; the callback runs on the next animation frame so
 * layout changes it causes never trigger "ResizeObserver loop" errors.
 */
export function observeResize(
  elements: Element[],
  callback: () => void
): () => void {
  let frame = 0;
  const observer = new ResizeObserver(() => {
    cancelAnimationFrame(frame);
    frame = requestAnimationFrame(callback);
  });
  for (const element of elements) observer.observe(element);
  return () => {
    cancelAnimationFrame(frame);
    observer.disconnect();
  };
}
