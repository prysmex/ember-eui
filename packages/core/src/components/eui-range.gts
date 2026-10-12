import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { later } from '@ember/runloop';
import { service } from '@ember/service';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, eq, not } from 'ember-truth-helpers';

import argOrDefault, {
  argOrDefaultDecorator
} from '../helpers/arg-or-default.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { rangeAriaValueText } from '../utils/eui/range.ts';
import {
  euiRangeStyles,
  getLevelColor
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { isWithinRange } from '../utils/number/index.ts';
import EuiInputPopover from './eui-input-popover.gts';
import EuiRangeHighlight from './eui-range-highlight.gts';
import EuiRangeInput from './eui-range-input.gts';
import EuiRangeLabel from './eui-range-label.gts';
import EuiRangeSlider from './eui-range-slider.gts';
import EuiRangeTooltip from './eui-range-tooltip.gts';
import EuiRangeTrack from './eui-range-track.gts';
import EuiRangeWrapper from './eui-range-wrapper.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiRangeLevel } from './eui-range-levels';
import type { EuiRangeTick } from './eui-range-ticks';

export interface EuiRangeArgs {
  /** Smaller slider, for dense forms. Defaults to `false`. */
  compressed?: boolean;
  /** Makes the number input read-only. */
  readOnly?: boolean;
  /** Stretches the slider to its container's width. Defaults to `false`. */
  fullWidth?: boolean;
  /** Id of the slider. Defaults to a generated id. */
  id?: string;
  /**
   * Create colored indicators for certain intervals
   */
  levels?: EuiRangeLevel[];
  /** Increment between values. Defaults to `1`. */
  step?: number;
  /**
   * Pass `true` to displays an extra input control for direct manipulation.
   * Pass `'inputWithPopover'` to only show the input but show the range in a dropdown.
   */
  showInput?: boolean | 'inputWithPopover';
  /**
   * Shows static min/max labels on the sides of the range slider.
   * Defaults to `false`.
   */
  showLabels?: boolean;
  /**
   * Shows a thick line from min to value. Defaults to `false`.
   */
  showRange?: boolean;
  /**
   * Shows clickable tick marks and labels at the given interval
   * (`step`/`tickInterval`). Defaults to `false`.
   */
  showTicks?: boolean;

  /** Lowest selectable value. Defaults to `0`. */
  min?: number;
  /** Highest selectable value. Defaults to `100`. */
  max?: number;
  /**
   * Shows the value in a tooltip above the thumb. Defaults to `false`.
   */
  showValue?: boolean;
  /**
   * Specified ticks at specified values
   */
  ticks?: EuiRangeTick[];
  /**
   * Modifies the number of tick marks and at what interval
   */
  tickInterval?: number;
  /**
   * Appends to the tooltip
   */
  valueAppend?: any;
  /**
   * Prepends to the tooltip
   */
  valuePrepend?: any;

  /**
   * Called with the event (read `event.target.value`, a string) and whether
   * the value is within `@min`/`@max`. Update `@value` here.
   */
  onChange?: (event: Event, isValid: boolean) => void;
  /** Called when the slider or input loses focus. */
  onBlur?: (event: Event) => void;
  /** Called when the slider or input gets focus. */
  onFocus?: (event: Event) => void;

  /** The value. */
  value?: number;

  /** Disables the slider and input. */
  disabled?: boolean;

  /** @private Show the `<:prepend>` block. Defaults to `true`. */
  isPrependProvided?: boolean;
  /** @private Show the `<:append>` block. Defaults to `true`. */
  isAppendProvided?: boolean;
  /** @private Ignore the `<:max>` block. */
  isFakeMaxBlock?: boolean;
  /** @private Ignore the `<:min>` block. */
  isFakeMinBlock?: boolean;
  /** @private Ignore the `<:value>` block. */
  isFakeValueBlock?: boolean;
  /** @private Ignore the `<:valueAppend>` block. */
  isFakeValueAppendBlock?: boolean;
  /** @private Ignore the `<:valuePrepend>` block. */
  isFakeValuePrependBlock?: boolean;
  /** Shows the invalid state. */
  isInvalid?: boolean;
  /** `name` of the inputs, for forms. */
  name?: string;
  /**
   * Shows a spinner in the number input (`@showInput="inputWithPopover"`).
   * Defaults to `false`.
   */
  isLoading?: boolean;
}

/**
 * A slider to pick a number, optionally with a number input, ticks,
 * levels and a value tooltip. For a range of two values use EuiDualRange.
 */
export interface EuiRangeSignature {
  Element: HTMLInputElement;
  Args: EuiRangeArgs;
  Blocks: {
    /** Custom min label (`@showLabels`); yields `@min`. */
    min: [min: number];
    /** Custom max label (`@showLabels`); yields `@max`. */
    max: [max: number];
    /** Custom value tooltip content (`@showValue`). */
    value: [];
    /** Content after the value in the tooltip, e.g. a unit. */
    valueAppend: [];
    /** Content before the value in the tooltip, e.g. a currency sign. */
    valuePrepend: [];
    /** Content before the number input (`@showInput`); yields its class. */
    prepend: [classes: string];
    /** Content after the number input (`@showInput`); yields its class. */
    append: [classes: string];
    /** Unused. */
    input: [];
    /** Unused. */
    content: [];
  };
}

export default class EuiRangeComponent extends Component<EuiRangeSignature> {
  // Defaults
  @argOrDefaultDecorator(0) min!: number;
  @argOrDefaultDecorator(100) max!: number;
  @argOrDefaultDecorator(1) step!: number;
  @argOrDefaultDecorator(false) fullWidth!: boolean;
  @argOrDefaultDecorator(false) compressed!: boolean;
  @argOrDefaultDecorator(false) isLoading!: boolean;
  @argOrDefaultDecorator(false) showLabels!: boolean;
  @argOrDefaultDecorator(false) showInput!: boolean | string;
  @argOrDefaultDecorator(false) showRange!: boolean;
  @argOrDefaultDecorator(false) showTicks!: boolean;
  @argOrDefaultDecorator(false) showValue!: boolean;
  @argOrDefaultDecorator([]) levels!: EuiRangeLevel[];

  @service declare euiI18n: EuiI18n;

  preventPopoverClose = false;

  //State
  @tracked id: string = this.args.id || guidFor({});
  @tracked isPopoverOpen = false;
  ///

  @action
  handleOnChange(e: Event): void {
    const isValid = isWithinRange(
      this.min,
      this.max,
      (e.currentTarget as HTMLInputElement).value
    );

    if (this.args.onChange) {
      this.args.onChange(e, isValid);
    }
  }

  get isValid(): boolean {
    return isWithinRange(this.min, this.max, this.args.value ?? '');
  }

  get digitTolerance(): number {
    return Math.max(String(this.min).length, String(this.max).length);
  }

  get showInputOnly(): boolean {
    return this.showInput === 'inputWithPopover';
  }

  get canShowDropdown(): boolean {
    return this.showInputOnly && !this.args.readOnly && !this.args.disabled;
  }

  get numberValue(): number {
    return Number(this.args.value);
  }

  get showRangeTooltip(): boolean {
    return (
      this.showValue &&
      !!String(this.args.value).length &&
      this.args.value !== undefined
    );
  }

  get context() {
    return getEuiThemeContext(this);
  }

  /** Upstream root styles (`euiRange` + `hasInput`) composed into the wrapper. */
  @cached
  get rootCss() {
    const styles = useEuiBorealisStyles(this.context, euiRangeStyles);
    return [styles.euiRange, this.showInput && styles.hasInput];
  }

  /** `euiRange__slimHorizontalSpacer` with ticks, else `euiRange__horizontalSpacer`. */
  @cached
  get spacerClass(): string {
    const styles = useEuiBorealisStyles(this.context, euiRangeStyles);
    const slim = this.showTicks || !!this.args.ticks;
    return slim
      ? `euiRange__slimHorizontalSpacer ${euiClass(this.context, styles.euiRange__slimHorizontalSpacer)}`
      : `euiRange__horizontalSpacer ${euiClass(this.context, styles.euiRange__horizontalSpacer)}`;
  }

  /** The level color the value falls into, for the thumb. */
  get thumbColor(): string | undefined {
    return getLevelColor(this.levels ?? [], Number(this.args.value));
  }

  get ariaValueText(): string | undefined {
    return this.args.ticks
      ? rangeAriaValueText(this.args.ticks, this.args.value)
      : undefined;
  }

  get screenReaderInstructions(): string {
    return this.euiI18n.lookupToken(
      'euiRange.sliderScreenReaderInstructions',
      'You are in a custom range slider. Use the Up and Down arrow keys to change the value.'
    );
  }

  @action
  onInputFocus(e: Event): void {
    if (this.args.onFocus) {
      this.args.onFocus(e);
    }

    this.isPopoverOpen = true;
  }

  @action
  onInputBlur(e: Event): void {
    later(
      this,
      () => {
        // Safari does not recognize any focus-related eventing for input[type=range]
        // making it impossible to capture its state using active/focus/relatedTarget
        // Instead, a prevention flag is set on mousedown, with a waiting period here.
        // Mousedown is viable because in the popover case, it is inaccessible via keyboard (intentionally)
        if (this.preventPopoverClose) {
          this.preventPopoverClose = false;

          return;
        }

        if (this.args.onBlur) {
          this.args.onBlur(e);
        }

        this.closePopover();
      },
      200
    );
  }

  @action
  setPreventPopover(val: boolean): void {
    this.preventPopoverClose = val;
  }

  @action
  closePopover(): void {
    this.preventPopoverClose = false;
    this.isPopoverOpen = false;
  }

  @action
  setPreventPopoverClose(bool: boolean): void {
    this.preventPopoverClose = bool;
  }

  <template>
    {{#let
      (and (argOrDefault @isPrependProvided true) (has-block "prepend"))
      (and (argOrDefault @isAppendProvided true) (has-block "append"))
      (and (not (argOrDefault @isFakeMaxBlock false)) (has-block "max"))
      (and (not (argOrDefault @isFakeMinBlock false)) (has-block "min"))
      (and (not (argOrDefault @isFakeValueBlock false)) (has-block "value"))
      (and
        (not (argOrDefault @isFakeValueAppendBlock false))
        (has-block "valueAppend")
      )
      (and
        (not (argOrDefault @isFakeValuePrependBlock false))
        (has-block "valuePrepend")
      )
      as |hasPrepend hasAppend hasMaxBlock hasMinBlock hasValueBlock hasValueAppendBlock hasValuePrependBlock|
    }}
      {{#if this.showInputOnly}}
        <EuiInputPopover
          class="euiRange__popover"
          @fullWidth={{@fullWidth}}
          @isOpen={{this.isPopoverOpen}}
          @closePopover={{this.closePopover}}
          @disableFocusTrap={{true}}
          @popoverScreenReaderText={{this.screenReaderInstructions}}
        >
          <:input>
            <EuiRangeInput
              id={{this.id}}
              @min={{this.min}}
              @max={{this.max}}
              @readOnly={{@readOnly}}
              @step={{this.step}}
              @value={{@value}}
              @disabled={{@disabled}}
              @compressed={{@compressed}}
              @name={{@name}}
              @fullWidth={{and this.showInputOnly this.fullWidth}}
              @isLoading={{and this.showInputOnly @isLoading}}
              @isInvalid={{@isInvalid}}
              @autoSize={{not this.showInputOnly}}
              @isPrependProvided={{hasPrepend}}
              @isAppendProvided={{hasAppend}}
              ...attributes
              {{on "focus" (if this.canShowDropdown this.onInputFocus (optional @onFocus))}}
              {{on "blur" (if this.canShowDropdown this.onInputBlur (optional @onBlur))}}
              {{on "input" this.handleOnChange}}
            >
              <:prepend as |classes|>
                {{yield classes to="prepend"}}
              </:prepend>
              <:append as |classes|>
                {{yield classes to="append"}}
              </:append>
            </EuiRangeInput>
          </:input>
          <:content>
            <EuiRangeWrapper
              class="euiRange"
              @css={{this.rootCss}}
              @fullWidth={{@fullWidth}}
              @compressed={{@compressed}}
            >
              {{#if this.showLabels}}
                <EuiRangeLabel @side="min" @disabled={{@disabled}}>
                  {{#if hasMinBlock}}
                    {{yield this.min to="min"}}
                  {{else}}
                    {{this.min}}
                  {{/if}}
                </EuiRangeLabel>
              {{/if}}
              <EuiRangeTrack
                aria-hidden={{if this.showInput "true"}}
                @disabled={{@disabled}}
                @compressed={{@compressed}}
                @max={{this.max}}
                @min={{this.min}}
                @step={{this.step}}
                @showTicks={{this.showTicks}}
                @showRange={{this.showRange}}
                @tickInterval={{@tickInterval}}
                @ticks={{@ticks}}
                @levels={{this.levels}}
                @onChange={{this.handleOnChange}}
                @value={{@value}}
                as |trackWidth|
              >
                <EuiRangeSlider
                  aria-hidden={{if this.showInput "true"}}
                  tabindex={{if this.showInput "-1"}}
                  @id={{if this.showInput undefined this.id}}
                  @name={{@name}}
                  @min={{this.min}}
                  @max={{this.max}}
                  @step={{this.step}}
                  @value={{@value}}
                  @disabled={{@disabled}}
                  @showTicks={{this.showTicks}}
                  @showRange={{this.showRange}}
                  @thumbColor={{this.thumbColor}}
                  @ariaValueText={{this.ariaValueText}}
                  ...attributes
                  {{on "mousedown" (if this.showInputOnly (fn this.setPreventPopoverClose true) (optional))}}
                  {{on "focus" (if (eq this.showInput true) (optional) (optional @onFocus))}}
                  {{on "blur" (if this.showInputOnly this.onInputBlur (optional @onBlur))}}
                  {{on "input" this.handleOnChange}}
                />
                {{#if (and this.showRange this.isValid)}}
                  <EuiRangeHighlight
                    @showTicks={{this.showTicks}}
                    @min={{this.min}}
                    @max={{this.max}}
                    @lowerValue={{this.min}}
                    @upperValue={{this.numberValue}}
                    @levels={{this.levels}}
                    @trackWidth={{trackWidth}}
                  />
                {{/if}}
                {{#if this.showRangeTooltip}}
                  <EuiRangeTooltip
                    @value={{@value}}
                    @max={{this.max}}
                    @min={{this.min}}
                    @name={{@name}}
                    @showTicks={{this.showTicks}}
                  >
                    <:valuePrepend>{{~#if hasValuePrependBlock~}}{{yield to="valuePrepend"}}{{~else~}}{{@valuePrepend}}{{~/if~}}</:valuePrepend>
                    <:value>{{~#if hasValueBlock~}}{{yield to="value"}}{{~else~}}{{@value}}{{~/if~}}</:value>
                    <:valueAppend>{{~#if hasValueAppendBlock~}}{{yield to="valueAppend"}}{{~else~}}{{@valueAppend}}{{~/if~}}</:valueAppend>
                  </EuiRangeTooltip>
                {{/if}}
              </EuiRangeTrack>
              {{#if this.showLabels}}
                <EuiRangeLabel @side="max" @disabled={{@disabled}}>
                  {{#if hasMaxBlock}}
                    {{yield this.max to="max"}}
                  {{else}}
                    {{this.max}}
                  {{/if}}
                </EuiRangeLabel>
              {{/if}}
              {{#if (and this.showInput (not this.showInputOnly))}}
                <div class={{this.spacerClass}}></div>
                <EuiRangeInput
                  id={{this.id}}
                  @min={{this.min}}
                  @max={{this.max}}
                  @readOnly={{@readOnly}}
                  @step={{this.step}}
                  @value={{@value}}
                  @disabled={{@disabled}}
                  @compressed={{@compressed}}
                  @name={{@name}}
                  @fullWidth={{and this.showInputOnly this.fullWidth}}
                  @isLoading={{and this.showInputOnly @isLoading}}
                  @isInvalid={{@isInvalid}}
                  @autoSize={{not this.showInputOnly}}
                  @isPrependProvided={{hasPrepend}}
                  @isAppendProvided={{hasAppend}}
                  ...attributes
                  {{on "focus" (if this.canShowDropdown this.onInputFocus (optional @onFocus))}}
                  {{on "blur" (if this.canShowDropdown this.onInputBlur (optional @onBlur))}}
                  {{on "input" this.handleOnChange}}
                >
                  <:prepend as |classes|>
                    {{yield classes to="prepend"}}
                  </:prepend>
                  <:append as |classes|>
                    {{yield classes to="append"}}
                  </:append>
                </EuiRangeInput>
              {{/if}}
            </EuiRangeWrapper>
          </:content>
        </EuiInputPopover>
      {{else}}
        <EuiRangeWrapper
          class="euiRange"
          @css={{this.rootCss}}
          @fullWidth={{@fullWidth}}
          @compressed={{@compressed}}
        >
          {{#if this.showLabels}}
            <EuiRangeLabel @side="min" @disabled={{@disabled}}>
              {{#if hasMinBlock}}
                {{yield this.min to="min"}}
              {{else}}
                {{this.min}}
              {{/if}}
            </EuiRangeLabel>
          {{/if}}
          <EuiRangeTrack
            aria-hidden={{if this.showInput "true"}}
            @disabled={{@disabled}}
            @compressed={{@compressed}}
            @max={{this.max}}
            @min={{this.min}}
            @step={{this.step}}
            @showTicks={{this.showTicks}}
            @showRange={{this.showRange}}
            @tickInterval={{@tickInterval}}
            @ticks={{@ticks}}
            @levels={{this.levels}}
            @onChange={{this.handleOnChange}}
            @value={{@value}}
            as |trackWidth|
          >
            <EuiRangeSlider
              aria-hidden={{if this.showInput "true"}}
              tabindex={{if this.showInput "-1"}}
              @id={{if this.showInput undefined this.id}}
              @name={{@name}}
              @min={{this.min}}
              @max={{this.max}}
              @step={{this.step}}
              @value={{@value}}
              @disabled={{@disabled}}
              @showTicks={{this.showTicks}}
              @showRange={{this.showRange}}
              @thumbColor={{this.thumbColor}}
              @ariaValueText={{this.ariaValueText}}
              ...attributes
              {{on "mousedown" (if this.showInputOnly (fn this.setPreventPopoverClose true) (optional))}}
              {{on "focus" (if (eq this.showInput true) (optional) (optional @onFocus))}}
              {{on "blur" (if this.showInputOnly this.onInputBlur (optional @onBlur))}}
              {{on "input" this.handleOnChange}}
            />
            {{#if (and this.showRange this.isValid)}}
              <EuiRangeHighlight
                @showTicks={{this.showTicks}}
                @min={{this.min}}
                @max={{this.max}}
                @lowerValue={{this.min}}
                @upperValue={{this.numberValue}}
                @levels={{this.levels}}
                @trackWidth={{trackWidth}}
              />
            {{/if}}
            {{#if this.showRangeTooltip}}
              <EuiRangeTooltip
                @value={{@value}}
                @max={{this.max}}
                @min={{this.min}}
                @name={{@name}}
                @showTicks={{this.showTicks}}
              >
                <:valuePrepend>{{~#if hasValuePrependBlock~}}{{yield to="valuePrepend"}}{{~else~}}{{@valuePrepend}}{{~/if~}}</:valuePrepend>
                <:value>{{~#if hasValueBlock~}}{{yield to="value"}}{{~else~}}{{@value}}{{~/if~}}</:value>
                <:valueAppend>{{~#if hasValueAppendBlock~}}{{yield to="valueAppend"}}{{~else~}}{{@valueAppend}}{{~/if~}}</:valueAppend>
              </EuiRangeTooltip>
            {{/if}}
          </EuiRangeTrack>
          {{#if this.showLabels}}
            <EuiRangeLabel @side="max" @disabled={{@disabled}}>
              {{#if hasMaxBlock}}
                {{yield this.max to="max"}}
              {{else}}
                {{this.max}}
              {{/if}}
            </EuiRangeLabel>
          {{/if}}
          {{#if (and this.showInput (not this.showInputOnly))}}
            <div class={{this.spacerClass}}></div>
            <EuiRangeInput
              id={{this.id}}
              @min={{this.min}}
              @max={{this.max}}
              @readOnly={{@readOnly}}
              @step={{this.step}}
              @value={{@value}}
              @disabled={{@disabled}}
              @compressed={{@compressed}}
              @name={{@name}}
              @fullWidth={{and this.showInputOnly this.fullWidth}}
              @isLoading={{and this.showInputOnly @isLoading}}
              @isInvalid={{@isInvalid}}
              @autoSize={{not this.showInputOnly}}
              @isPrependProvided={{hasPrepend}}
              @isAppendProvided={{hasAppend}}
              ...attributes
              {{on "focus" (if this.canShowDropdown this.onInputFocus (optional @onFocus))}}
              {{on "blur" (if this.canShowDropdown this.onInputBlur (optional @onBlur))}}
              {{on "input" this.handleOnChange}}
            >
              <:prepend as |classes|>
                {{yield classes to="prepend"}}
              </:prepend>
              <:append as |classes|>
                {{yield classes to="append"}}
              </:append>
            </EuiRangeInput>
          {{/if}}
        </EuiRangeWrapper>
      {{/if}}
    {{/let}}
  </template>
}
