import inlineStyles from '@ember-eui/core/helpers/inline-styles';
import classNames from '@ember-eui/core/helpers/class-names';
import simpleStyle from '@ember-eui/core/modifiers/simple-style';
import { and, not, or } from 'ember-truth-helpers';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import { hash } from '@ember/helper';
import EuiIcon from '@ember-eui/core/components/eui-icon';
import { on } from '@ember/modifier';
import { optional } from 'ember-composable-helpers/helpers/optional';

<template>
  {{#if (and (or @onClick @href) (not @iconType))}}
    {{#if @onClick}}
      <button
        type="button"
        class={{classNames
          "euiBadge-isClickable"
          (if @isDisabled "euiBadge-isDisabled")
          componentName="EuiBadge"
          color=(argOrDefault @color "default")
        }}
        aria-label={{if @onClick @onClickAriaLabel}}
        disabled={{@isDisabled}}
        ...attributes
        {{simpleStyle
          (inlineStyles
            componentName="EuiBadge"
            componentArgs=(hash badgeColor=(argOrDefault @color "default"))
          )
        }}
        {{on "click" (optional @onClick)}}
      >
        <span class="euiBadge__content">
          <span class="euiBadge__text">
            {{yield}}
          </span>
        </span>
      </button>
    {{else}}
      <a
        class={{classNames
          "euiBadge-isClickable"
          (if @isDisabled "euiBadge-isDisabled")
          componentName="EuiBadge"
          color=(argOrDefault @color "default")
        }}
        target={{@target}}
        href={{@href}}
        aria-label={{if @onClick @onClickAriaLabel}}
        disabled={{@isDisabled}}
        ...attributes
        {{simpleStyle
          (inlineStyles
            componentName="EuiBadge"
            componentArgs=(hash badgeColor=(argOrDefault @color "default"))
          )
        }}
      >
        <span class="euiBadge__content">
          <span class="euiBadge__text">
            {{yield}}
          </span>
        </span>
      </a>
    {{/if}}
  {{else if @iconType}}
    <span
      class={{classNames
        (if @isDisabled "euiBadge-isDisabled")
        componentName="EuiBadge"
        iconSide=(argOrDefault @iconSide "left")
        color=(argOrDefault @color "default")
      }}
      ...attributes
      {{simpleStyle
        (inlineStyles
          componentName="EuiBadge"
          componentArgs=(hash badgeColor=(argOrDefault @color "default"))
        )
      }}
    >
      <span class="euiBadge__content">
        {{#if (has-block)}}
          {{#if @onClick}}
            <button
              class="euiBadge__childButton"
              type="button"
              disabled={{@isDisabled}}
              {{on "click" (optional @onClick)}}
            >
              {{yield}}
            </button>
          {{else if @href}}
            <a
              class="euiBadge__childButton"
              href={{@href}}
              disabled={{@isDisabled}}
            >
              {{yield}}
            </a>
          {{else}}
            <span class="euiBadge__text">
              {{yield}}
            </span>
          {{/if}}
        {{/if}}
        {{#if @iconOnClick}}
          {{! template-lint-disable }}
          <button
            type="button"
            class="euiBadge__iconButton"
            aria-label={{@iconOnClickAriaLabel}}
            disabled={{@isDisabled}}
            title={{@iconOnClickAriaLabel}}
            tabindex={{@closeButtonProps.tabIndex}}
            data-selected-index={{@closeButtonProps.dataSelectedIconIndex}}
            {{on "click" (optional @iconOnClick)}}
          >
            <EuiIcon
              @color="inherit"
              @iconClasses={{classNames
                "euiBadge__icon"
                @closeButtonProps.iconClasses
              }}
              @type={{@iconType}}
              @size={{if (has-block) "s" "m"}}
            />
          </button>
          {{! tempalte-lint-enable}}
        {{else}}
          <EuiIcon
            @color="inherit"
            @type={{@iconType}}
            @size={{if (has-block) "s" "m"}}
            @iconClasses="euiBadge__icon"
          />
        {{/if}}
      </span>
    </span>
  {{else}}
    <span
      class={{classNames
        (if @isDisabled "euiBadge-isDisabled")
        componentName="EuiBadge"
        iconSide=(argOrDefault @iconSide "left")
        color=(argOrDefault @color "default")
      }}
      ...attributes
      {{simpleStyle
        (inlineStyles
          componentName="EuiBadge"
          componentArgs=(hash badgeColor=(argOrDefault @color "default"))
        )
      }}
    >
      <span class="euiBadge__content">
        <span class="euiBadge__text">
          {{yield}}
        </span>
      </span>
    </span>
  {{/if}}
</template>
