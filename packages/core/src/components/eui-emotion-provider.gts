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
import { EuiThemeContext } from '../utils/emotion/context.ts';
import EuiEmotionButton from './eui-emotion-button.gts';

import type { EuiEmotionCache } from '../utils/emotion/context.ts';
import type {
  EuiColorMode,
  EuiEmotionTheme,
  EuiThemeOverrides
} from '../utils/emotion/theme.ts';
import type { EuiEmotionButtonSignature } from './eui-emotion-button.gts';
import type { ComponentLike } from '@glint/template';

export interface EuiEmotionProviderSignature {
  Args: {
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

/** Wrapperless provider; descendants consume the nearest theme automatically. */
export default class EuiEmotionProvider extends Component<EuiEmotionProviderSignature> {
  private readonly themeContext = new EuiThemeContext(
    () => this.args,
    () => this.args.parent ?? getEuiThemeContext(this)
  );

  @provide(EUI_EMOTION_CONTEXT)
  get context() {
    return this.themeContext;
  }

  <template>
    {{yield
      (hash
        context=this.context
        theme=this.context.theme
        Button=(component EuiEmotionButton context=this.context)
      )
    }}
  </template>
}
