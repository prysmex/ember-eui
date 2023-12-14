import { concat } from '@ember/helper';

import style from 'ember-style-modifier/modifiers/style';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import euiPageRestrictWidth from '../helpers/eui-page-restrict-width';

import type { paddingSizeMapping } from '../utils/css-mappings/eui-page-content-body';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPageContentBodySignature {
  Element: HTMLDivElement;
  Args: {
    restrictWidth?: boolean;
    paddingSize?: keyof typeof paddingSizeMapping;
    style?: {
      [key: string]: string;
    };
  };
  Blocks: {
    default: [];
  };
}

const EuiPageContentBody: TemplateOnlyComponent<EuiPageContentBodySignature> =
  <template>
    {{#let
      (euiPageRestrictWidth (argOrDefault @restrictWidth false) @style)
      as |styling|
    }}
      <div
        class={{classNames
          (concat "euiPage--" styling.widthClassName)
          componentName="EuiPageContentBody"
          paddingSize=@paddingSize
        }}
        {{style styling.newStyle}}
        ...attributes
      >
        {{yield}}
      </div>
    {{/let}}
  </template>;

export default EuiPageContentBody;
