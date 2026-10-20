import allIcons from '../-private/all-icons.ts';
import { registerIcons } from './preload-icons.ts';

/**
 * Opts out of lazy icons: registers every EUI icon, so none is loaded
 * when it first renders (no placeholder, no fade-in, no request). Importing
 * this module bundles all ~700 icons with the code that imports it, so call
 * it only if your app wants that, e.g. once in `app/app.js`:
 *
 * ```js
 * import { registerAllIcons } from '@ember-eui/core/utils/register-all-icons';
 *
 * registerAllIcons();
 * ```
 *
 * By default (without this), icons load the first time they render; use
 * `registerIcons` from `@ember-eui/core/utils/preload-icons` to bundle only
 * some of them.
 */
export function registerAllIcons(): void {
  registerIcons(allIcons);
}
