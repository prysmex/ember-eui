import type {
  EuiBorealisOverrides,
  EuiBorealisHighContrastMode
} from '../utils/eui/theme.ts';
import Component from '@glimmer/component';
import { provide } from 'ember-provide-consume-context';
import {
  EUI_EMOTION_CONTEXT,
  getEuiThemeContext
} from '../utils/emotion/consume.ts';
import { hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiThemeContext } from '../utils/emotion/context.ts';
import EuiEmotionButton from './eui-emotion-button.gts';
import { euiClass } from '../utils/eui/styles.ts';

import type { EuiEmotionCache } from '../utils/emotion/context.ts';
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

  get colorClass() {
    const { colorMode, euiTheme } = this.context.upstream;
    return euiClass(this.context, {
      label: `euiColorMode-${colorMode}`,
      color: euiTheme.colors.textParagraph
    });
  }

  <template>
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
