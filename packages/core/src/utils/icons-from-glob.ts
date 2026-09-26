import { assert } from '@ember/debug';

import type { EuiIconComponent } from '../-private/icons.ts';

export interface IconsFromGlobOptions {
  /**
   * Prepended to every icon name: `prefix: 'app-'` + `logo.svg` -> `app-logo`.
   */
  prefix?: string;

  /**
   * Custom naming. Receives the path as returned by `import.meta.glob`.
   * Defaults to the file name without extension, like ember-svg-jar's
   * `stripPath` default: `../icons/brands/logo.svg` -> `logo`.
   */
  name?: (path: string) => string;
}

function fileName(path: string): string {
  const base = path.slice(path.lastIndexOf('/') + 1);
  const dot = base.lastIndexOf('.');

  return dot > 0 ? base.slice(0, dot) : base;
}

/**
 * Turns the result of an eager `import.meta.glob` of svg files (imported
 * as components, e.g. with @svg-jar/plugin) into the name -> component
 * map expected by the `euiIcon.icons` config, so a whole folder of icons
 * can be registered at once:
 *
 * ```js
 * import { iconsFromGlob } from '@ember-eui/core/utils/icons-from-glob';
 *
 * euiConfig.updateConfig({
 *   'euiIcon.icons': iconsFromGlob(
 *     import.meta.glob('../icons/**\/*.svg', { eager: true })
 *   ),
 * });
 * ```
 *
 * ```hbs
 * <EuiIcon @type="logo" />
 * ```
 *
 * The glob must be `{ eager: true }` (lazy globs return loader functions,
 * which cannot be told apart from components). Both module namespaces and
 * `{ import: 'default' }` results are accepted.
 */
export function iconsFromGlob(
  modules: Record<string, unknown>,
  options: IconsFromGlobOptions = {}
): Record<string, EuiIconComponent> {
  const { prefix = '', name = fileName } = options;
  const icons: Record<string, EuiIconComponent> = {};
  const sources: Record<string, string> = {};

  for (const [path, module] of Object.entries(modules)) {
    const component =
      module && typeof module === 'object' && 'default' in module
        ? (module as { default: unknown }).default
        : module;

    assert(
      `iconsFromGlob: "${path}" is not a component. Pass an eager glob of svgs imported as components, e.g. import.meta.glob('./icons/*.svg', { eager: true }) with @svg-jar/plugin configured with target 'ember'.`,
      component !== null &&
        (typeof component === 'object' || typeof component === 'function')
    );

    const iconName = `${prefix}${name(path)}`;

    assert(
      `iconsFromGlob: "${sources[iconName]}" and "${path}" both map to the icon name "${iconName}". Rename one of them or pass a \`name\` function.`,
      !(iconName in icons)
    );

    icons[iconName] = component as EuiIconComponent;
    sources[iconName] = path;
  }

  return icons;
}
