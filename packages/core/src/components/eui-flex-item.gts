import { element } from 'ember-element-helper';
import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { growMapping } from '../utils/css-mappings/eui-flex-item.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFlexItemSignature {
  Element: Element;
  Args: {
    /**
     * How the item grows: `true` (default) takes an equal share of the
     * space, `false` only takes its content's width, `1`–`10` take that
     * many shares.
     */
    grow?: keyof typeof growMapping | boolean;
    /** Tag of the item. Defaults to `'div'`. */
    tagName?: string;
  };
  Blocks: {
    /** The content. */
    default: [];
  };
}

const EuiFlexItem: TemplateOnlyComponent<EuiFlexItemSignature> = <template>
  {{#let (argOrDefault @tagName "div") as |tagName|}}
    {{#if (eq tagName "div")}}
      <div
        class={{classNames componentName="EuiFlexItem" grow=@grow}}
        ...attributes
      >
        {{yield}}
      </div>
    {{else if (eq tagName "span")}}
      <span
        class={{classNames componentName="EuiFlexItem" grow=@grow}}
        ...attributes
      >
        {{yield}}
      </span>
    {{else}}
      {{#let (element tagName) as |TagElement|}}
        <TagElement
          class={{classNames componentName="EuiFlexItem" grow=@grow}}
          ...attributes
        >
          {{yield}}
        </TagElement>
      {{/let}}
    {{/if}}
  {{/let}}
</template>;

export default EuiFlexItem;
