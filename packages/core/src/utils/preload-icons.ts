import { loadIcons } from '../-private/icon-loader.ts';

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
 *     await preloadIcons(['arrowDown', 'cross', 'search']);
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
