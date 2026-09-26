import { concat } from '@ember/helper';

import { element } from 'ember-element-helper';
import style from 'ember-style-modifier/modifiers/style';
import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import euiPageRestrictWidth from '../helpers/eui-page-restrict-width.ts';
import EuiPanel from './eui-panel.gts';

import type { EuiPanelSignature } from './eui-panel';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The main column of an EuiPage: header, content and so on. */
export interface EuiPageBodySignature {
  Element: EuiPanelSignature['Element'];
  Args: {
    /**
     * Max width of the content: `true` for EUI's default (1000px), a
     * number in px, or any CSS width. Defaults to `false` (no limit).
     */
    restrictWidth?: boolean | number | string;
    /** Tag of the body (without `@panelled`). Defaults to `'div'`. */
    tagName?: string;
    /** Border radius of the panel: `'none'` or `'m'`. Defaults to `'none'`. */
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    /**
     * Padding: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'l'` when
     * `@panelled`, `'none'` otherwise.
     */
    paddingSize?: 'none' | 's' | 'm' | 'l';
    /** Renders the body as an `EuiPanel` (white background with padding). */
    panelled?: boolean;
    /** Panel background: `'subdued'` or `'transparent'`. */
    color?: 'subdued' | 'transparent';
    /** Adds a border to the panel. */
    hasBorder?: boolean;
    /** Adds a shadow to the panel. */
    hasShadow?: boolean;
    /** Inline styles, merged with the max width. */
    style?: Record<string, string>;
  };
  Blocks: {
    /** Usually an `EuiPageHeader` and `EuiPageContent`. */
    default: [];
  };
}

const EuiPageBody: TemplateOnlyComponent<EuiPageBodySignature> = <template>
  {{#let
    (argOrDefault @restrictWidth false)
    (argOrDefault @tagName "div")
    (argOrDefault @borderRadius "none")
    (argOrDefault @paddingSize (if @panelled "l" "none"))
    as |restrictWidth tagName borderRadius paddingSize|
  }}

    {{#let (euiPageRestrictWidth restrictWidth @style) as |styling|}}
      {{#if @panelled}}
        <EuiPanel
          class={{classNames
            (if (eq borderRadius "none") "euiPageBody--borderRadiusNone")
            (if
              styling.widthClassName
              (concat "euiPageBody--" styling.widthClassName)
            )
            componentName="EuiPageBody"
            paddingSize=@paddingSize
          }}
          @paddingSize={{paddingSize}}
          @borderRadius={{borderRadius}}
          @color={{@color}}
          @hasBorder={{@hasBorder}}
          @hasShadow={{@hasShadow}}
          {{style styling.newStyle}}
          ...attributes
        >
          {{yield}}
        </EuiPanel>
      {{else}}
        {{#let (element tagName) as |Tag|}}
          <Tag
            class={{classNames
              (if (eq borderRadius "none") "euiPageBody--borderRadiusNone")
              (if
                styling.widthClassName
                (concat "euiPageBody--" styling.widthClassName)
              )
              componentName="EuiPageBody"
              paddingSize=@paddingSize
            }}
            {{style styling.newStyle}}
            {{!@glint-expect-error}}
            ...attributes
          >
            {{yield}}
          </Tag>
        {{/let}}
      {{/if}}
    {{/let}}
  {{/let}}
</template>;

export default EuiPageBody;
