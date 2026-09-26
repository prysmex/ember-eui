import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type {
  alignItemsMapping,
  directionMapping,
  gutterSizeMapping,
  justifyContentMapping} from '../utils/css-mappings/eui-flex-group.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFlexGroupSignature {
  Element: HTMLDivElement | HTMLSpanElement;
  Args: {
    /**
     * Space between items: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`.
     * Defaults to `'l'`.
     */
    gutterSize?: keyof typeof gutterSizeMapping;
    /**
     * Cross axis alignment (`align-items`): `'stretch'`, `'flexStart'`,
     * `'flexEnd'`, `'center'` or `'baseline'`. Defaults to `'stretch'`.
     */
    alignItems?: keyof typeof alignItemsMapping;
    /**
     * Main axis distribution (`justify-content`): `'flexStart'`,
     * `'flexEnd'`, `'center'`, `'spaceBetween'`, `'spaceAround'` or
     * `'spaceEvenly'`. Defaults to `'flexStart'`.
     */
    justifyContent?: keyof typeof justifyContentMapping;
    /**
     * `'row'`, `'rowReverse'`, `'column'` or `'columnReverse'`.
     * Defaults to `'row'`.
     */
    direction?: keyof typeof directionMapping;
    /** Lets items wrap onto several lines. Defaults to `false`. */
    wrap?: boolean;
    /**
     * Stacks the items in one column on small screens. Set `false` for rows
     * that must stay on one line (e.g. icon + text). Defaults to `true`.
     */
    responsive?: boolean;
    /** `'div'` or `'span'` (inside text). Defaults to `'div'`. */
    tagName?: 'div' | 'span';
  };
  Blocks: {
    /** The `EuiFlexItem`s. */
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
