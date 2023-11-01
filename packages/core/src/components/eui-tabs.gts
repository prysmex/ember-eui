import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import { eq } from 'ember-truth-helpers';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

import { sizeMapping, displayMapping } from '../utils/css-mappings/eui-tabs';

export interface EuiTabsSignature {
  Element: HTMLDivElement;
  Args: {
    display?: keyof typeof displayMapping;
    size?: keyof typeof sizeMapping;
    expand?: boolean;
    bottomBorder?: boolean;
    className?: string;
  };
  Blocks: {
    default: [];
  };
}

const EuiTabs: TemplateOnlyComponent<EuiTabsSignature> = <template>
  {{#let
    (if (eq @display "condensed") false (argOrDefault @bottomBorder true))
    as |bottomBorder|
  }}
    <div
      role="tablist"
      class={{classNames
        (if (argOrDefault @expand false) "euiTabs--expand")
        (if bottomBorder "euiTabs--bottomBorder")
        @className
        componentName="EuiTabs"
        display=(argOrDefault @display "default")
        size=(argOrDefault @size "m")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  {{/let}}
</template>;

export default EuiTabs;
