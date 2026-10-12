import Component from '@glimmer/component';
import { service } from '@ember/service';
import { hash } from '@ember/helper';
import { EuiThemeContext } from '../utils/emotion/context.ts';
import EuiEmotionButton from './eui-emotion-button.gts';

import type EuiEmotionService from '../services/eui-emotion.ts';
import type { EuiEmotionCache } from '../utils/emotion/context.ts';
import type { EuiColorMode, EuiEmotionTheme, EuiThemeOverrides } from '../utils/emotion/theme.ts';
import type { EuiEmotionButtonSignature } from './eui-emotion-button.gts';
import type { ComponentLike } from '@glint/template';

export interface EuiEmotionProviderSignature {
  Args: {
    colorMode?: EuiColorMode;
    overrides?: EuiThemeOverrides;
    parent?: EuiThemeContext;
    cache?: EuiEmotionCache;
  };
  Blocks: {
    default: [{
      context: EuiThemeContext;
      theme: EuiEmotionTheme;
      Button: ComponentLike<EuiEmotionButtonSignature>;
    }];
  };
}

/** Wrapperless, explicit subtree context for the Emotion spike. */
export default class EuiEmotionProvider extends Component<EuiEmotionProviderSignature> {
  @service('eui-emotion') declare defaults: EuiEmotionService;

  readonly context = new EuiThemeContext(
    () => this.args,
    () => this.args.parent ?? this.defaults.context,
  );

  <template>
    {{yield (hash
      context=this.context
      theme=this.context.theme
      Button=(component EuiEmotionButton context=this.context)
    )}}
  </template>
}
