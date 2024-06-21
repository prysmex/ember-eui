import { concat } from '@ember/helper';

import style from 'ember-style-modifier/modifiers/style';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import euiPageRestrictWidth from '../helpers/eui-page-restrict-width.ts';
import inlineStyles from '../helpers/inline-styles.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPageSignature {
  Element: HTMLDivElement;
  Args: {
    restrictWidth?: boolean;
    paddingSize?: 'none' | 's' | 'm' | 'l';
    grow?: boolean;
    direction?: 'row' | 'column';
    style?: Record<string, string>;
  };
  Blocks: {
    default: [];
  };
}

const EuiPage: TemplateOnlyComponent<EuiPageSignature> = <template>
  {{#let
    (argOrDefault @restrictWidth false)
    (argOrDefault @paddingSize "m")
    (argOrDefault @grow true)
    (argOrDefault @direction "row")
    as |restrictWidth paddingSize grow direction|
  }}
    {{#let (euiPageRestrictWidth restrictWidth @style) as |styling|}}
      <div
        class={{classNames
          (if grow "euiPage--grow")
          (concat "euiPage--" styling.widthClassName)
          componentName="EuiPage"
          paddingSize=paddingSize
          direction=direction
        }}
        ...attributes
        {{style
          (if styling.newStyle (inlineStyles styling.newStyle))
          (inlineStyles min-height="460px;")
        }}
      >
        {{yield}}
      </div>
    {{/let}}
  {{/let}}
</template>;

export default EuiPage;
