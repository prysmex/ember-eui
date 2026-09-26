import { and, not } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiTextAlign from './eui-text-align.gts';
import EuiTextColor from './eui-text-color.gts';

import type { sizeMapping } from '../utils/css-mappings/eui-text.ts';
import type { alignMapping } from '../utils/css-mappings/eui-text-align.ts';
import type { colorMapping } from '../utils/css-mappings/eui-text-color.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** Styles plain HTML content (`<p>`, `<ul>`, `<h3>`, `<code>`…) with EUI's typography. */
export interface EuiTextSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * `true` lets text span the container's full width; `false` caps lines
     * at a readable width. Defaults to `true`.
     */
    grow?: boolean;
    /** `'xs'`, `'s'`, `'m'` or `'relative'` (inherits). Defaults to `'m'`. */
    size?: keyof typeof sizeMapping;
    /** `'left'`, `'center'` or `'right'`. */
    textAlign?: keyof typeof alignMapping;
    /**
     * `'default'`, `'subdued'`, `'success'`, `'accent'`, `'danger'`,
     * `'warning'`, `'ghost'` or `'primary'`.
     */
    color?: keyof typeof colorMapping;
  };
  Blocks: {
    /** HTML content (paragraphs, lists, headings, code…), styled by EuiText. */
    default: [];
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
