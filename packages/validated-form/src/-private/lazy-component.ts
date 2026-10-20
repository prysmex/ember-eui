import { tracked } from '@glimmer/tracking';
import { buildWaiter } from '@ember/test-waiters';

const waiter = buildWaiter('@ember-eui/validated-form:lazy-component');

/**
 * A component imported the first time it is read, so the fields that render
 * a heavy control (combo box, ranges, markdown editor) do not bring it into
 * the bundle of every app that imports the form. `component` is `undefined`
 * until the import resolves; it is tracked, so the field renders then, and
 * every later read, from any field, has it at once. The import is a test
 * waiter: `settled()` waits for it.
 */
export class LazyComponent<T> {
  @tracked private loaded?: T;
  private loading?: Promise<void>;

  constructor(private importComponent: () => Promise<{ default: T }>) {}

  get component(): T | undefined {
    void this.load();

    return this.loaded;
  }

  /** Imports the component now, e.g. before showing a form that uses it. */
  load(): Promise<void> {
    if (!this.loading) {
      const token = waiter.beginAsync();

      this.loading = this.importComponent()
        .then(
          (module) => {
            this.loaded = module.default;
          },
          (error: unknown) => {
            // let a later render try again
            this.loading = undefined;
            throw error;
          }
        )
        .finally(() => waiter.endAsync(token));
    }

    return this.loading;
  }
}
