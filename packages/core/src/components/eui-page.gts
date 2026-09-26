import { concat } from '@ember/helper';

import style from 'ember-style-modifier/modifiers/style';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import euiPageRestrictWidth from '../helpers/eui-page-restrict-width.ts';
import inlineStyles from '../helpers/inline-styles.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The outermost layout of a page: holds an optional `EuiPageSideBar` and an `EuiPageBody`. See also EuiPageTemplate. */
export interface EuiPageSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Max width of the content: `true` for EUI's default (1000px), a
     * number in px, or any CSS width. Defaults to `false` (no limit).
     */
    restrictWidth?: boolean | number | string;
    /** Padding around the page: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`. */
    paddingSize?: 'none' | 's' | 'm' | 'l';
    /** Fills the window's height. Defaults to `true`. */
    grow?: boolean;
    /**
     * `'row'` puts an `EuiPageSideBar` beside the body, `'column'` stacks
     * them. Defaults to `'row'`.
     */
    direction?: 'row' | 'column';
    /** Inline styles, merged with the max width. */
    style?: Record<string, string>;
  };
  Blocks: {
    /** `EuiPageSideBar` and `EuiPageBody`. */
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
          (if styling.widthClassName (concat "euiPage--" styling.widthClassName))
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
