import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import { and, eq, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type {
  borderRadiusMapping,
  colorMapping,
  paddingSizeMapping} from '../utils/css-mappings/eui-panel.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A box grouping content, with background, padding, border and shadow options. */
export interface EuiPanelSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Adds a box shadow (plain panels only). Defaults to `true`.
     */
    hasShadow?: boolean;
    /**
     * Adds a border (plain and transparent panels only).
     */
    hasBorder?: boolean;
    /**
     * Padding: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`.
     */
    paddingSize?: keyof typeof paddingSizeMapping;
    /**
     * `'none'` or `'m'`. Defaults to `'m'`.
     */
    borderRadius?: keyof typeof borderRadiusMapping;
    /**
     * Background: `'plain'`, `'transparent'`, `'subdued'`, `'accent'`,
     * `'primary'`, `'success'`, `'warning'` or `'danger'`.
     * Defaults to `'plain'`.
     */
    color?: keyof typeof colorMapping;
    /**
     * Grows to fill a flex parent's height. Defaults to `true`.
     */
    grow?: boolean;
    /**
     * Makes the whole panel clickable (hover styles, `role="button"`,
     * focusable, Enter and Space activate it).
     */
    onClick?: (e: MouseEvent) => void;
    /**
     * Hover styles for a clickable panel. Defaults to `true`.
     */
    isClickable?: boolean;
  };

  Blocks: {
    /** The panel's content. */
    default: [];
  };
}

/**
 * Enter and Space activate a clickable panel, like a native button. Keys
 * pressed in controls inside the panel are left alone.
 */
function activateOnKey(
  onClick: (e: MouseEvent) => void,
  event: KeyboardEvent
): void {
  if (event.target !== event.currentTarget) return;

  if (event.key === 'Enter' || event.key === ' ') {
    // Space would otherwise scroll the page
    event.preventDefault();
    onClick(event as unknown as MouseEvent);
  }
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
          tabindex="0"
          {{on "click" @onClick}}
          {{on "keydown" (fn activateOnKey @onClick)}}
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
