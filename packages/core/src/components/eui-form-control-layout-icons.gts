import { on } from '@ember/modifier';

import { and, eq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import EuiFormControlLayoutClearButton from './eui-form-control-layout-clear-button';
import EuiFormControlLayoutCustomIcon from './eui-form-control-layout-custom-icon';
import EuiLoadingSpinner from './eui-loading-spinner';

import type { DistributiveOmit } from './common';
import type { EuiFormControlLayoutClearButtonArgs } from './eui-form-control-layout-clear-button';
import type { EuiFormControlLayoutCustomIconArgs } from './eui-form-control-layout-custom-icon';
import type { IconType } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

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
  iconSide?: (typeof ICON_SIDES)[number];
  clear?: EuiFormControlLayoutClearButtonArgs;
  isLoading?: boolean;
  compressed?: boolean;
}

export interface EuiFormControlLayoutIconsSignature {
  Element: typeof EuiFormControlLayoutCustomIcon,
  Args: EuiFormControlLayoutIconsArgs;
}

const EuiFormControlLayoutIcons: TemplateOnlyComponent<EuiFormControlLayoutIconsSignature> =
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
  </template>;

export default EuiFormControlLayoutIcons;
