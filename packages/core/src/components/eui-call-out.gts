import { eq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiIcon from './eui-icon.gts';
import EuiText from './eui-text.gts';
import TextBlock from './text-block.gts';

import type {
  colorMapping,
  sizeMapping
} from '../utils/css-mappings/eui-call-out.ts';
import type { EuiIconSignature } from './eui-icon';
import type { EuiTextSignature } from './eui-text';
import type { TextBlockSignature } from './text-block';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiCallOutSignature {
  Element: HTMLDivElement;
  Args: {
    /** Title in the callout's header. Use the `<:title>` block for markup. */
    title?: string;
    /**
     * Renders the title as a heading element, e.g. `'h2'`, so it appears in
     * the page outline. Defaults to a `<span>`.
     */
    heading?: TextBlockSignature['Args']['tagName'];
    /**
     * Icon before the title (only shown with a title), e.g. `'alert'`,
     * `'check'` or `'help'`.
     */
    iconType?: EuiIconSignature['Args']['type'];
    /** `'s'` or `'m'`. Defaults to `'m'`. */
    size?: keyof typeof sizeMapping;
    /**
     * `'primary'`, `'success'`, `'warning'` or `'danger'`.
     * Defaults to `'primary'`.
     */
    color?: keyof typeof colorMapping;
    /** Color of the body text, any `EuiText` color. Defaults to the text color. */
    textColor?: EuiTextSignature['Args']['color'];
    /** Size of the title icon. Defaults to `'m'`. */
    iconSize?: EuiIconSignature['Args']['size'];
  };
  Blocks: {
    /** The title, instead of `@title`. */
    title?: [];
    /** The body; same as the default block. */
    body?: [];
    /** The body, e.g. paragraphs and buttons. */
    default?: [];
  };
}

const EuiCallOut: TemplateOnlyComponent<EuiCallOutSignature> = <template>
  <div
    class={{classNames
      componentName="EuiCallOut"
      size=(argOrDefault @size "m")
      color=(argOrDefault @color "primary")
    }}
    ...attributes
  >
    {{#if (or @title (has-block "title"))}}
      <div class="euiCallOutHeader">
        {{#if @iconType}}
          <EuiIcon
            @iconClasses="euiCallOutHeader__icon"
            @type={{@iconType}}
            @size={{argOrDefault @iconSize "m"}}
            aria-hidden="true"
            @color="inherit"
          />
        {{/if}}
        {{#if @heading}}
          <TextBlock @tagName={{@heading}} class="euiCallOutHeader__title">
            {{#if (has-block "title")}}
              {{yield to="title"}}
            {{else}}
              {{@title}}
            {{/if}}
          </TextBlock>
        {{else}}
          <span class="euiCallOutHeader__title">
            {{#if (has-block "title")}}
              {{yield to="title"}}
            {{else}}
              {{@title}}
            {{/if}}
          </span>
        {{/if}}
      </div>
    {{/if}}
    {{#if (or (has-block "body") (has-block))}}
      <EuiText @size={{if (eq @size "s") "xs" "s"}} @color={{@textColor}}>
        {{#if (has-block "body")}}
          {{yield to="body"}}
        {{else}}
          {{yield}}
        {{/if}}
      </EuiText>
    {{/if}}
  </div>
</template>;

export default EuiCallOut;
