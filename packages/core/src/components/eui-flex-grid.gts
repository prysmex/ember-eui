import { element } from 'ember-element-helper';
import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type {
  directionMapping,
  gutterSizeMapping} from '../utils/css-mappings/eui-flex-grid.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFlexGridSignature {
  Element: HTMLDivElement | any;
  Args: {
    /**
     * Passes the HTML tag to the wrapping element. Defaults to `'div'`.
     */
    tagName?: string;
    /**
     * `'row'` fills the grid row by row, `'column'` column by column.
     * Defaults to `'row'`.
     */
    direction?: keyof typeof directionMapping;
    /**
     * Number of columns, `1` to `4`. `0` lets the items wrap at their own
     * width. Defaults to `0`.
     */
    columns?: number;
    /**
     * Space between items: `'none'`, `'s'`, `'m'`, `'l'` or `'xl'`.
     * Defaults to `'l'`.
     */
    gutterSize?: keyof typeof gutterSizeMapping;
    /**
     * Stacks the items in one column on small screens. Defaults to `true`.
     */
    responsive?: boolean;
  };
  Blocks: {
    /** The `EuiFlexItem`s, laid out in a grid. */
    default: [];
  };
}

const EuiFlexGrid: TemplateOnlyComponent<EuiFlexGridSignature> = <template>
  {{#let (argOrDefault @tagName "div") as |tagName|}}
    {{#if (eq tagName "div")}}
      <div
        class={{classNames
          (unless (eq @responsive false) "euiFlexGrid--responsive")
          componentName="EuiFlexGrid"
          gutterSize=(argOrDefault @gutterSize "l")
          direction=(argOrDefault @direction "row")
          columns=(argOrDefault @columns 0)
        }}
        ...attributes
      >
        {{yield}}
      </div>
    {{else}}
      {{#let (element tagName) as |Element|}}
        <Element
          class={{classNames
            (unless (eq @responsive false) "euiFlexGrid--responsive")
            componentName="EuiFlexGrid"
            gutterSize=(argOrDefault @gutterSize "l")
            direction=(argOrDefault @direction "row")
            columns=(argOrDefault @columns 0)
          }}
          ...attributes
        >
          {{yield}}
        </Element>
      {{/let}}
    {{/if}}
  {{/let}}
</template>;

export default EuiFlexGrid;
