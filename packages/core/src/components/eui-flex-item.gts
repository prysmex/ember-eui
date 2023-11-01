import argOrDefault from '../helpers/arg-or-default';
import { eq } from 'ember-truth-helpers';
import classNames from '../helpers/class-names';
import { element } from 'ember-element-helper';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

import { growMapping } from '../utils/css-mappings/eui-flex-item';

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
