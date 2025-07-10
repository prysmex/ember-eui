import { eq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiIcon from './eui-icon.gts';
import EuiText from './eui-text.gts';
import TextBlock from './text-block.gts';

import type {
  colorMapping,
  sizeMapping
} from '../utils/css-mappings/eui-call-out';
import type { EuiIconSignature } from './eui-icon';
import type { EuiTextSignature } from './eui-text';
import type { TextBlockSignature } from './text-block';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiCallOutSignature {
  Element: HTMLDivElement;
  Args: {
    title?: string;
    heading?: TextBlockSignature['Args']['tagName'];
    iconType?: EuiIconSignature['Args']['type'];
    size?: keyof typeof sizeMapping;
    color?: keyof typeof colorMapping;
    textColor?: EuiTextSignature['Args']['color'];
    iconSize?: EuiIconSignature['Args']['size'];
  };
  Blocks: {
    title?: [];
    body?: [];
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
    {{#if (has-block "body")}}
      <EuiText @size={{if (eq @size "s") "xs" "s"}} @color={{@textColor}}>
        {{yield to="body"}}
      </EuiText>
    {{/if}}
  </div>
</template>;

export default EuiCallOut;
