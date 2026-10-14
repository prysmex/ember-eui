import type { CSSInterpolation } from '@emotion/css/create-instance';
import type { EuiThemeContext } from '../emotion/context.ts';
import type { EuiBorealisContext } from './theme.ts';

type Factory = (theme: EuiBorealisContext) => unknown;

/**
 * Factory output per resolved theme. `context.upstream` is `@cached`, so a
 * theme change yields a new object (and a fresh cache) while every consumer
 * of an unchanged theme shares one result. Mirrors upstream's
 * `useEuiMemoizedStyles`.
 */
const memo = new WeakMap<EuiBorealisContext, WeakMap<Factory, unknown>>();

/** Factories receive the real computed upstream theme, without React hooks. */
export function useEuiBorealisStyles<T>(
  context: EuiThemeContext,
  factory: (theme: EuiBorealisContext) => T
): T {
  return memoizedStyles(context.upstream, factory);
}

/** Same memoization for callers that already hold a resolved theme. */
export function memoizedStyles<T>(
  theme: EuiBorealisContext,
  factory: (theme: EuiBorealisContext) => T
): T {
  let byFactory = memo.get(theme);
  if (!byFactory) memo.set(theme, (byFactory = new WeakMap()));
  if (!byFactory.has(factory)) byFactory.set(factory, factory(theme));
  return byFactory.get(factory) as T;
}

/**
 * A theme function: the counterpart of upstream's `css` prop callback,
 * `({ euiTheme, colorMode, highContrastMode }) => styles`. It receives the
 * nearest provider's resolved theme; its result is memoized per resolved
 * theme and function identity, so define it once (module scope or a
 * stable class field), not inline in a getter that re-runs.
 */
export type EuiCssFunction = (theme: EuiBorealisContext) => EuiCss;

/**
 * Extra styles a caller composes into a migrated component's own class,
 * last — the Ember counterpart of upstream's `css` prop. An Emotion
 * interpolation (object, string, serialized styles), a theme function, or
 * an array of those. Use it to style a migrated child instead of adding a
 * second class, whose precedence would depend on rule insertion order.
 *
 * Keep values static: each distinct value adds rules that are never removed
 * (Emotion is append-only, as upstream). Put values that change often
 * (data- or animation-driven positions and sizes, per-item colors) in
 * `style` instead.
 */
export type EuiCss =
  | CSSInterpolation
  | EuiCssFunction
  | readonly EuiCss[];

function hasFunction(style: unknown): boolean {
  if (typeof style === 'function') return true;
  return Array.isArray(style) && style.some(hasFunction);
}

function resolveCss(
  theme: EuiBorealisContext,
  style: EuiCss
): CSSInterpolation {
  if (typeof style === 'function')
    return resolveCss(theme, memoizedStyles(theme, style));
  if (Array.isArray(style) && style.some(hasFunction))
    return (style as readonly EuiCss[]).map((s) => resolveCss(theme, s));
  return style as CSSInterpolation;
}

/**
 * Resolve theme functions in `@css`-style values against a context's
 * theme. Only reads `context.upstream` (a tracked dependency) when a
 * function is present.
 */
export function resolveEuiCss(
  context: EuiThemeContext,
  style: EuiCss
): CSSInterpolation {
  return hasFunction(style) ? resolveCss(context.upstream, style) : (style as CSSInterpolation);
}

/**
 * Compose serialized upstream styles into a class in the provider-owned
 * cache. Theme functions anywhere in `styles` (e.g. a caller's `@css`) are
 * resolved here against the context's theme, so every component that
 * composes `@css` through `euiClass` supports them.
 */
export function euiClass(context: EuiThemeContext, ...styles: EuiCss[]): string {
  return context.cache.css(resolveEuiCss(context, styles));
}
