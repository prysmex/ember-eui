import {
  loadIcons,
  registerIcons as registerLoadedIcons
} from '../-private/icon-loader.ts';

import type { EuiIconComponent } from '../-private/icon-data.ts';
import type { EuiIconType } from '../components/eui-icon.gts';

/**
 * EUI icons are loaded the first time they render, with an empty icon in
 * their place meanwhile. Preload the ones that should show up right away,
 * e.g. in the application route:
 *
 * ```js
 * import { preloadIcons } from '@ember-eui/core/utils/preload-icons';
 *
 * export default class ApplicationRoute extends Route {
 *   async beforeModel() {
 *     await preloadIcons(['chevronSingleDown', 'cross', 'magnify']);
 *   }
 * }
 * ```
 *
 * Resolves once they are all loaded; an icon that fails to load is logged
 * and loaded again the next time it renders.
 */
export function preloadIcons(types: EuiIconType[]): Promise<void> {
  return loadIcons(types);
}

/**
 * Registers EUI icons the app imports itself, so they render right away,
 * without the loading placeholder, the fade-in or a request: e.g. the
 * icons of the first screen, at boot (in `app/app.js`):
 *
 * ```js
 * import { registerIcons } from '@ember-eui/core/utils/preload-icons';
 * import cross from '@ember-eui/core/icons/cross';
 * import search from '@ember-eui/core/icons/search';
 *
 * registerIcons({ cross, search });
 * ```
 *
 * `@ember-eui/core/icons/<type>` exists for every EUI icon type (aliases
 * included), and its default export is that icon's component. Registered
 * icons are bundled with the module that imports them; the others still
 * load the first time they render.
 */
export function registerIcons(
  icons: Partial<Record<EuiIconType, EuiIconComponent>>
): void {
  registerLoadedIcons(icons);
}
