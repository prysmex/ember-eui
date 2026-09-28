import { helper } from '@ember/component/helper';
import { fn } from '@ember/helper';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';

import { and, eq, gt, not, or } from 'ember-truth-helpers';
import isArray from 'ember-truth-helpers/helpers/is-array';

import linkFormRowControl from '../-private/link-form-row-control.ts';
import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import useState from '../helpers/use-state.ts';
import EuiFormErrorText from './eui-form-error-text.gts';
import EuiFormHelpText from './eui-form-help-text.gts';
import EuiFormLabel from './eui-form-label.gts';

import type { displayMappingToClassMapping } from '../utils/css-mappings/eui-form-row.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A form control with its label, help text and errors:
 * `<EuiFormRow @label="Name" @helpText="As shown to others"><EuiFieldText … /></EuiFormRow>`.
 */
export interface EuiFormRowSignature {
  Element: HTMLDivElement | HTMLFieldSetElement;
  Args: {
    /**
     * The control's label. It is linked to the first text-like control in
     * the row automatically (no need to pass ids around).
     */
    label?: string;
    /**
     * Text at the end of the label line, e.g. "Optional". Use the
     * `<:labelAppend>` block for markup such as a help link.
     */
    labelAppend?: string;
    /**
     * `'label'` renders a `<label>`; `'legend'` a `<legend>`, for rows whose
     * control is a group (radios, checkboxes). Defaults to `'label'`.
     */
    labelType?: 'label' | 'legend';
    /**
     * `'legend'` renders the row as a `<fieldset>` (use it with
     * `@labelType="legend"` for groups). Defaults to a `<div>`.
     */
    legendType?: 'legend' | 'fieldset';
    /** Lets the row (and its control) take the container's full width. */
    fullWidth?: boolean;
    /** Shows `@error` under the control and styles the label as invalid. */
    isInvalid?: boolean;
    /** Disables the label's focus styling. */
    isDisabled?: boolean;
    /**
     * Adds space above the control as if it had a label, to align it with
     * labelled rows next to it (e.g. a button in an `EuiFlexGroup` of rows).
     */
    hasEmptyLabelSpace?: boolean;
    /**
     * Link the label to the control. Set `false` when the control has its
     * own label (e.g. a single checkbox). Defaults to `true`.
     */
    hasChildLabel?: boolean;
    /** @private Ignore the `<:label>` block. */
    isFakeLabelBlock?: boolean;
    /** @private Ignore the `<:helpText>` block. */
    isFakeHelpTextBlock?: boolean;
    /**
     * Help text under the control (a string, or an array for several lines).
     * The control's `aria-describedby` points to it, so screen readers read
     * it with the control.
     */
    helpText?: string;
    /**
     * Error message(s) shown under the control while `@isInvalid`; they are
     * added to the control's `aria-describedby` while shown.
     */
    error?: string | string[] | null;
    /** Extra classes for each error message. */
    errorClasses?: string;
    /** Extra classes for the help text. */
    helpTextClasses?: string;
    /** Id of the control; the label points to it. Defaults to a random id. */
    id?: string;
    /**
     * Layout: `'row'` (label above), `'rowCompressed'`, `'columnCompressed'`
     * (label beside, for dense forms), `'columnCompressedSwitch'` (for an
     * `EuiSwitch`), or `'center'` / `'centerCompressed'` (vertically centers
     * a control without a label, e.g. a button next to rows).
     * Defaults to `'row'`.
     */
    display?: keyof typeof displayMappingToClassMapping;
    /** @deprecated Has no effect. */
    extra?: unknown;
  };
  Blocks: {
    /** The control, e.g. `<EuiFieldText />`. */
    default: [];
    /** Custom label content, instead of `@label`; yields `@label`. */
    label: [string?];
    /** The control; same as the default block. */
    field: [];
    /** Renders each error (while `@isInvalid`); yields the error. */
    errors: [string?];
    /** Custom help text, instead of `@helpText`. */
    helpText: [string?];
    /** Content at the end of the label line, e.g. a help link. */
    labelAppend: [];
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
    (argOrDefault @id (randomId))
    (argOrDefault @hasChildLabel true)
    (and (not (argOrDefault @isFakeLabelBlock false)) (has-block "label"))
    (and (not (argOrDefault @isFakeHelpTextBlock false)) (has-block "helpText"))
    as |classes fieldWrapperClasses errors isLegend focusedState rowId hasChildLabel hasLabelBlock hasHelpTextBlock|
  }}
    {{#if (eq @legendType "legend")}}
      <fieldset
        class={{classes}}
        id="{{rowId}}-row"
        ...attributes
        {{linkFormRowControl
          rowId
          helpText=(or @helpText hasHelpTextBlock)
          errorCount=(if @isInvalid errors.length 0)
        }}
      >
        {{#if (or @label @labelAppend hasLabelBlock (has-block "labelAppend"))}}
          <div class="euiFormRow__labelWrapper">
            {{#if isLegend}}
              {{#if hasLabelBlock}}
                <EuiFormLabel
                  class="euiFormRow__label"
                  for={{rowId}}
                  aria-invalid={{if @isInvalid "true"}}
                  @isInvalid={{@isInvalid}}
                  @type={{@labelType}}
                >
                  {{yield @label to="label"}}
                </EuiFormLabel>
              {{else}}
                <EuiFormLabel
                  class="euiFormRow__label"
                  for={{rowId}}
                  aria-invalid={{if @isInvalid "true"}}
                  @isInvalid={{@isInvalid}}
                  @type={{@labelType}}
                >
                  {{@label}}
                </EuiFormLabel>
              {{/if}}
            {{else if hasLabelBlock}}
              <EuiFormLabel
                class="euiFormRow__label"
                aria-invalid={{if @isInvalid "true"}}
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
                aria-invalid={{if @isInvalid "true"}}
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
            {{#if (has-block "labelAppend")}}
              {{yield to="labelAppend"}}
            {{else if @labelAppend}}
              {{@labelAppend}}
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
          {{#if (or @helpText hasHelpTextBlock)}}
            {{#if hasHelpTextBlock}}
              <EuiFormHelpText id="{{rowId}}-help" class={{@helpTextClasses}}>
                {{yield @helpText to="helpText"}}
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
      <div
        class={{classes}}
        id="{{rowId}}-row"
        ...attributes
        {{linkFormRowControl
          rowId
          helpText=(or @helpText hasHelpTextBlock)
          errorCount=(if @isInvalid errors.length 0)
        }}
      >
        {{#if (or @label @labelAppend hasLabelBlock (has-block "labelAppend"))}}
          <div class="euiFormRow__labelWrapper">
            {{#if isLegend}}
              {{#if hasLabelBlock}}
                <EuiFormLabel
                  class="euiFormRow__label"
                  for={{rowId}}
                  aria-invalid={{if @isInvalid "true"}}
                  @isInvalid={{@isInvalid}}
                  @type={{@labelType}}
                >
                  {{yield @label to="label"}}
                </EuiFormLabel>
              {{else}}
                <EuiFormLabel
                  class="euiFormRow__label"
                  for={{rowId}}
                  aria-invalid={{if @isInvalid "true"}}
                  @isInvalid={{@isInvalid}}
                  @type={{@labelType}}
                >
                  {{@label}}
                </EuiFormLabel>
              {{/if}}
            {{else if hasLabelBlock}}
              <EuiFormLabel
                class="euiFormRow__label"
                aria-invalid={{if @isInvalid "true"}}
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
                aria-invalid={{if @isInvalid "true"}}
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
            {{#if (has-block "labelAppend")}}
              {{yield to="labelAppend"}}
            {{else if @labelAppend}}
              {{@labelAppend}}
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

          {{#if (or @helpText hasHelpTextBlock)}}
            {{#if hasHelpTextBlock}}
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
