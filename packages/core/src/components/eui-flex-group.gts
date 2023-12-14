import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

import type {
  alignItemsMapping,
  directionMapping,
  gutterSizeMapping,
  justifyContentMapping} from '../utils/css-mappings/eui-flex-group';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFlexGroupSignature {
  Element: HTMLDivElement | HTMLSpanElement;
  Args: {
    gutterSize?: keyof typeof gutterSizeMapping;
    alignItems?: keyof typeof alignItemsMapping;
    justifyContent?: keyof typeof justifyContentMapping;
    direction?: keyof typeof directionMapping;
    wrap?: boolean;
    responsive?: boolean;
    tagName?: 'div' | 'span';
  };
  Blocks: {
    default: [];
  };
}

const EuiFlexGroup: TemplateOnlyComponent<EuiFlexGroupSignature> = <template>
  {{#if (eq @tagName "span")}}
    <span
      class={{classNames
        (unless (eq @responsive false) "euiFlexGroup--responsive")
        (if @wrap "euiFlexGroup--wrap")
        componentName="EuiFlexGroup"
        gutterSize=(argOrDefault @gutterSize "l")
        alignItems=(argOrDefault @alignItems "stretch")
        justifyContent=(argOrDefault @justifyContent "flexStart")
        direction=(argOrDefault @direction "row")
      }}
      ...attributes
    >
      {{yield}}
    </span>
  {{else}}
    <div
      class={{classNames
        (unless (eq @responsive false) "euiFlexGroup--responsive")
        (if @wrap "euiFlexGroup--wrap")
        componentName="EuiFlexGroup"
        gutterSize=(argOrDefault @gutterSize "l")
        alignItems=(argOrDefault @alignItems "stretch")
        justifyContent=(argOrDefault @justifyContent "flexStart")
        direction=(argOrDefault @direction "row")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  {{/if}}
</template>;

export default EuiFlexGroup;
