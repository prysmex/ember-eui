import { on } from '@ember/modifier';

import { eq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiIcon from './eui-icon.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type {
  colorMapping,
  sizeMapping
} from '../utils/css-mappings/eui-beta-badge';
import type { EuiToolTipSignature } from './eui-tool-tip.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiBetaBadgeSignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * The label to use for the beta badge. Usually a single letter.
     */
    label?: string;
    /**
     * The title to use for the beta badge. Usually a full word.
     */
    title?: string;
    /**
     * The icon to use for the beta badge.
     */
    iconType?: string;
    /**
     * The color of the beta badge.
     */
    color?: keyof typeof colorMapping;

    /**
     * The size of the beta badge.
     */
    size?: keyof typeof sizeMapping;
    /**
     * The position of the tooltip for the beta badge.
     */
    tooltipPosition?: EuiToolTipSignature['Args']['position'];
    /**
     * The content of the tooltip for the beta badge.
     */
    tooltipContent?: string;
    /**
     * The aria-label for the beta badge.
     */
    onClickAriaLabel?: string;
    /**
     * The href for the beta badge.
     */
    href?: string;
    /**
     * The target for the beta badge.
     */
    target?: string;
    /**
     * The rel for the beta badge.
     */
    rel?: string;
    /**
     * The action to call when the beta badge is clicked.
     */
    onClick?: (event: MouseEvent) => void;
  };
  Blocks: {
    default: [];
  };
}

const EuiBetaBadge: TemplateOnlyComponent<EuiBetaBadgeSignature> = <template>
  {{#let
    (argOrDefault @size "m")
    (eq @label.length 1)
    (argOrDefault @tooltipPosition "top")
    as |size singleLetter tooltipPosition|
  }}

    {{#let
      (classNames
        (if @iconType "euiBetaBadge--iconOnly")
        (if singleLetter "euiBetaBadge--singleLetter")
        (if (or @onClick @href) "euiBetaBadge-isClickable")
        componentName="EuiBetaBadge"
        color=(argOrDefault @color "hollow")
        size=size
      )
      as |classes|
    }}

      {{#if (or @href @onClick)}}
        {{#if @href}}
          <a
            aria-label={{@onClickAriaLabel}}
            title={{if @label @label @title}}
            class={{classes}}
            href={{@href}}
            target={{@target}}
            rel={{@rel}}
            ...attributes
          >
            {{#if (has-block)}}
              {{yield}}
            {{else if @iconType}}
              <EuiIcon
                @iconClasses="euiBetaBadge__icon"
                @type={{@iconType}}
                @size={{if (eq size "m") "m" "s"}}
                aria-hidden="true"
                @color="inherit"
              />
            {{else}}
              {{@label}}
            {{/if}}
          </a>
        {{else if @onClick}}
          <button
            type="button"
            aria-label={{@onClickAriaLabel}}
            title={{if @label @label @title}}
            class={{classes}}
            {{on "click" @onClick}}
            ...attributes
          >
            {{#if (has-block)}}
              {{yield}}
            {{else if @iconType}}
              <EuiIcon
                @iconClasses="euiBetaBadge__icon"
                @type={{@iconType}}
                @size={{if (eq size "m") "m" "s"}}
                aria-hidden="true"
                @color="inherit"
              />
            {{else}}
              {{@label}}
            {{/if}}
          </button>
        {{/if}}

        {{#if @tooltipContent}}
          <EuiToolTip
            @position={{tooltipPosition}}
            @title={{or @title @label}}
            @content={{@tooltipContent}}
          >
            {{#if @href}}
              <a
                aria-label={{@onClickAriaLabel}}
                title={{if @label @label @title}}
                class={{classes}}
                href={{@href}}
                target={{@target}}
                rel={{@rel}}
                ...attributes
              >
                {{#if (has-block)}}
                  {{yield}}
                {{else if @iconType}}
                  <EuiIcon
                    @iconClasses="euiBetaBadge__icon"
                    @type={{@iconType}}
                    @size={{if (eq size "m") "m" "s"}}
                    aria-hidden="true"
                    @color="inherit"
                  />
                {{else}}
                  {{@label}}
                {{/if}}
              </a>
            {{else if @onClick}}
              <button
                type="button"
                aria-label={{@onClickAriaLabel}}
                title={{if @label @label @title}}
                class={{classes}}
                {{on "click" @onClick}}
                ...attributes
              >
                {{#if (has-block)}}
                  {{yield}}
                {{else if @iconType}}
                  <EuiIcon
                    @iconClasses="euiBetaBadge__icon"
                    @type={{@iconType}}
                    @size={{if (eq size "m") "m" "s"}}
                    aria-hidden="true"
                    @color="inherit"
                  />
                {{else}}
                  {{@label}}
                {{/if}}
              </button>
            {{/if}}
          </EuiToolTip>
        {{/if}}
      {{else}}
        {{#if @tooltipContent}}
          <EuiToolTip
            @position={{tooltipPosition}}
            @title={{or @title @label}}
            @content={{@tooltipContent}}
          >
            <span tabindex="0" class={{classes}} ...attributes>
              {{#if (has-block)}}
                {{yield}}
              {{else if @iconType}}
                <EuiIcon
                  @iconClasses="euiBetaBadge__icon"
                  @type={{@iconType}}
                  @size={{if (eq size "m") "m" "s"}}
                  aria-hidden="true"
                  @color="inherit"
                />
              {{else}}
                {{@label}}
              {{/if}}
            </span>
          </EuiToolTip>
        {{else}}
          <span class={{classes}} title={{@title}} ...attributes>
            {{#if (has-block)}}
              {{yield}}
            {{else if @iconType}}
              <EuiIcon
                @iconClasses="euiBetaBadge__icon"
                @type={{@iconType}}
                @size={{if (eq size "m") "m" "s"}}
                aria-hidden="true"
                @color="inherit"
              />
            {{else}}
              {{@label}}
            {{/if}}
          </span>
        {{/if}}

      {{/if}}

    {{/let}}

  {{/let}}
</template>;

export default EuiBetaBadge;
