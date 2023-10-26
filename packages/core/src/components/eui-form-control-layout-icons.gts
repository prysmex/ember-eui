import argOrDefault from '../helpers/arg-or-default';
import { and, or, eq } from 'ember-truth-helpers';
import EuiFormControlLayoutCustomIcon from './eui-form-control-layout-custom-icon';
import EuiLoadingSpinner from './eui-loading-spinner';
import EuiFormControlLayoutClearButton from './eui-form-control-layout-clear-button';
import { on } from '@ember/modifier';

import { IconType } from './eui-icon';
import { DistributiveOmit } from './common';
import { EuiFormControlLayoutCustomIconArgs } from './eui-form-control-layout-custom-icon';
import { EuiFormControlLayoutClearButtonArgs } from './eui-form-control-layout-clear-button';

export const ICON_SIDES: ['left', 'right'] = ['left', 'right'];

type IconShape = DistributiveOmit<
  EuiFormControlLayoutCustomIconArgs,
  'type' | 'iconRef'
> & {
  type: IconType;
  side?: (typeof ICON_SIDES)[number];
  ref?: EuiFormControlLayoutCustomIconArgs['iconRef'];
};

export interface EuiFormControlLayoutIconsArgs {
  icon?: IconType | IconShape;
  clear?: EuiFormControlLayoutClearButtonArgs;
  isLoading?: boolean;
  compressed?: boolean;
}

<template>
  {{#let (argOrDefault @iconSide "left") as |iconSide|}}
    {{#if (and @icon (eq iconSide "left"))}}
      <div class="euiFormControlLayoutIcons">
        <EuiFormControlLayoutCustomIcon
          @size={{if @compressed "s" "m"}}
          @type={{@icon}}
          ...attributes
        />
      </div>
    {{/if}}
    {{#if (or @clear @isLoading (and @icon (eq iconSide "right")))}}
      <div class="euiFormControlLayoutIcons euiFormControlLayoutIcons--right">
        {{#if @clear}}
          <EuiFormControlLayoutClearButton
            @size={{if @compressed "s" "m"}}
            {{on "click" @clear}}
          />
        {{/if}}
        {{#if @isLoading}}
          <EuiLoadingSpinner @size="m" />
        {{/if}}
        {{#if (and @icon (eq iconSide "right"))}}
          <EuiFormControlLayoutCustomIcon
            @size={{if @compressed "s" "m"}}
            @type={{@icon}}
            ...attributes
          />
        {{/if}}
      </div>
    {{/if}}
  {{/let}}
</template>
