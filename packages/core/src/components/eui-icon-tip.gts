import { or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import EuiIcon from './eui-icon.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type { EuiIconSignature } from './eui-icon';
import type { EuiToolTipSignature } from './eui-tool-tip';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiIconTipSignature {
  Element: EuiToolTipSignature['Element'];
  Args: {
    position?: 'top' | 'right' | 'bottom' | 'left';
    delay?: 'regular' | 'long';
    title?: string;
    content?: string;
    iconProps?: {
      className?: string;
    };
    type?: string;
    color?: string;
    size?: EuiIconSignature['Args']['size'];
    ariaLabel?: string;
    anchorClassName?: string;
    onMouseOut?: (event: MouseEvent) => void;
    display?: EuiToolTipSignature['Args']['display'];
  };
  Blocks: {
    content: [];
    title: [];
  };
}

const EuiIconTip: TemplateOnlyComponent<EuiIconTipSignature> = <template>
  {{#let
    (has-block "content") (has-block "title")
    as |hasContentBlock hasTitleBlock|
  }}
    <EuiToolTip
      @position={{argOrDefault @position "top"}}
      @delay={{argOrDefault @delay "regular"}}
      @hasTitle={{if (or hasTitleBlock @title) true false}}
      @anchorClassName={{@anchorClassName}}
      @onMouseOut={{@onMouseOut}}
      @display={{@display}}
      ...attributes
    >
      <:anchor>
        <EuiIcon
          tabindex="0"
          @iconClasses={{@iconProps.className}}
          @type={{argOrDefault @type "questionInCircle"}}
          @color={{@color}}
          @size={{@size}}
          aria-label={{argOrDefault @ariaLabel "Info"}}
        />
      </:anchor>
      <:title>
        {{#if hasTitleBlock}}
          {{yield to="title"}}
        {{else}}
          {{@title}}
        {{/if}}
      </:title>
      <:content>
        {{#if hasContentBlock}}
          {{yield to="content"}}
        {{else}}
          {{@content}}
        {{/if}}
      </:content>
    </EuiToolTip>
  {{/let}}
</template>;

export default EuiIconTip;
