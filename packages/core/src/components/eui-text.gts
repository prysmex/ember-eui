import { and, not } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiTextAlign from './eui-text-align.gts';
import EuiTextColor from './eui-text-color.gts';

import type { sizeMapping } from '../utils/css-mappings/eui-text';
import type { alignMapping } from '../utils/css-mappings/eui-text-align';
import type { colorMapping } from '../utils/css-mappings/eui-text-color';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiTextSignature {
  Element: HTMLDivElement;
  Args: {
    grow?: boolean;
    size?: keyof typeof sizeMapping;
    textAlign?: keyof typeof alignMapping;
    color?: keyof typeof colorMapping;
  };
  Blocks: {
    default: [];
    hola: [number, {name: string}];
  };
}

const EuiTextComponent: TemplateOnlyComponent<EuiTextSignature> = <template>
  <div
    class={{classNames
      (unless (argOrDefault @grow true) "euiText--constrainedWidth")
      componentName="EuiText"
      size=(argOrDefault @size "m")
    }}
    ...attributes
  >
    {{#if (and @textAlign @color)}}
      {{#let (component EuiTextAlign) as |Align|}}
        {{#let (component EuiTextColor) as |Color|}}
          <Align @textAlign={{@textAlign}}>
            <Color @color={{@color}} @tagName="div">
              {{yield}}
            </Color>
          </Align>
        {{/let}}
      {{/let}}
    {{else if (and @textAlign (not @color))}}
      {{#let (component EuiTextAlign) as |Align|}}
        <Align @textAlign={{@textAlign}}>
          {{yield}}
        </Align>
      {{/let}}
    {{else if (and (not @textAlign) @color)}}
      {{#let (component EuiTextColor) as |Color|}}
        <Color @color={{@color}} @tagName="div">
          {{yield}}
        </Color>
      {{/let}}
    {{else}}
      {{yield}}
    {{/if}}
  </div>
</template>;

export default EuiTextComponent;
