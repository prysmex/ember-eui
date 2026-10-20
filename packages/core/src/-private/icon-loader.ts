import { tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';
import { buildWaiter } from '@ember/test-waiters';

import { typeToPathMap } from '../utils/css-mappings/eui-icon.ts';
import { emptyIcon } from './icon-data.ts';

import type { EuiIconType } from '../components/eui-icon.gts';
import type { EuiIconComponent } from './icon-data.ts';

// `await render()` / `settled()` wait for icons that are still loading
const waiter = buildWaiter('@ember-eui/core:eui-icon');

class LoadingIcon {
  @tracked component?: EuiIconComponent;

  promise: Promise<EuiIconComponent | undefined>;

  constructor(type: EuiIconType, component?: EuiIconComponent) {
    if (component) {
      // registered (registerIcons): no loading, so no placeholder or fade
      this.component = component;
      this.promise = Promise.resolve(component);

      return;
    }

    const token = waiter.beginAsync();

    // the loaders (one import per icon type, ~700) come with the first icon
    // that has to load
    this.promise = import('./icons.ts')
      .then(({ default: iconLoaders }) => iconLoaders[type]())
      .then(
        ({ default: component }) => (this.component = component),
        (error: unknown) => {
          // a later render retries, e.g. after a failed chunk request
          // (unless the app registered the icon meanwhile)
          if (cache.get(type) === this) cache.delete(type);
          console.error(`EuiIcon: could not load the "${type}" icon`, error);

          return undefined;
        }
      )
      .finally(() => waiter.endAsync(token));
  }
}

const cache = new Map<EuiIconType, LoadingIcon>();

function load(type: EuiIconType): LoadingIcon {
  let icon = cache.get(type);

  if (!icon) {
    assert(`"${type}" is not an EUI icon`, Object.prototype.hasOwnProperty.call(typeToPathMap, type));

    icon = new LoadingIcon(type);
    cache.set(type, icon);
  }

  return icon;
}

/**
 * The component for an EUI icon, or undefined while it loads (the first
 * time an icon is rendered). Reading it inside a template or getter
 * re-renders once the icon has loaded.
 */
export function loadedIcon(type: EuiIconType): EuiIconComponent | undefined {
  if (type === 'empty') return emptyIcon;

  return load(type).component;
}

/**
 * Makes icons render at once, from components the app imported
 * (`@ember-eui/core/icons/<type>`), instead of loading them first.
 */
export function registerIcons(
  icons: Partial<Record<EuiIconType, EuiIconComponent>>
): void {
  for (const [type, component] of Object.entries(icons) as [
    EuiIconType,
    EuiIconComponent | undefined
  ][]) {
    assert(
      `"${type}" is not an EUI icon`,
      Object.prototype.hasOwnProperty.call(typeToPathMap, type)
    );

    if (component && !cache.get(type)?.component) {
      cache.set(type, new LoadingIcon(type, component));
    }
  }
}

/** Resolves once every icon has loaded (or failed to). */
export async function loadIcons(types: EuiIconType[]): Promise<void> {
  await Promise.all(types.map((type) => load(type).promise));
}

/** For tests: forget loaded icons so the next render loads them again. */
export function clearIconCache(): void {
  cache.clear();
}
