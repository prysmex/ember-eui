import { concat } from '@ember/helper';

import { element } from 'ember-element-helper';
import style from 'ember-style-modifier/modifiers/style';
import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import euiPageRestrictWidth from '../helpers/eui-page-restrict-width';
import EuiPanel from './eui-panel.gts';

import type { EuiPanelSignature } from './eui-panel.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPageBodySignature {
  Element: EuiPanelSignature['Element'];
  Args: {
    restrictWidth?: boolean;
    tagName?: string;
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    paddingSize?: 'none' | 's' | 'm' | 'l';
    panelled?: boolean;
    color?: 'subdued' | 'transparent';
    hasBorder?: boolean;
    hasShadow?: boolean;
    style?: Record<string, string>;
  };
  Blocks: {
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
