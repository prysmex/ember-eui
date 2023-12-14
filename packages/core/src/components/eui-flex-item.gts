import { element } from 'ember-element-helper';
import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

import type { growMapping } from '../utils/css-mappings/eui-flex-item';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFlexItemSignature {
  Element: Element;
  Args: {
    grow?: keyof typeof growMapping | boolean;
    tagName?: string;
  };
  Blocks: {
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
