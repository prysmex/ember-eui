import { concat } from '@ember/helper';

import style from 'ember-style-modifier/modifiers/style';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import euiPageRestrictWidth from '../helpers/eui-page-restrict-width.ts';

import type { paddingSizeMapping } from '../utils/css-mappings/eui-page-content-body.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The content of an EuiPageContent. */
export interface EuiPageContentBodySignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Max width of the content: `true` for EUI's default (1000px), a
     * number in px, or any CSS width. Defaults to `false` (no limit).
     */
    restrictWidth?: boolean | number | string;
    /** Padding: `'none'`, `'s'`, `'m'` or `'l'`. */
    paddingSize?: keyof typeof paddingSizeMapping;
    /** Inline styles, merged with the max width. */
    style?: {
      [key: string]: string;
    };
  };
  Blocks: {
    /** The content. */
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
          (if styling.widthClassName (concat "euiPage--" styling.widthClassName))
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
