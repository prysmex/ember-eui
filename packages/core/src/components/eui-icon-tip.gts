import { or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import EuiIcon from './eui-icon.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type { EuiIconSignature } from './eui-icon';
import type { EuiToolTipSignature } from './eui-tool-tip';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A focusable icon (a "?" by default) showing a tooltip, e.g. to explain a
 * setting next to its label.
 */
export interface EuiIconTipSignature {
  Element: EuiToolTipSignature['Element'];
  Args: {
    /** Where the tooltip appears. Defaults to `'top'`. */
    position?: 'top' | 'right' | 'bottom' | 'left';
    /** `'regular'` or `'long'` delay before showing. Defaults to `'regular'`. */
    delay?: 'regular' | 'long';
    /** Bold title of the tooltip. */
    title?: string;
    /** The tooltip's text. */
    content?: string;
    /** Props for the icon: `{ className }`. */
    iconProps?: {
      className?: string;
    };
    /** The icon. Defaults to `'questionInCircle'`. */
    type?: string;
    /** Color of the icon, any `EuiIcon` color. */
    color?: string;
    /** Size of the icon. */
    size?: EuiIconSignature['Args']['size'];
    /** Accessible name of the icon. Defaults to "Info". */
    ariaLabel?: string;
    /** Class for the element wrapping the icon. */
    anchorClassName?: string;
    /** Called when the pointer leaves the icon. */
    onMouseOut?: (event: MouseEvent) => void;
    /** Display of the wrapper: `'inlineBlock'` or `'block'`. */
    display?: EuiToolTipSignature['Args']['display'];
  };
  Blocks: {
    /** The tooltip's content, instead of `@content`. */
    content: [];
    /** The tooltip's title, instead of `@title`. */
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
          @aria-label={{argOrDefault @ariaLabel "Info"}}
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
