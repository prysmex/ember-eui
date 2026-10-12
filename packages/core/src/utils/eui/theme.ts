import { EuiThemeBorealis } from '@elastic/eui-theme-borealis';
import { buildTheme, getComputed } from '@elastic/eui-theme-common';
import type {
  EuiThemeModifications,
  UseEuiTheme,
  EuiThemeSystem,
  EuiThemeHighContrastMode
} from '@elastic/eui-theme-common';
import type { EuiColorMode } from '../emotion/theme.ts';

export type EuiBorealisHighContrastMode = EuiThemeHighContrastMode;
export type EuiBorealisOverrides = EuiThemeModifications;
export type EuiBorealisContext = UseEuiTheme;
export const EUI_UPSTREAM_VERSIONS = Object.freeze({
  eui: '123.1.0',
  borealis: '8.1.0',
  common: '10.1.0'
});

/**
 * Pure recursive merge. Never mutate provider arguments or upstream defaults.
 * Nested objects are always rebuilt as plain objects: template `(hash)`
 * values have no prototype, and upstream `buildTheme` calls `hasOwnProperty`.
 */
export function mergeBorealisOverrides(
  parent: EuiBorealisOverrides = {},
  own: EuiBorealisOverrides = {}
): EuiBorealisOverrides {
  const isRecord = (value: unknown): value is Record<string, unknown> =>
    !!value && typeof value === 'object' && !Array.isArray(value);
  function merge(
    left: Record<string, unknown>,
    right: Record<string, unknown>
  ): Record<string, unknown> {
    const result: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(left))
      result[key] = isRecord(value) ? merge({}, value) : value;
    for (const [key, value] of Object.entries(right)) {
      if (value === undefined) continue;
      const previous = result[key];
      result[key] = isRecord(value)
        ? merge(isRecord(previous) ? previous : {}, value)
        : value;
    }
    return result;
  }
  return merge(parent, own) as EuiBorealisOverrides;
}

export function resolveBorealisTheme(
  mode: EuiColorMode,
  modifications: EuiBorealisOverrides = {},
  highContrastMode: EuiBorealisHighContrastMode = false
): EuiBorealisContext {
  const colorMode = mode === 'dark' ? 'DARK' : 'LIGHT';
  return {
    euiTheme: getComputed<{}>(
      EuiThemeBorealis,
      buildTheme(
        modifications,
        '_EMBER_EUI_BOREALIS'
      ) as Partial<EuiThemeSystem>,
      colorMode,
      highContrastMode
    ),
    colorMode,
    highContrastMode,
    modifications
  };
}
