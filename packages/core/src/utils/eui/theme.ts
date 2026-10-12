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

/** Pure recursive merge. Never mutate provider arguments or upstream defaults. */
export function mergeBorealisOverrides(
  parent: EuiBorealisOverrides = {},
  own: EuiBorealisOverrides = {}
): EuiBorealisOverrides {
  function merge(
    left: Record<string, unknown>,
    right: Record<string, unknown>
  ): Record<string, unknown> {
    const result = { ...left };
    for (const [key, value] of Object.entries(right)) {
      if (value === undefined) continue;
      const previous = left[key];
      result[key] =
        value &&
        typeof value === 'object' &&
        !Array.isArray(value) &&
        previous &&
        typeof previous === 'object' &&
        !Array.isArray(previous)
          ? merge(
              previous as Record<string, unknown>,
              value as Record<string, unknown>
            )
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
