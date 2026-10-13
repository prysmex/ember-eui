import type {
  EuiBorealisOverrides,
  EuiHighContrastModeArg
} from '../utils/eui/theme.ts';
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { getContext, provide } from 'ember-provide-consume-context';
import {
  EUI_EMOTION_CONTEXT,
  getEuiThemeContext
} from '../utils/emotion/consume.ts';
import { hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import {
  EuiThemeContext,
  createEuiEmotionCache
} from '../utils/emotion/context.ts';
import { euiGlobalStyles } from '../utils/eui/global-styles.ts';
import EuiEmotionButton from './eui-emotion-button.gts';
import { euiClass, memoizedStyles } from '../utils/eui/styles.ts';
import { euiThemeCssVariables } from '../utils/eui/css-variables.ts';
import { EuiSystemPreferences } from '../utils/emotion/system.ts';

import type { EuiEmotionCache } from '../utils/emotion/context.ts';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';
import type {
  EuiColorMode,
  EuiEmotionTheme,
  EuiThemeOverrides
} from '../utils/emotion/theme.ts';
import type { EuiEmotionButtonSignature } from './eui-emotion-button.gts';
import type { ComponentLike } from '@glint/template';

export interface EuiEmotionProviderSignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * Wrap the content in a `<span class="euiThemeProvider">` that sets the
     * resolved paragraph color, as upstream's nested EuiThemeProvider does,
     * so inherited text follows this provider's mode. Defaults to `true`.
     * Pass `false` where an extra element would break layout (e.g. a
     * provider directly inside a flex or grid container); attributes are
     * forwarded to the span.
     */
    wrapper?: boolean;
    /**
     * Like upstream EuiProvider's `globalStyles`: the outermost provider
     * injects EUI's global reset and root typography (root font size 14px
     * in Borealis, which upstream `rem` sizes are relative to) while it is
     * rendered, and removes them when torn down. Nested providers never
     * do. Pass `false` on pages that still rely on legacy EUI CSS, or when
     * the host app owns its global styles. Defaults to `true`.
     */
    globalStyles?: boolean;
    /**
     * `"light"` or `"dark"`. Nested providers inherit their parent's. Like
     * upstream EuiProvider, a root provider (no parent provider) left
     * undefined follows the OS `prefers-color-scheme` (or the
     * `eui-emotion` service's `colorMode` when set). An OS-forced high
     * contrast (`forced-colors: active`) supersedes it.
     */
    colorMode?: EuiColorMode;
    borealisOverrides?: EuiBorealisOverrides;
    /**
     * Like upstream: `true` (or `"preferred"`) enables high contrast,
     * `false` overrides the parent/system preference, `"forced"` forces it.
     * Undefined inherits; a root provider then follows the OS
     * (`prefers-contrast: more` → `"preferred"`, Windows
     * `forced-colors: active` → `"forced"`, which supersedes every app
     * setting, including `@colorMode`).
     */
    highContrastMode?: EuiHighContrastModeArg;
    overrides?: EuiThemeOverrides;
    parent?: EuiThemeContext;
    cache?: EuiEmotionCache;
  };
  Blocks: {
    default: [
      {
        context: EuiThemeContext;
        theme: EuiEmotionTheme;
        Button: ComponentLike<EuiEmotionButtonSignature>;
      }
    ];
  };
}

/** Descendants consume the nearest theme automatically; see `@wrapper`. */
export default class EuiEmotionProvider extends Component<EuiEmotionProviderSignature> {
  private readonly themeContext = new EuiThemeContext(
    () => this.args,
    () =>
      this.args.parent ??
      getContext(this, EUI_EMOTION_CONTEXT) ??
      this.systemContext()
  );

  private system?: EuiSystemPreferences;
  private rootParent?: EuiThemeContext;

  /**
   * A root provider's parent: upstream's `EuiSystemDefaultsProvider`. OS
   * preferences fill what the `eui-emotion` service leaves unset; the
   * service still supplies overrides and the default cache.
   */
  private systemContext(): EuiThemeContext {
    if (!this.rootParent) {
      const defaults = getEuiThemeContext(this);
      const system = (this.system = new EuiSystemPreferences());
      this.rootParent = new EuiThemeContext(() => {
        const own = defaults.settings();
        return {
          colorMode: own.colorMode ?? system.colorMode,
          highContrastMode:
            system.highContrastMode === 'forced'
              ? 'forced'
              : (own.highContrastMode ?? system.highContrastMode)
        };
      }, () => defaults);
    }
    return this.rootParent;
  }

  @provide(EUI_EMOTION_CONTEXT)
  get context() {
    return this.themeContext;
  }

  private globals?: EuiEmotionCache;

  /** The outermost provider: no parent provider and no `@parent`. */
  get isRoot() {
    return !this.args.parent && !getContext(this, EUI_EMOTION_CONTEXT);
  }

  /** Only the outermost provider owns global styles, as upstream. */
  get rendersGlobalStyles() {
    return this.args.globalStyles !== false && this.isRoot;
  }

  /**
   * The root provider owns the page-level styles: upstream's global styles
   * (unless `@globalStyles={{false}}`) in the `eui-global` cache, and the
   * theme's CSS variables on `:root` (see `utils/eui/css-variables.ts`) in
   * the `eui-vars` cache, re-injected when the theme changes. Variables are
   * published even without global styles: they style nothing by
   * themselves.
   */
  syncGlobalStyles = (
    upstream: EuiBorealisContext,
    isRoot: boolean,
    globalStyles: boolean
  ): undefined => {
    if (!isRoot) {
      this.removeGlobalStyles();
      return this.removeCssVariables();
    }
    if (globalStyles) {
      this.globals ??= createEuiEmotionCache({ key: 'eui-global' });
      this.globals.flush();
      // Spread: the parts are template fragments, as in upstream's css(...).
      this.globals.injectGlobal(...euiGlobalStyles(upstream));
    } else {
      this.removeGlobalStyles();
    }
    this.variables ??= createEuiEmotionCache({ key: 'eui-vars' });
    this.variables.flush();
    this.variables.injectGlobal({
      ':root': memoizedStyles(upstream, euiThemeCssVariables)
    });
  };

  private variables?: EuiEmotionCache;

  private removeGlobalStyles(): undefined {
    this.globals?.flush();
    this.globals = undefined;
  }

  private removeCssVariables(): undefined {
    this.variables?.flush();
    this.variables = undefined;
  }

  willDestroy() {
    super.willDestroy();
    this.removeGlobalStyles();
    this.removeCssVariables();
    this.system?.destroy();
  }

  /**
   * A nested provider whose theme differs from its parent's (own
   * overrides, or a different color/contrast mode) scopes the theme CSS
   * variables on its wrapper; otherwise they are inherited from `:root`.
   */
  get scopesCssVariables(): boolean {
    if (this.isRoot) return false;
    const parent = this.args.parent ?? getEuiThemeContext(this);
    const overrides = this.args.borealisOverrides;
    return (
      (!!overrides && Object.keys(overrides).length > 0) ||
      this.context.colorMode !== parent.colorMode ||
      this.context.highContrastMode !== parent.highContrastMode
    );
  }

  @cached
  get colorClass() {
    const upstream = this.context.upstream;
    const { colorMode, euiTheme } = upstream;
    return euiClass(this.context, {
      label: `euiColorMode-${colorMode}`,
      color: euiTheme.colors.textParagraph,
      ...(this.scopesCssVariables
        ? memoizedStyles(upstream, euiThemeCssVariables)
        : undefined)
    });
  }

  <template>
    {{this.syncGlobalStyles
      this.context.upstream
      this.isRoot
      this.rendersGlobalStyles
    }}
    {{#if (if (eq @wrapper undefined) true @wrapper)}}
      <span class="euiThemeProvider {{this.colorClass}}" ...attributes>
        {{yield
          (hash
            context=this.context
            theme=this.context.theme
            Button=(component EuiEmotionButton context=this.context)
          )
        }}
      </span>
    {{else}}
      {{yield
        (hash
          context=this.context
          theme=this.context.theme
          Button=(component EuiEmotionButton context=this.context)
        )
      }}
    {{/if}}
  </template>
}
