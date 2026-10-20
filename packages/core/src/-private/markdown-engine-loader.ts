import { tracked } from '@glimmer/tracking';
import { buildWaiter } from '@ember/test-waiters';

type MarkdownEngine = typeof import('./markdown-engine.ts');

// `await render()` / `settled()` wait for the engine while it loads
const waiter = buildWaiter('@ember-eui/core:markdown-engine');

class Loader {
  @tracked engine?: MarkdownEngine;
  promise?: Promise<void>;

  load(): Promise<void> {
    if (!this.promise) {
      const token = waiter.beginAsync();

      this.promise = import('./markdown-engine.ts')
        .then(
          (engine) => {
            this.engine = engine;
          },
          (error: unknown) => {
            // a later render retries, e.g. after a failed chunk request
            this.promise = undefined;
            console.error('EuiMarkdownFormat: could not load markdown', error);
          }
        )
        .finally(() => waiter.endAsync(token));
    }

    return this.promise;
  }
}

const loader = new Loader();

/**
 * The markdown engine once it has loaded (the first call starts loading
 * it), `undefined` until then. Reading it inside a template or getter
 * re-renders once it has loaded.
 */
export function markdownEngine(): MarkdownEngine | undefined {
  void loader.load();

  return loader.engine;
}

/** Resolves once the markdown engine has loaded (or failed to). */
export function loadMarkdownEngine(): Promise<void> {
  return loader.load();
}
