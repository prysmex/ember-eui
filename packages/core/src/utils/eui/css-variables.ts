import { euiFontSize } from './styles.generated.ts';

import type { EuiBorealisContext } from './theme.ts';

/**
 * Theme tokens as CSS custom properties, so plain app CSS can follow the
 * nearest provider's color mode, high contrast mode and overrides.
 *
 * Upstream EUI 123.1.0 has no token-level CSS variables (only per-component
 * ones such as `--euiFixedHeadersOffset`), so the names are Ember EUI's own,
 * derived deterministically from the token path:
 *
 * - `--eui-` + the path segments in kebab case joined by `-`;
 * - the `colors` group is singular: `colors.textSubdued` →
 *   `--eui-color-text-subdued`, `colors.severity.danger` →
 *   `--eui-color-severity-danger`;
 * - `size.s` → `--eui-size-s`, `border.radius.medium` →
 *   `--eui-border-radius-medium`, `font.familyCode` → `--eui-font-family-code`;
 * - font sizes are computed like upstream `euiFontSize(theme, scale)`:
 *   `--eui-font-size-s`, `--eui-line-height-s` (rem, relative to the root
 *   font size the root provider sets).
 *
 * Published groups: every string color (plus `colors.severity`; `colors.vis`
 * is left out), `size`, `border`, `font` families/feature settings/weights,
 * the font size scale, `focus` color/width and `animation`.
 */
export type EuiCssVariables = Record<string, string>;

const FONT_SCALES = ['xxxs', 'xxs', 'xs', 's', 'm', 'l', 'xl', 'xxl'] as const;

const kebab = (segment: string) =>
  segment.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();

/** `'colors.textSubdued'` → `'--eui-color-text-subdued'`. */
export function euiCssVariableName(path: string): string {
  const [group, ...rest] = path.split('.');
  const head = group === 'colors' ? 'color' : group!;
  return `--eui-${[head, ...rest].map(kebab).join('-')}`;
}

/**
 * `var(--eui-…)` for a token path, e.g. `euiCssVar('colors.textSubdued')`.
 * Usable in JS style objects and, as a plain function helper, in templates.
 */
export function euiCssVar(path: string, fallback?: string): string {
  const name = euiCssVariableName(path);
  return fallback === undefined ? `var(${name})` : `var(${name}, ${fallback})`;
}

function addLeaves(
  out: EuiCssVariables,
  path: string,
  value: unknown,
  accept: (value: unknown) => boolean = (v) =>
    typeof v === 'string' || typeof v === 'number'
) {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    for (const [key, child] of Object.entries(value))
      addLeaves(out, `${path}.${key}`, child, accept);
  } else if (accept(value)) {
    out[euiCssVariableName(path)] = String(value);
  }
}

/** The variables for one resolved theme; memoize with `memoizedStyles`. */
export function euiThemeCssVariables({
  euiTheme
}: EuiBorealisContext): EuiCssVariables {
  const out: EuiCssVariables = {};
  const theme = euiTheme as unknown as {
    colors: Record<string, unknown>;
    size: unknown;
    border: unknown;
    font: Record<string, unknown> & { weight: unknown };
    focus: { color: unknown; width: unknown };
    animation: unknown;
  };
  for (const [key, value] of Object.entries(theme.colors)) {
    if (key === 'vis') continue;
    addLeaves(out, `colors.${key}`, value, (v) => typeof v === 'string');
  }
  addLeaves(out, 'size', theme.size);
  addLeaves(out, 'border', theme.border);
  const font = theme.font;
  for (const key of ['family', 'familyCode', 'familySerif', 'featureSettings'])
    addLeaves(out, `font.${key}`, font[key]);
  addLeaves(out, 'font.weight', font.weight);
  for (const scale of FONT_SCALES) {
    const { fontSize, lineHeight } = euiFontSize(
      { euiTheme } as never,
      scale,
      undefined as never
    ) as { fontSize: string; lineHeight: string };
    out[`--eui-font-size-${scale}`] = fontSize;
    out[`--eui-line-height-${scale}`] = lineHeight;
  }
  const focus = theme.focus;
  addLeaves(out, 'focus.color', focus.color);
  addLeaves(out, 'focus.width', focus.width);
  addLeaves(out, 'animation', theme.animation);
  return out;
}
