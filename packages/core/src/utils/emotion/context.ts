import { cached } from '@glimmer/tracking';
import { mergeBorealisOverrides, resolveBorealisTheme } from '../eui/theme.ts';
import type {
  EuiBorealisOverrides,
  EuiBorealisHighContrastMode
} from '../eui/theme.ts';
import createEmotion from '@emotion/css/create-instance';
import { defaultTheme, mergeTheme } from './theme.ts';

import type {
  CSSInterpolation,
  Emotion,
  Options
} from '@emotion/css/create-instance';
import type {
  EuiColorMode,
  EuiEmotionTheme,
  EuiThemeOverrides
} from './theme.ts';

export type EuiEmotionCache = Emotion;

/** The caller owns the instance; shared caches must not be flushed by children. */
export function createEuiEmotionCache(
  options: Options = { key: 'eui-spike' }
): EuiEmotionCache {
  return createEmotion(options);
}

export interface EuiThemeSettings {
  colorMode?: EuiColorMode;
  borealisOverrides?: EuiBorealisOverrides;
  highContrastMode?: EuiBorealisHighContrastMode;
  overrides?: EuiThemeOverrides;
  cache?: EuiEmotionCache;
}

/** Explicit context lets Ember autotracking follow provider and parent settings. */
export class EuiThemeContext {
  private fallbackCache?: EuiEmotionCache;

  constructor(
    private settings: () => EuiThemeSettings,
    private parent: () => EuiThemeContext | undefined = () => undefined
  ) {}

  get colorMode(): EuiColorMode {
    return this.settings().colorMode ?? this.parent()?.colorMode ?? 'light';
  }

  get overrides(): EuiThemeOverrides {
    const inherited = this.parent()?.overrides;
    const own = this.settings().overrides;
    return {
      ...inherited,
      ...own,
      colors: { ...inherited?.colors, ...own?.colors }
    };
  }

  get borealisOverrides(): EuiBorealisOverrides {
    return mergeBorealisOverrides(
      this.parent()?.borealisOverrides,
      this.settings().borealisOverrides
    );
  }

  get highContrastMode(): EuiBorealisHighContrastMode {
    return (
      this.settings().highContrastMode ??
      this.parent()?.highContrastMode ??
      false
    );
  }

  @cached
  get upstream() {
    return resolveBorealisTheme(
      this.colorMode,
      this.borealisOverrides,
      this.highContrastMode
    );
  }

  get theme(): EuiEmotionTheme {
    return mergeTheme(defaultTheme(this.colorMode), this.overrides);
  }

  get cache(): EuiEmotionCache {
    const inherited = this.settings().cache ?? this.parent()?.cache;
    if (inherited) return inherited;
    return (this.fallbackCache ??= createEuiEmotionCache());
  }

  /** Only flush a cache this context created, never a supplied or inherited one. */
  destroy() {
    this.fallbackCache?.flush();
    this.fallbackCache = undefined;
  }
}

/** Ordinary tracked reads, without React hook lifecycle or ordering rules. */
export function useEuiTheme(context: EuiThemeContext): EuiEmotionTheme {
  return context.theme;
}

export function useEuiStyles(
  context: EuiThemeContext,
  factory: (theme: EuiEmotionTheme) => CSSInterpolation
): string {
  return context.cache.css(factory(useEuiTheme(context)));
}
