import { helper } from '@ember/component/helper';
import { fn } from '@ember/helper';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';

import { and, eq, gt,not, or } from 'ember-truth-helpers';
import isArray from 'ember-truth-helpers/helpers/is-array';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import useState from '../helpers/use-state';
import EuiFormErrorText from './eui-form-error-text.gts';
import EuiFormHelpText from './eui-form-help-text.gts';
import EuiFormLabel from './eui-form-label.gts';

import type { displayMappingToClassMapping } from '../utils/css-mappings/eui-form-row';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFormRowSignature {
  Element: HTMLDivElement | HTMLFieldSetElement;
  Args: {
    label?: string;
    labelAppend?: string;
    labelType?: 'label' | 'legend';
    legendType?: 'legend' | 'fieldset';
    fullWidth?: boolean;
    isInvalid?: boolean;
    isDisabled?: boolean;
    hasEmptyLabelSpace?: boolean;
    hasChildLabel?: boolean;
    isFakeLabelBlock?: boolean;
    helpText?: string;
    error?: string | string[] | null;
    errorClasses?: string;
    helpTextClasses?: string;
    id?: string;
    display?: keyof typeof displayMappingToClassMapping;
    extra?: unknown;
  };
  Blocks: {
    default: [];
    label: [string?];
    field: [];
    errors: [string?];
    helpText: [];
  };
}

export function startsWith(
  [needle, word]: [string, string | undefined] /*, hash*/
): boolean {
  return word?.startsWith(needle) || false;
}

const startWith = helper(startsWith);

const EuiFormRow: TemplateOnlyComponent<EuiFormRowSignature> = <template>
  {{#let
    (classNames
      "euiFormRow"
      (if @hasEmptyLabelSpace "euiFormRow--hasEmptyLabelSpace")
      (if @fullWidth "euiFormRow--fullWidth")
      componentName="EuiFormRow"
      display=@display
    )
    (classNames
      "euiFormRow__fieldWrapper"
      (if (startWith "center" @display) "euiFormRow__fieldWrapperDisplayOnly")
    )
    (if (isArray @error) @error (array @error))
    (and @label (eq @labelType "legend"))
    (useState false)
    (argOrDefault @id (uniqueId))
    (argOrDefault @hasChildLabel true)
    (and (not (argOrDefault @isFakeLabelBlock false)) (has-block "label"))
    as |classes fieldWrapperClasses errors isLegend focusedState rowId hasChildLabel hasLabelBlock|
  }}
    {{#if (eq @legendType "legend")}}
      <fieldset class={{classes}} id="{{rowId}}-row" ...attributes>
        {{#if (or @label @labelAppend hasLabelBlock)}}
          <div class="euiFormRow__labelWrapper">
            {{#if isLegend}}
              {{#if hasLabelBlock}}
                <EuiFormLabel
                  class="euiFormRow__label"
                  for={{rowId}}
                  aria-invalid={{@isInvalid}}
                  @isInvalid={{@isInvalid}}
                  @type={{@labelType}}
                >
                  {{yield @label to="label"}}
                </EuiFormLabel>
              {{else}}
                <EuiFormLabel
                  class="euiFormRow__label"
                  for={{rowId}}
                  aria-invalid={{@isInvalid}}
                  @isInvalid={{@isInvalid}}
                  @type={{@labelType}}
                >
                  {{@label}}
                </EuiFormLabel>
              {{/if}}
            {{else if hasLabelBlock}}
              <EuiFormLabel
                class="euiFormRow__label"
                aria-invalid={{@isInvalid}}
                for={{if hasChildLabel rowId}}
                @isInvalid={{@isInvalid}}
                @type={{@labelType}}
                @isFocused={{and
                  (not @isDisabled)
                  (not isLegend)
                  focusedState.value
                }}
              >
                {{yield @label to="label"}}
              </EuiFormLabel>
            {{else}}
              <EuiFormLabel
                class="euiFormRow__label"
                aria-invalid={{@isInvalid}}
                for={{if hasChildLabel rowId}}
                @isInvalid={{@isInvalid}}
                @type={{@labelType}}
                @isFocused={{and
                  (not @isDisabled)
                  (not isLegend)
                  focusedState.value
                }}
              >
                {{@label}}
              </EuiFormLabel>
            {{/if}}
          </div>
        {{/if}}
        <div
          class={{fieldWrapperClasses}}
          {{on "focusin" (fn focusedState.setState true)}}
          {{on "focusout" (fn focusedState.setState false)}}
        >
          {{#if (has-block "field")}}
            {{yield to="field"}}
          {{else}}
            {{yield}}
          {{/if}}
          {{#if
            (or
              (and (has-block "errors") @isInvalid)
              (and (gt errors.length 0) @isInvalid)
            )
          }}
            {{#if (has-block "errors")}}
              {{#each errors as |error i|}}
                <EuiFormErrorText
                  class="euiFormRow__text {{@errorClasses}}"
                  id="{{rowId}}-error-{{i}}"
                >
                  {{!@glint-ignore}}
                  {{yield error to="errors"}}
                </EuiFormErrorText>
              {{/each}}
            {{else}}
              {{#each errors as |error i|}}
                <EuiFormErrorText
                  class="euiFormRow__text {{@errorClasses}}"
                  id="{{rowId}}-error-{{i}}"
                >
                  {{!@glint-ignore}}
                  {{error}}
                </EuiFormErrorText>
              {{/each}}
            {{/if}}
          {{/if}}
          {{#if (or @helpText (has-block "helpText"))}}
            {{#if (has-block "helpText")}}
              <EuiFormHelpText id="{{rowId}}-help" class={{@helpTextClasses}}>
                {{yield to="helpText"}}
              </EuiFormHelpText>
            {{else}}
              <EuiFormHelpText id="{{rowId}}-help" class={{@helpTextClasses}}>
                {{@helpText}}
              </EuiFormHelpText>
            {{/if}}
          {{/if}}
        </div>
      </fieldset>
    {{else}}
      <div class={{classes}} id="{{rowId}}-row" ...attributes>
        {{#if (or @label @labelAppend hasLabelBlock)}}
          <div class="euiFormRow__labelWrapper">
            {{#if isLegend}}
              {{#if hasLabelBlock}}
                <EuiFormLabel
                  class="euiFormRow__label"
                  for={{rowId}}
                  aria-invalid={{@isInvalid}}
                  @isInvalid={{@isInvalid}}
                  @type={{@labelType}}
                >
                  {{yield @label to="label"}}
                </EuiFormLabel>
              {{else}}
                <EuiFormLabel
                  class="euiFormRow__label"
                  for={{rowId}}
                  aria-invalid={{@isInvalid}}
                  @isInvalid={{@isInvalid}}
                  @type={{@labelType}}
                >
                  {{@label}}
                </EuiFormLabel>
              {{/if}}
            {{else if hasLabelBlock}}
              <EuiFormLabel
                class="euiFormRow__label"
                aria-invalid={{@isInvalid}}
                for={{if hasChildLabel rowId}}
                @isInvalid={{@isInvalid}}
                @type={{@labelType}}
                @isFocused={{and
                  (not @isDisabled)
                  (not isLegend)
                  focusedState.value
                }}
              >
                {{yield @label to="label"}}
              </EuiFormLabel>
            {{else}}
              <EuiFormLabel
                class="euiFormRow__label"
                aria-invalid={{@isInvalid}}
                for={{if hasChildLabel rowId}}
                @isInvalid={{@isInvalid}}
                @type={{@labelType}}
                @isFocused={{and
                  (not @isDisabled)
                  (not isLegend)
                  focusedState.value
                }}
              >
                {{@label}}
              </EuiFormLabel>
            {{/if}}
          </div>
        {{/if}}
        <div
          class={{fieldWrapperClasses}}
          {{on "focusin" (fn focusedState.setState true)}}
          {{on "focusout" (fn focusedState.setState false)}}
        >
          {{#if (has-block "field")}}
            {{yield to="field"}}
          {{else}}
            {{yield}}
          {{/if}}
          {{#if
            (or
              (and (has-block "errors") @isInvalid)
              (and (gt errors.length 0) @isInvalid)
            )
          }}
            {{#if (has-block "errors")}}
              {{#each errors as |error i|}}
                <EuiFormErrorText
                  class="euiFormRow__text {{@errorClasses}}"
                  id="{{rowId}}-error-{{i}}"
                >
                  {{!@glint-ignore}}
                  {{yield error to="errors"}}
                </EuiFormErrorText>
              {{/each}}
            {{else}}
              {{#each errors as |error i|}}
                <EuiFormErrorText
                  class="euiFormRow__text {{@errorClasses}}"
                  id="{{rowId}}-error-{{i}}"
                >
                  {{!@glint-ignore}}
                  {{error}}
                </EuiFormErrorText>
              {{/each}}
            {{/if}}
          {{/if}}
          {{#if (or @helpText (has-block "helpText"))}}
            {{#if (has-block "helpText")}}
              <EuiFormHelpText id="{{rowId}}-help" class={{@helpTextClasses}}>
                {{yield to="helpText"}}
              </EuiFormHelpText>
            {{else}}
              {{#let
                (if (isArray @helpText) @helpText (array @helpText))
                as |helpTexts|
              }}
                {{#each helpTexts as |helpText i|}}
                  <EuiFormHelpText
                    id="{{rowId}}-help-{{i}}"
                    class={{@helpTextClasses}}
                  >
                    {{helpText}}
                  </EuiFormHelpText>
                {{/each}}
              {{/let}}
            {{/if}}
          {{/if}}
        </div>
      </div>
    {{/if}}
  {{/let}}
</template>;

export default EuiFormRow;
