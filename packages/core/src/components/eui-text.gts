import { and, not } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiTextAlign from './eui-text-align';
import EuiTextColor from './eui-text-color';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiTextSignature {
  Element: HTMLDivElement;
  Args: {
    grow?: boolean;
    size?: 'xs' | 's' | 'm' | 'l' | 'xl';
    textAlign?: 'left' | 'center' | 'right';
    color?:
      | 'default'
      | 'subdued'
      | 'secondary'
      | 'accent'
      | 'danger'
      | 'warning'
      | 'ghost';
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

declare module '@glint/environment-ember-loose/registry' {
  export default interface Registry {
    EuiText: typeof EuiTextComponent;
  }
}
