import type { CSSInterpolation } from '@emotion/css/create-instance';
import type { EuiThemeContext } from '../emotion/context.ts';
import type { EuiBorealisContext } from './theme.ts';

/** Factories receive the real computed upstream theme, without React hooks. */
export function useEuiBorealisStyles<T>(
  context: EuiThemeContext,
  factory: (theme: EuiBorealisContext) => T
): T {
  return factory(context.upstream);
}

/** Compose serialized upstream styles into a class in the provider-owned cache. */
export function euiClass(
  context: EuiThemeContext,
  ...styles: CSSInterpolation[]
): string {
  return context.cache.css(styles);
}
