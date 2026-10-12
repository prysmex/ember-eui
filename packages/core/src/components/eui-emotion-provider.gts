import type {
  EuiBorealisOverrides,
  EuiBorealisHighContrastMode
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
import { euiClass } from '../utils/eui/styles.ts';

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
    colorMode?: EuiColorMode;
    borealisOverrides?: EuiBorealisOverrides;
    highContrastMode?: EuiBorealisHighContrastMode;
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
    () => this.args.parent ?? getEuiThemeContext(this)
  );

  @provide(EUI_EMOTION_CONTEXT)
  get context() {
    return this.themeContext;
  }

  private globals?: EuiEmotionCache;

  /** Only the outermost provider owns global styles, as upstream. */
  get rendersGlobalStyles() {
    return (
      this.args.globalStyles !== false &&
      !this.args.parent &&
      !getContext(this, EUI_EMOTION_CONTEXT)
    );
  }

  syncGlobalStyles = (
    upstream: EuiBorealisContext,
    enabled: boolean
  ): undefined => {
    if (!enabled) return this.removeGlobalStyles();
    this.globals ??= createEuiEmotionCache({ key: 'eui-global' });
    this.globals.flush();
    // Spread: the parts are template fragments, as in upstream's css(...).
    this.globals.injectGlobal(...euiGlobalStyles(upstream));
  };

  private removeGlobalStyles(): undefined {
    this.globals?.flush();
    this.globals = undefined;
  }

  willDestroy() {
    super.willDestroy();
    this.removeGlobalStyles();
  }

  @cached
  get colorClass() {
    const { colorMode, euiTheme } = this.context.upstream;
    return euiClass(this.context, {
      label: `euiColorMode-${colorMode}`,
      color: euiTheme.colors.textParagraph
    });
  }

  <template>
    {{this.syncGlobalStyles this.context.upstream this.rendersGlobalStyles}}
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
