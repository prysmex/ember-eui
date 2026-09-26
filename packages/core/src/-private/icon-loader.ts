import { tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';
import { buildWaiter } from '@ember/test-waiters';

import iconLoaders, { emptyIcon } from './icons.ts';

import type { EuiIconType } from '../components/eui-icon.gts';
import type { EuiIconComponent } from './icons.ts';

// `await render()` / `settled()` wait for icons that are still loading
const waiter = buildWaiter('@ember-eui/core:eui-icon');

class LoadingIcon {
  @tracked component?: EuiIconComponent;

  promise: Promise<EuiIconComponent | undefined>;

  constructor(type: EuiIconType) {
    const token = waiter.beginAsync();

    this.promise = iconLoaders[type]()
      .then(
        ({ default: component }) => (this.component = component),
        (error: unknown) => {
          // a later render retries, e.g. after a failed chunk request
          cache.delete(type);
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
    assert(`"${type}" is not an EUI icon`, Object.prototype.hasOwnProperty.call(iconLoaders, type));

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

/** Resolves once every icon has loaded (or failed to). */
export async function loadIcons(types: EuiIconType[]): Promise<void> {
  await Promise.all(types.map((type) => load(type).promise));
}

/** For tests: forget loaded icons so the next render loads them again. */
export function clearIconCache(): void {
  cache.clear();
}
