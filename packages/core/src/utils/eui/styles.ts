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
 * Extra styles a caller composes into a migrated component's own class,
 * last — the Ember counterpart of upstream's `css` prop. Use it to style a
 * migrated child instead of adding a second class, whose precedence would
 * depend on rule insertion order.
 */
export type EuiCss = CSSInterpolation;

/** Compose serialized upstream styles into a class in the provider-owned cache. */
export function euiClass(
  context: EuiThemeContext,
  ...styles: CSSInterpolation[]
): string {
  return context.cache.css(styles);
}
