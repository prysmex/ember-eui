/**
 * The barcode scan panel, loaded on first use (readiness item 1): an app
 * whose sheet never opens an editor that can scan does not load it. As
 * core's markdown engine: `settled()` waits for it while it loads.
 */
import { tracked } from '@glimmer/tracking';
import { buildWaiter } from '@ember/test-waiters';

import type BarcodeScanPanel from './barcode-scan-panel.gts';

const waiter = buildWaiter('@ember-eui/sheet:barcode-scan');

class Loader {
  @tracked panel?: typeof BarcodeScanPanel;
  promise?: Promise<void>;

  load(): Promise<void> {
    if (!this.promise) {
      const token = waiter.beginAsync();
      this.promise = import('./barcode-scan-panel.gts')
        .then(
          (module) => {
            this.panel = module.default;
          },
          (error: unknown) => {
            // a later open retries, e.g. after a failed chunk request
            this.promise = undefined;
            console.error('EuiSheet: could not load the scan panel', error);
          }
        )
        .finally(() => waiter.endAsync(token));
    }
    return this.promise;
  }
}

const loader = new Loader();

/**
 * The scan panel once it has loaded (the first call starts loading it),
 * `undefined` until then. Read in a template, it renders once loaded.
 */
export function barcodeScanPanel(): typeof BarcodeScanPanel | undefined {
  void loader.load();
  return loader.panel;
}

/** Starts loading the scan panel (an editor that can scan opened). */
export function loadBarcodeScanPanel(): Promise<void> {
  return loader.load();
}
