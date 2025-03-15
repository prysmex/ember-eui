import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { later } from '@ember/runloop';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, eq, not } from 'ember-truth-helpers';

import argOrDefault, {
  argOrDefaultDecorator
} from '../helpers/arg-or-default.ts';
import castTo from '../helpers/cast-to.ts';
import classNames from '../helpers/class-names.ts';
import { isWithinRange } from '../utils/number/index.ts';
import EuiInputPopover from './eui-input-popover.gts';
import EuiRangeHighlight from './eui-range-highlight.gts';
import EuiRangeInput from './eui-range-input.gts';
import EuiRangeLabel from './eui-range-label.gts';
import EuiRangeSlider from './eui-range-slider.gts';
import EuiRangeTooltip from './eui-range-tooltip.gts';
import EuiRangeTrack from './eui-range-track.gts';
import EuiRangeWrapper from './eui-range-wrapper.gts';

import type { EuiRangeLevel } from './eui-range-levels';
import type { EuiRangeTick } from './eui-range-ticks';

export interface EuiRangeArgs {
  compressed?: boolean;
  readOnly?: boolean;
  fullWidth?: boolean;
  id?: string;
  /**
   * Create colored indicators for certain intervals
   */
  levels?: EuiRangeLevel[];
  step?: number;
  /**
   * Pass `true` to displays an extra input control for direct manipulation.
   * Pass `'inputWithPopover'` to only show the input but show the range in a dropdown.
   */
  showInput?: boolean | 'inputWithPopover';
  /**
   * Shows static min/max labels on the sides of the range slider
   */
  showLabels?: boolean;
  /**
   * Shows a thick line from min to value
   */
  showRange?: boolean;
  /**
   * Shows clickable tick marks and labels at the given interval (`step`/`tickInterval`)
   */
  showTicks?: boolean;

  min?: number;
  max?: number;
  /**
   * Shows a tooltip styled value
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

  onChange?: (event: Event, isValid: boolean) => void;
  onBlur?: (event: Event) => void;
  onFocus?: (event: Event) => void;

  value?: number;

  disabled?: boolean;

  isPrependProvided?: boolean;
  isAppendProvided?: boolean;
  isFakeMaxBlock?: boolean;
  isFakeMinBlock?: boolean;
  isFakeValueBlock?: boolean;
  isFakeValueAppendBlock?: boolean;
  isFakeValuePrependBlock?: boolean;
  isInvalid?: boolean;
  name?: string;
  isLoading?: boolean;
}

export interface EuiRangeSignature {
  Element: HTMLInputElement;
  Args: EuiRangeArgs;
  Blocks: {
    min: [min: number];
    max: [max: number];
    value: [];
    valueAppend: [];
    valuePrepend: [];
    prepend: [classes: string];
    append: [classes: string];
    input: [];
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
    return isWithinRange(this.min, this.max, this.args.value || '');
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

  get showRangeTooltip(): boolean {
    return (
      this.showValue &&
      !!String(this.args.value).length &&
      this.args.value !== undefined
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
        >
          <:input>
            <EuiRangeInput
              id={{this.id}}
              @min={{this.min}}
              @max={{this.max}}
              @digitTolerance={{this.digitTolerance}}
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
              {{on
                "focus"
                (if this.canShowDropdown this.onInputFocus (optional @onFocus))
              }}
              {{on
                "blur"
                (if this.canShowDropdown this.onInputBlur (optional @onBlur))
              }}
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
              class={{classNames
                "euiRange"
                (if this.showInput "euiRange--hasInput")
              }}
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
                aria-hidden={{eq this.showInput true}}
                @disabled={{@disabled}}
                @compressed={{@compressed}}
                @max={{this.max}}
                @min={{this.min}}
                @step={{this.step}}
                @showTicks={{this.showTicks}}
                @tickInterval={{@tickInterval}}
                @ticks={{@ticks}}
                @levels={{this.levels}}
                @onChange={{this.handleOnChange}}
                @value={{@value}}
              >
                {{#if (and this.showRange this.isValid)}}
                  <EuiRangeHighlight
                    @compressed={{@compressed}}
                    @showTicks={{this.showTicks}}
                    {{!@glint-expect-error}}
                    @min={{castTo this.min to="number"}}
                    {{!@glint-expect-error}}
                    @max={{castTo this.max to="number"}}
                    {{!@glint-expect-error}}
                    @lowerValue={{castTo this.min to="number"}}
                    {{!@glint-expect-error}}
                    @upperValue={{castTo @value to="number"}}
                  />
                {{/if}}
                <EuiRangeSlider
                  aria-hidden={{if (eq this.showInput true) true false}}
                  tabindex={{if (eq this.showInput true) "-1"}}
                  @id={{if this.showInput undefined this.id}}
                  @name={{@name}}
                  @min={{this.min}}
                  @max={{this.max}}
                  @step={{this.step}}
                  @value={{@value}}
                  @disabled={{@disabled}}
                  @compressed={{@compressed}}
                  @showTicks={{this.showTicks}}
                  @showRange={{this.showRange}}
                  ...attributes
                  {{on
                    "mousedown"
                    (if
                      this.showInputOnly
                      (fn this.setPreventPopoverClose true)
                      (optional)
                    )
                  }}
                  {{on
                    "focus"
                    (if (eq this.showInput true) (optional) (optional @onFocus))
                  }}
                  {{on
                    "blur"
                    (if this.showInputOnly this.onInputBlur (optional @onBlur))
                  }}
                  {{on "input" this.handleOnChange}}
                />
                {{#if this.showRangeTooltip}}
                  <EuiRangeTooltip
                    @compressed={{@compressed}}
                    @value={{@value}}
                    @max={{this.max}}
                    @min={{this.min}}
                    @name={{@name}}
                    @showTicks={{this.showTicks}}
                  >
                    <:valuePrepend>
                      {{#if hasValuePrependBlock}}
                        {{yield to="valuePrepend"}}
                      {{else}}
                        {{@valuePrepend}}
                      {{/if}}
                    </:valuePrepend>
                    <:value>
                      {{#if hasValueBlock}}
                        {{yield to="value"}}
                      {{else}}
                        {{@value}}
                      {{/if}}
                    </:value>
                    <:valueAppend>
                      {{#if hasValueAppendBlock}}
                        {{yield to="valueAppend"}}
                      {{else}}
                        {{@valueAppend}}
                      {{/if}}
                    </:valueAppend>
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
                <div class="euiRange__horizontalSpacer"></div>
                {{#if this.showInput}}
                  <EuiRangeInput
                    id={{this.id}}
                    @min={{this.min}}
                    @max={{this.max}}
                    @digitTolerance={{this.digitTolerance}}
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
                    {{on
                      "focus"
                      (if
                        this.canShowDropdown
                        this.onInputFocus
                        (optional @onFocus)
                      )
                    }}
                    {{on
                      "blur"
                      (if
                        this.canShowDropdown this.onInputBlur (optional @onBlur)
                      )
                    }}
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
              {{/if}}
            </EuiRangeWrapper>
          </:content>
        </EuiInputPopover>
      {{else}}
        <EuiRangeWrapper
          class={{classNames
            "euiRange"
            (if this.showInput "euiRange--hasInput")
          }}
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
            aria-hidden={{eq this.showInput true}}
            @disabled={{@disabled}}
            @compressed={{@compressed}}
            @max={{this.max}}
            @min={{this.min}}
            @step={{this.step}}
            @showTicks={{this.showTicks}}
            @tickInterval={{@tickInterval}}
            @ticks={{@ticks}}
            @levels={{this.levels}}
            @onChange={{this.handleOnChange}}
            @value={{@value}}
          >
            {{#if (and this.showRange this.isValid)}}
              <EuiRangeHighlight
                @compressed={{@compressed}}
                @showTicks={{this.showTicks}}
                {{!@glint-expect-error}}
                @min={{castTo this.min to="number"}}
                {{!@glint-expect-error}}
                @max={{castTo this.max to="number"}}
                {{!@glint-expect-error}}
                @lowerValue={{castTo this.min to="number"}}
                {{!@glint-expect-error}}
                @upperValue={{castTo @value to="number"}}
              />
            {{/if}}
            <EuiRangeSlider
              aria-hidden={{if (eq this.showInput true) true false}}
              tabindex={{if (eq this.showInput true) "-1"}}
              @id={{if this.showInput undefined this.id}}
              @name={{@name}}
              @min={{this.min}}
              @max={{this.max}}
              @step={{this.step}}
              @value={{@value}}
              @disabled={{@disabled}}
              @compressed={{@compressed}}
              @showTicks={{this.showTicks}}
              @showRange={{this.showRange}}
              ...attributes
              {{on
                "mousedown"
                (if
                  this.showInputOnly (fn this.setPreventPopover true) (optional)
                )
              }}
              {{on
                "focus"
                (if (eq this.showInput true) (optional) (optional @onFocus))
              }}
              {{on
                "blur"
                (if this.showInputOnly this.onInputBlur (optional @onBlur))
              }}
              {{on "input" this.handleOnChange}}
            />
            {{#if this.showRangeTooltip}}
              <EuiRangeTooltip
                @compressed={{@compressed}}
                @value={{@value}}
                @max={{this.max}}
                @min={{this.min}}
                @name={{@name}}
                @showTicks={{this.showTicks}}
              >
                <:valuePrepend>
                  {{#if hasValuePrependBlock}}
                    {{yield to="valuePrepend"}}
                  {{else}}
                    {{@valuePrepend}}
                  {{/if}}
                </:valuePrepend>
                <:value>
                  {{#if hasValueBlock}}
                    {{yield to="value"}}
                  {{else}}
                    {{@value}}
                  {{/if}}
                </:value>
                <:valueAppend>
                  {{#if hasValueAppendBlock}}
                    {{yield to="valueAppend"}}
                  {{else}}
                    {{@valueAppend}}
                  {{/if}}
                </:valueAppend>
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
            <div class="euiRange__horizontalSpacer"></div>
            {{#if this.showInput}}
              <EuiRangeInput
                id={{this.id}}
                @min={{this.min}}
                @max={{this.max}}
                @digitTolerance={{this.digitTolerance}}
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
                {{on
                  "focus"
                  (if
                    this.canShowDropdown this.onInputFocus (optional @onFocus)
                  )
                }}
                {{on
                  "blur"
                  (if this.canShowDropdown this.onInputBlur (optional @onBlur))
                }}
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
          {{/if}}
        </EuiRangeWrapper>
      {{/if}}
    {{/let}}
  </template>
}
