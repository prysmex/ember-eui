import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import { and, not, or } from 'ember-truth-helpers';

import { euiFormFullWidth } from '../-private/eui-form-context.ts';
import linkFormRowControl from '../-private/link-form-row-control.ts';
import { randomId } from '../-private/random-id.ts';
import useState from '../helpers/use-state.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiFormLabelAppendStyles,
  euiFormRowStyles
} from '../utils/eui/styles.generated.ts';
import EuiFormErrorText from './eui-form-error-text.gts';
import { euiFieldsetReset } from './eui-form-fieldset.gts';
import EuiFormHelpText from './eui-form-help-text.gts';
import EuiFormLabel from './eui-form-label.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiText from './eui-text.gts';

/**
 * Row layouts. `rowCompressed` looks like `row` in the latest theme;
 * `columnCompressedSwitch` is kept as an alias of `columnCompressed`, which
 * now adapts to switches itself (upstream removed the separate display).
 */
export type EuiFormRowDisplay =
  | 'row'
  | 'rowCompressed'
  | 'columnCompressed'
  | 'columnCompressedSwitch'
  | 'center'
  | 'centerCompressed';

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
     * Text at the end of the label line, e.g. "Optional" (small subdued
     * text). Use the `<:labelAppend>` block for markup such as a help link.
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
    /**
     * Lets the row (and its control) take the container's full width
     * instead of the theme's form max width (400px in Borealis). Defaults to
     * the enclosing EuiForm's `@fullWidth`, else `false`.
     */
    fullWidth?: boolean;
    /** Shows `@error` under the control and styles the label as invalid. */
    isInvalid?: boolean;
    /**
     * Disables the label's focus state and pointer cursor (pass `@disabled`
     * to the control itself).
     */
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
    /**
     * Ids of other elements describing the control, added first to its
     * `aria-describedby` (before the help text and errors).
     */
    describedByIds?: string[];
    /** Extra classes for each error message. */
    errorClasses?: string;
    /** Extra classes for the help text. */
    helpTextClasses?: string;
    /** Id of the control; the label points to it. Defaults to a random id. */
    id?: string;
    /**
     * Layout: `'row'` (label above), `'columnCompressed'` (label beside, for
     * dense forms; also used for switches), or `'center'` /
     * `'centerCompressed'` (vertically centers content shorter than a
     * control, e.g. a switch or text next to rows). `'rowCompressed'` and
     * `'columnCompressedSwitch'` are kept as aliases of `'row'` and
     * `'columnCompressed'`. Defaults to `'row'`.
     */
    display?: EuiFormRowDisplay;
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
    /** Custom help text, instead of `@helpText`; yields `@helpText`. */
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

export default class EuiFormRow extends Component<EuiFormRowSignature> {
  private readonly generatedId = randomId();

  get rowId(): string {
    return this.args.id ?? this.generatedId;
  }

  get isFieldset(): boolean {
    return this.args.legendType === 'legend';
  }

  get tagName(): 'fieldset' | 'div' {
    return this.isFieldset ? 'fieldset' : 'div';
  }

  get isLegendLabel(): boolean {
    return this.args.labelType === 'legend';
  }

  /** The label's `for`: never on a legend, and not when `@hasChildLabel={{false}}`. */
  get labelFor(): string | undefined {
    if (this.isLegendLabel || this.args.hasChildLabel === false) return;
    return this.rowId;
  }

  /** Every `@error` (the `<:errors>` block is rendered once per item). */
  get errors(): (string | undefined)[] {
    const { error } = this.args;
    // `null` is passed through to the block as before.
    return (Array.isArray(error) ? error : [error]) as (string | undefined)[];
  }

  /** `@error` messages rendered without a block: an empty single error is skipped (upstream). */
  get errorMessages(): string[] {
    const { error } = this.args;
    if (Array.isArray(error)) return error;
    return error ? [error] : [];
  }

  get helpTexts(): string[] {
    const { helpText } = this.args;
    return Array.isArray(helpText) ? (helpText as string[]) : [helpText!];
  }

  get display(): keyof ReturnType<typeof euiFormRowStyles> {
    switch (this.args.display) {
      case 'columnCompressed':
      case 'columnCompressedSwitch':
        return 'columnCompressed';
      case 'rowCompressed':
      case 'center':
      case 'centerCompressed':
        return this.args.display;
      default:
        return 'row';
    }
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFormRowStyles);
    // Same order as upstream's `cssStyles`.
    return euiClass(
      context,
      this.isFieldset ? euiFieldsetReset : { boxSizing: 'border-box' },
      styles.euiFormRow,
      euiFormFullWidth(this, this.args.fullWidth)
        ? styles.fullWidth
        : styles.formWidth,
      styles[this.display] as string
    );
  }

  @cached
  get labelAppendClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFormLabelAppendStyles);
    return euiClass(
      context,
      { fontFamily: context.upstream.euiTheme.font.family },
      styles.euiFormLabelAppend
    );
  }

  <template>
    {{#let
      (element this.tagName)
      (useState false)
      (and (not @isFakeLabelBlock) (has-block "label"))
      (and (not @isFakeHelpTextBlock) (has-block "helpText"))
      as |Tag focusedState hasLabelBlock hasHelpTextBlock|
    }}
      {{#let
        (or @label @labelAppend hasLabelBlock (has-block "labelAppend"))
        as |hasLabel|
      }}
        <Tag
          class="euiFormRow
            {{if @hasEmptyLabelSpace 'euiFormRow--hasEmptyLabelSpace'}}
            {{if hasLabel 'euiFormRow--hasLabel'}}
            {{this.classes}}"
          id="{{this.rowId}}-row"
          ...attributes
          {{linkFormRowControl
            this.rowId
            helpText=(or @helpText hasHelpTextBlock)
            errorCount=(if @isInvalid this.errors.length 0)
            describedByIds=@describedByIds
          }}
        >
          {{#if hasLabel}}
            <div class="euiFormRow__labelWrapper">
              {{#if (or @label hasLabelBlock)}}
                <EuiFormLabel
                  class="euiFormRow__label"
                  id="{{this.rowId}}-label"
                  aria-invalid={{if @isInvalid "true"}}
                  @for={{this.labelFor}}
                  @type={{@labelType}}
                  @isInvalid={{@isInvalid}}
                  @isDisabled={{@isDisabled}}
                  @isFocused={{and
                    (not @isDisabled)
                    (not this.isLegendLabel)
                    focusedState.value
                  }}
                >
                  {{#if hasLabelBlock}}
                    {{yield @label to="label"}}
                  {{else}}
                    {{@label}}
                  {{/if}}
                </EuiFormLabel>
              {{/if}}
              {{#if (has-block "labelAppend")}}
                <EuiText @size="xs" class="euiFormRow__labelAppend">
                  {{yield to="labelAppend"}}
                </EuiText>
              {{else if @labelAppend}}
                <span
                  class="euiFormLabelAppend euiFormRow__labelAppend
                    {{this.labelAppendClasses}}"
                >{{@labelAppend}}</span>
              {{/if}}
            </div>
          {{else if @hasEmptyLabelSpace}}
            <EuiSpacer @size="m" class="euiFormRow__labelWrapper" />
          {{/if}}
          <div
            class="euiFormRow__fieldWrapper"
            {{on "focusin" (fn focusedState.setState true)}}
            {{on "focusout" (fn focusedState.setState false)}}
          >
            {{#if (has-block "field")}}
              {{yield to="field"}}
            {{else}}
              {{yield}}
            {{/if}}
            {{#if @isInvalid}}
              {{#if (has-block "errors")}}
                {{#each this.errors as |error i|}}
                  <EuiFormErrorText
                    class="euiFormRow__text {{@errorClasses}}"
                    id="{{this.rowId}}-error-{{i}}"
                  >
                    {{yield error to="errors"}}
                  </EuiFormErrorText>
                {{/each}}
              {{else}}
                {{#each this.errorMessages as |error i|}}
                  <EuiFormErrorText
                    class="euiFormRow__text {{@errorClasses}}"
                    id="{{this.rowId}}-error-{{i}}"
                  >
                    {{error}}
                  </EuiFormErrorText>
                {{/each}}
              {{/if}}
            {{/if}}
            {{#if hasHelpTextBlock}}
              <EuiFormHelpText
                id="{{this.rowId}}-help"
                class="euiFormRow__text {{@helpTextClasses}}"
              >
                {{yield @helpText to="helpText"}}
              </EuiFormHelpText>
            {{else if @helpText}}
              {{#if this.isFieldset}}
                {{! fieldset rows keep their single "-help" id }}
                <EuiFormHelpText
                  id="{{this.rowId}}-help"
                  class="euiFormRow__text {{@helpTextClasses}}"
                >
                  {{@helpText}}
                </EuiFormHelpText>
              {{else}}
                {{#each this.helpTexts as |helpText i|}}
                  <EuiFormHelpText
                    id="{{this.rowId}}-help-{{i}}"
                    class="euiFormRow__text {{@helpTextClasses}}"
                  >
                    {{helpText}}
                  </EuiFormHelpText>
                {{/each}}
              {{/if}}
            {{/if}}
          </div>
        </Tag>
      {{/let}}
    {{/let}}
  </template>
}
