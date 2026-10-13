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
/**
 * What `@highContrastMode` accepts: upstream's boolean prop (`true` is
 * `'preferred'`, `false` opts out of the system preference) plus the
 * resolved modes themselves.
 */
export type EuiHighContrastModeArg = boolean | EuiThemeHighContrastMode;
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

/*
 * `euiHighContrastModifications` is ported from @elastic/eui 123.1.0
 * `services/theme/high_contrast_overrides.js` (`useHighContrastModifications`,
 * without the React memo hooks).
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 * Parity with upstream is checked in scripts/eui-upstream-parity.test.mjs.
 */
const systemThemes = new Map<'LIGHT' | 'DARK', UseEuiTheme['euiTheme']>();

/**
 * Upstream applies high contrast by modifying the theme: every border token
 * becomes the matching text color (or plain dark/light), so consumer border
 * overrides are replaced too.
 */
export function euiHighContrastModifications(
  colorMode: 'LIGHT' | 'DARK',
  modifications: EuiBorealisOverrides = {}
): EuiBorealisOverrides {
  const system = EuiThemeBorealis;
  const borderColor =
    colorMode === 'DARK'
      ? system.root.colors.plainLight
      : system.root.colors.plainDark;
  const getBorderWidth = (width: 'thin' | 'thick') =>
    String(
      modifications?.border?.width?.[width] || system.root.border.width[width]
    );
  let systemTheme = systemThemes.get(colorMode);
  if (!systemTheme)
    systemThemes.set(
      colorMode,
      (systemTheme = getComputed(system as never, {}, colorMode) as never)
    );
  const colors = systemTheme.colors;
  const borderColorModifications = {
    borderBasePrimary: colors.textPrimary,
    borderBaseAccent: colors.textAccent,
    borderBaseAccentSecondary: colors.textAccentSecondary,
    borderBaseNeutral: colors.textNeutral,
    borderBaseSuccess: colors.textSuccess,
    borderBaseWarning: colors.textWarning,
    borderBaseRisk: colors.textRisk,
    borderBaseDanger: colors.textDanger,
    borderBasePlain: borderColor,
    borderBaseSubdued: borderColor,
    borderBaseProminent: borderColor,
    borderBaseDisabled: colors.textDisabled,
    borderBaseFloating: borderColor,
    borderStrongPrimary: colors.textPrimary,
    borderStrongAccent: colors.textAccent,
    borderStrongAccentSecondary: colors.textAccentSecondary,
    borderStrongNeutral: colors.textNeutral,
    borderStrongSuccess: colors.textSuccess,
    borderStrongWarning: colors.textWarning,
    borderStrongRisk: colors.textRisk,
    borderStrongDanger: colors.textDanger
  };
  return {
    colors: {
      LIGHT: { ...borderColorModifications },
      DARK: { ...borderColorModifications }
    },
    border: {
      color: borderColor,
      thin: `${getBorderWidth('thin')} solid ${borderColor}`,
      thick: `${getBorderWidth('thick')} solid ${borderColor}`
    }
  } as EuiBorealisOverrides;
}

export function resolveBorealisTheme(
  mode: EuiColorMode,
  modifications: EuiBorealisOverrides = {},
  highContrastMode: EuiBorealisHighContrastMode = false
): EuiBorealisContext {
  const colorMode = mode === 'dark' ? 'DARK' : 'LIGHT';
  // Upstream spreads the high contrast modifications over the consumer's
  // shallowly, which drops consumer `colors`/`border` overrides entirely in
  // high contrast; a deep merge keeps brand colors while the high contrast
  // border tokens still win.
  const effective = highContrastMode
    ? mergeBorealisOverrides(
        modifications,
        euiHighContrastModifications(colorMode, modifications)
      )
    : modifications;
  return {
    euiTheme: getComputed<{}>(
      EuiThemeBorealis,
      buildTheme(effective, '_EMBER_EUI_BOREALIS') as Partial<EuiThemeSystem>,
      colorMode,
      highContrastMode
    ),
    colorMode,
    highContrastMode,
    modifications
  };
}
