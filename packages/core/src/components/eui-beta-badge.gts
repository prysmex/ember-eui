import classNames from '../helpers/class-names';
import { eq, or } from 'ember-truth-helpers';
import argOrDefault from '../helpers/arg-or-default';
import EuiIcon from './eui-icon';
import EuiToolTip from './eui-tool-tip';
import { on } from '@ember/modifier';

<template>
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
        color=(arg-or-default @color "hollow")
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
        {{else}}
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
            {{else}}
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
</template>
