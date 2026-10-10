import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiPanel from './eui-panel.gts';

import type { EuiPanelSignature } from './eui-panel';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A panel holding the page's main content, inside EuiPageBody. */
export interface EuiPageContentSignature {
  Element: HTMLDivElement;
  Args: {
    /** `role` of the content. Defaults to `'main'`; pass `null` for none. */
    role?: string | null;
    /** Vertically centers (`'center'`) or bottom-aligns the content panel. */
    verticalPosition?: 'center' | 'bottom';
    /** Horizontally centers the content panel (e.g. an empty prompt). */
    horizontalPosition?: 'center';
    /** Adds a shadow. */
    hasShadow?: boolean;
    /** Adds a border. */
    hasBorder?: boolean;
    /** Padding, any `EuiPanel` padding size. Defaults to `'l'`. */
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
    /** Border radius: `'none'` or `'m'`. */
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    /** Background, any `EuiPanel` color. */
    color?: EuiPanelSignature['Args']['color'];
    /** Fills the remaining height. */
    grow?: boolean;
  };
  Blocks: {
    /** `EuiPageContentHeader` and `EuiPageContentBody`, or any content. */
    default: [];
  };
}

const EuiPageContent: TemplateOnlyComponent<EuiPageContentSignature> =
  <template>
    {{#let (argOrDefault @role "main") as |role|}}
      <EuiPanel
        role={{if (eq role null) undefined role}}
        class={{classNames
          (if (eq @borderRadius "none") "euiPageContent--borderRadiusNone")
          componentName="EuiPageContent"
          verticalPosition=@verticalPosition
          horizontalPosition=@horizontalPosition
        }}
        @hasShadow={{@hasShadow}}
        @hasBorder={{@hasBorder}}
        @paddingSize={{argOrDefault @paddingSize "l"}}
        @borderRadius={{@borderRadius}}
        @color={{@color}}
        @grow={{@grow}}
        ...attributes
      >
        {{yield}}
      </EuiPanel>
    {{/let}}
  </template>;

export default EuiPageContent;
