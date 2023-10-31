import { eq } from 'ember-truth-helpers';
import argOrDefault from '../helpers/arg-or-default';
import EuiPanel from './eui-panel';
import type { EuiPanelSignature } from './eui-panel';
import classNames from '../helpers/class-names';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPageContentSignature {
  Element: HTMLDivElement;
  Args: {
    role?: string;
    verticalPosition?: 'center' | 'bottom';
    horizontalPosition?: 'center';
    hasShadow?: boolean;
    hasBorder?: boolean;
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    color?: EuiPanelSignature['Args']['color'];
    grow?: boolean;
  };
  Blocks: {
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
