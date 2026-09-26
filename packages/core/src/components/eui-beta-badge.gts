import { on } from '@ember/modifier';

import { eq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiIcon from './eui-icon.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type {
  colorMapping,
  sizeMapping
} from '../utils/css-mappings/eui-beta-badge.ts';
import type { EuiIconSignature } from './eui-icon';
import type { EuiToolTipSignature } from './eui-tool-tip';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiBetaBadgeSignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * The badge's text, e.g. `'Beta'`, or a single letter (rendered as a
     * circle). Also its hover title. The default block replaces it.
     */
    label?: string;
    /**
     * Hover title when there is no `@label` (e.g. with `@iconType`), and the
     * title of the `@tooltipContent` tooltip.
     */
    title?: string;
    /**
     * Renders an icon instead of `@label` (icon-only badge). Give it a
     * `@title` so it has a name.
     */
    iconType?: EuiIconSignature['Args']['type'];
    /**
     * `'hollow'`, `'accent'` or `'subdued'`. Defaults to `'hollow'`.
     */
    color?: keyof typeof colorMapping;

    /**
     * `'s'` or `'m'`. Defaults to `'m'`.
     */
    size?: keyof typeof sizeMapping;
    /**
     * Where the `@tooltipContent` tooltip appears: `'top'`, `'right'`,
     * `'bottom'` or `'left'`. Defaults to `'top'`.
     */
    tooltipPosition?: EuiToolTipSignature['Args']['position'];
    /**
     * Shows a tooltip with this text on hover, e.g. what "Beta" means here.
     */
    tooltipContent?: string;
    /**
     * Accessible label of the badge when it is a link or button
     * (`@href` / `@onClick`).
     */
    onClickAriaLabel?: string;
    /**
     * Makes the badge a link.
     */
    href?: string;
    /**
     * `target` of the `@href` link, e.g. `'_blank'`.
     */
    target?: string;
    /**
     * `rel` of the `@href` link, e.g. `'noopener'`.
     */
    rel?: string;
    /**
     * Makes the badge a button calling this function.
     */
    onClick?: (event: MouseEvent) => void;
  };
  Blocks: {
    /** Custom content instead of `@label` / `@iconType`. */
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
