import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import type Component from '@glimmer/component';
import { and, or } from 'ember-truth-helpers';
import type { EuiFormControlLayoutIconsArgs } from './eui-form-control-layout-icons';
import EuiFormControlLayoutIcons from './eui-form-control-layout-icons';
import type { CommonArgs } from '../components/common';

type StringOrComponent = string | Component;
type PrependAppendType = StringOrComponent | StringOrComponent[];

export type EuiFormControlLayoutArgs = CommonArgs &
  HTMLDivElement & {
    /**
     * Creates an input group with element(s) coming before children.
     * `string` | `Component` or an array of these
     */
    prepend?: PrependAppendType;
    /**
     * Creates an input group with element(s) coming after children.
     * `string` | `Component` or an array of these
     */
    append?: PrependAppendType;
    children?: Component;
    icon?: EuiFormControlLayoutIconsArgs['icon'];
    clear?: EuiFormControlLayoutIconsArgs['clear'];
    fullWidth?: boolean;
    isLoading?: boolean;
    isDisabled?: boolean;
    className?: string;
    compressed?: boolean;
    readOnly?: boolean;
    /**
     * Connects the prepend and append labels to the input
     */
    inputId?: string;
  };

<template>
  <div
    class={{classNames
      (if @fullWidth "euiFormControlLayout--fullWidth")
      (if @compressed "euiFormControlLayout--compressed")
      (if @readOnly "euiFormControlLayout--readOnly")
      (if
        (and
          (argOrDefault @useGroup true)
          (or (has-block "append") (has-block "prepend"))
        )
        "euiFormControlLayout--group"
      )
      (if @disabled "euiFormControlLayout--isDisabled")
      "euiFormControlLayout"
    }}
    ...attributes
  >
    {{#if (has-block "prepend")}}
      {{yield "euiFormControlLayout__prepend" to="prepend"}}
    {{/if}}
    <div class="euiFormControlLayout__childrenWrapper">
      {{#if (has-block "field")}}
        {{yield to="field"}}
      {{else}}
        {{yield}}
      {{/if}}
      <EuiFormControlLayoutIcons
        @icon={{@icon}}
        @iconSide={{@iconSide}}
        @clear={{@clear}}
        @compressed={{@compressed}}
        @isLoading={{@isLoading}}
      />
    </div>
    {{#if (has-block "append")}}
      {{yield "euiFormControlLayout__append" to="append"}}
    {{/if}}
  </div>
</template>
