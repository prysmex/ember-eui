import {
  euiSplitButtonActionStyles,
  euiSplitButtonDividerStyles,
  euiSplitButtonStyles
} from './styles.generated.ts';

import type { EuiThemeContext } from '../emotion/context.ts';
import type { EuiBorealisContext } from './theme.ts';

/**
 * Upstream's split button factories take a second argument (a background
 * color, a divider color or a size), so `useEuiBorealisStyles` cannot memoize
 * them. Upstream memoizes them per render with `useMemo`; here the result is
 * kept per resolved theme (like `useEuiBorealisStyles`) and argument.
 */
type ArgFactory<A, T> = (theme: EuiBorealisContext, arg: A) => T;
const memo = new WeakMap<
  EuiBorealisContext,
  Map<ArgFactory<never, unknown>, Map<unknown, unknown>>
>();

function memoizedWithArg<A, T>(
  context: EuiThemeContext,
  factory: ArgFactory<A, T>,
  arg: A
): T {
  const theme = context.upstream;
  let byFactory = memo.get(theme);
  if (!byFactory) memo.set(theme, (byFactory = new Map()));
  let byArg = byFactory.get(factory as ArgFactory<never, unknown>);
  if (!byArg)
    byFactory.set(factory as ArgFactory<never, unknown>, (byArg = new Map()));
  if (!byArg.has(arg)) byArg.set(arg, factory(theme, arg));
  return byArg.get(arg) as T;
}

export function splitButtonStyles(
  context: EuiThemeContext,
  backgroundColor: string
) {
  return memoizedWithArg(context, euiSplitButtonStyles, backgroundColor);
}

export function splitButtonActionStyles(
  context: EuiThemeContext,
  size: 'xs' | 's' | 'm'
) {
  return memoizedWithArg(context, euiSplitButtonActionStyles, size);
}

export function splitButtonDividerStyles(
  context: EuiThemeContext,
  color: string
) {
  return memoizedWithArg(context, euiSplitButtonDividerStyles, color);
}
