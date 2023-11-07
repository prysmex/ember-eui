import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

import {
  colorMapping,
  paddingSizeMapping,
  borderRadiusMapping
} from '../utils/css-mappings/eui-panel';

import { and, eq, not, or } from 'ember-truth-helpers';

import { on } from '@ember/modifier';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPanelSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Adds a box shadow to the panel
     */
    hasShadow?: boolean;
    /**
     * Adds a border around the panel
     */
    hasBorder?: boolean;
    /**
     * Adds a padding around the panel
     */
    paddingSize?: keyof typeof paddingSizeMapping;
    /**
     * Adds a border radius to the panel
     */
    borderRadius?: keyof typeof borderRadiusMapping;
    /**
     * Adds a background color to the panel
     */
    color?: keyof typeof colorMapping;
    /**
     * Adds a flex-grow: 0 to the panel
     */
    grow?: boolean;
    /**
     * Adds a click handler to the panel
     */
    onClick?: (e: MouseEvent) => void;
    /**
     * Adds a click handler to the panel
     */
    isClickable?: boolean;
  };

  Blocks: {
    default: [];
  };
}

const EuiPanel: TemplateOnlyComponent<EuiPanelSignature> = <template>
  {{#let
    (argOrDefault @hasShadow true)
    (argOrDefault @color "plain")
    (argOrDefault @grow true)
    as |hasShadow color grow|
  }}
    {{#let
      (eq color "plain") (or (eq color "plain") (eq color "transparent"))
      as |canHaveShadow canHaveBorder|
    }}
      {{#if @onClick}}
        <div
          role="button"
          class={{classNames
            (if (argOrDefault @isClickable true) "euiPanel--isClickable")
            (if (and canHaveShadow (eq hasShadow true)) "euiPanel--hasShadow")
            (if
              (and (not canHaveShadow) (eq hasShadow false))
              "euiPanel--noShadow"
            )
            (if (and canHaveBorder (eq @hasBorder true)) "euiPanel--hasBorder")
            (if
              (and (not canHaveBorder) (eq @hasBorder false))
              "euiPanel--noBorder"
            )
            (unless grow "euiPanel--flexGrowZero")
            componentName="EuiPanel"
            paddingSize=(argOrDefault @paddingSize "m")
            borderRadius=(argOrDefault @borderRadius "m")
            color=color
          }}
          {{on "click" @onClick}}
          ...attributes
        >
          {{yield}}
        </div>
      {{else}}
        <div
          class={{classNames
            (if (and canHaveShadow (eq hasShadow true)) "euiPanel--hasShadow")
            (if
              (and (not canHaveShadow) (eq hasShadow false))
              "euiPanel--noShadow"
            )
            (if (and canHaveBorder (eq @hasBorder true)) "euiPanel--hasBorder")
            (if
              (and (not canHaveBorder) (eq @hasBorder false))
              "euiPanel--noBorder"
            )
            (unless grow "euiPanel--flexGrowZero")
            componentName="EuiPanel"
            paddingSize=(argOrDefault @paddingSize "m")
            borderRadius=(argOrDefault @borderRadius "m")
            color=color
          }}
          ...attributes
        >
          {{yield}}
        </div>
      {{/if}}
    {{/let}}
  {{/let}}
</template>;

export default EuiPanel;
