import { buildWaiter } from '@ember/test-waiters';

const frameWaiter = buildWaiter('@ember-eui/core:eui-flyout-frame');

/**
 * Runs `callback` in the next animation frame (upstream's resize observer
 * hook does too, so a layout change cannot loop the observer); tests wait
 * for it.
 */
export function nextFrame(callback: () => void): void {
  const token = frameWaiter.beginAsync();
  requestAnimationFrame(() => {
    try {
      callback();
    } finally {
      frameWaiter.endAsync(token);
    }
  });
}
