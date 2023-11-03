import argOrDefault from '../helpers/arg-or-default';
import { eq } from 'ember-truth-helpers';
import classNames from '../helpers/class-names';
import { element } from 'ember-element-helper';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

import {
  gutterSizeMapping,
  directionMapping
} from '../utils/css-mappings/eui-flex-grid';

export interface EuiFlexGridSignature {
  Element: HTMLDivElement | any;
  Args: {
    /**
     * Passes the HTML tag to the wrapping element
     */
    tagName?: string;
    /**
     * Sets the direction of the flex grid
     */
    direction?: keyof typeof directionMapping;
    /**
     * Sets the number of columns in the flex grid
     */
    columns?: number;
    /**
     * Sets the gutter size between flex items
     */
    gutterSize?: keyof typeof gutterSizeMapping;
    /**
     * Sets the responsive behavior of the flex grid
     */
    responsive?: boolean;
  };
  Blocks: {
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
