import { cached } from '@glimmer/tracking';
import { mergeBorealisOverrides, resolveBorealisTheme } from '../eui/theme.ts';
import type {
  EuiBorealisOverrides,
  EuiBorealisHighContrastMode,
  EuiHighContrastModeArg
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
  highContrastMode?: EuiHighContrastModeArg;
  overrides?: EuiThemeOverrides;
  cache?: EuiEmotionCache;
}

/** Explicit context lets Ember autotracking follow provider and parent settings. */
export class EuiThemeContext {
  private fallbackCache?: EuiEmotionCache;

  constructor(
    /** The context's own (unresolved) settings; `undefined` inherits. */
    readonly settings: () => EuiThemeSettings,
    private parent: () => EuiThemeContext | undefined = () => undefined
  ) {}

  /**
   * Set on the contexts that are not providers: the `eui-emotion` service's
   * defaults and a root provider's system (OS) defaults.
   */
  isSystem = false;

  /**
   * The outermost provider's context (upstream's global theme), or this
   * context when no provider is rendered.
   */
  get root(): EuiThemeContext {
    const parent = this.parent();
    return !parent || parent.isSystem ? this : parent.root;
  }

  /**
   * As upstream `getColorMode`: an OS-forced high contrast (`'forced'` from
   * the parent) supersedes the app's color mode, so the parent's (the
   * system's, at the root) mode wins.
   */
  get colorMode(): EuiColorMode {
    const parent = this.parent();
    if (parent?.highContrastMode === 'forced') return parent.colorMode;
    return this.settings().colorMode ?? parent?.colorMode ?? 'light';
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

  /**
   * As upstream EuiThemeProvider: a forced parent always wins, `true` means
   * `'preferred'`, `false` overrides the parent/system preference, and
   * `undefined` inherits it.
   */
  get highContrastMode(): EuiBorealisHighContrastMode {
    const inherited = this.parent()?.highContrastMode ?? false;
    if (inherited === 'forced') return 'forced';
    const own = this.settings().highContrastMode;
    if (own === true) return 'preferred';
    if (own === undefined) return inherited;
    return own;
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
