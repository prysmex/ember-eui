import { on } from '@ember/modifier';

import { and, eq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import EuiFormControlLayoutClearButton from './eui-form-control-layout-clear-button.gts';
import EuiFormControlLayoutCustomIcon from './eui-form-control-layout-custom-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';

import type { EuiFormControlLayoutCustomIconSignature } from './eui-form-control-layout-custom-icon.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export const ICON_SIDES: ['left', 'right'] = ['left', 'right'];

export interface EuiFormControlLayoutIconsArgs {
  icon?: EuiFormControlLayoutCustomIconSignature['Args']['type'];
  iconSide?: (typeof ICON_SIDES)[number];
  clear?: (v: any) => void;
  isLoading?: boolean;
  compressed?: boolean;
}

export interface EuiFormControlLayoutIconsSignature {
  Element: EuiFormControlLayoutCustomIconSignature['Element'];
  Args: EuiFormControlLayoutIconsArgs;
}

const EuiFormControlLayoutIcons: TemplateOnlyComponent<EuiFormControlLayoutIconsSignature> =
  <template>
    {{#let (argOrDefault @iconSide "left") as |iconSide|}}
      {{#if (eq iconSide "left")}}
        <div class="euiFormControlLayoutIcons">
          {{#if @icon}}
            <EuiFormControlLayoutCustomIcon
              @size={{if @compressed "s" "m"}}
              @type={{@icon}}
              ...attributes
            />
          {{/if}}
        </div>
      {{/if}}
      {{#if (or @clear @isLoading (and @icon (eq iconSide "right")))}}
        <div class="euiFormControlLayoutIcons euiFormControlLayoutIcons--right">
          {{#if @clear}}
            <EuiFormControlLayoutClearButton
              @size={{if @compressed "s" "m"}}
              {{on "click" @clear}}
              ...attributes
            />
          {{/if}}
          {{#if @isLoading}}
            <EuiLoadingSpinner @size="m" />
          {{/if}}
          {{#if (eq iconSide "right")}}
            {{#if @icon}}
              <EuiFormControlLayoutCustomIcon
                @size={{if @compressed "s" "m"}}
                @type={{@icon}}
                ...attributes
              />
            {{/if}}
          {{/if}}
        </div>
      {{/if}}
    {{/let}}
  </template>;

export default EuiFormControlLayoutIcons;
