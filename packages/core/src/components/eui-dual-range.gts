import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { later } from '@ember/runloop';

import optional from 'ember-composable-helpers/helpers/optional';
import onKey from 'ember-keyboard/modifiers/on-key';
import { and, eq, not, or } from 'ember-truth-helpers';

import argOrDefault, { argOrDefaultDecorator } from '../helpers/arg-or-default';
import castTo from '../helpers/cast-to';
import simpleStyle from '../modifiers/simple-style';
import { keys } from '../utils/keys';
import { isWithinRange } from '../utils/number';
import { EUI_THUMB_SIZE } from '../utils/range';
import EuiFormControlLayoutDelimited from './eui-form-control-layout-delimited.gts';
import EuiInputPopover from './eui-input-popover.gts';
import EuiRangeHighlight from './eui-range-highlight.gts';
import EuiRangeInput from './eui-range-input.gts';
import EuiRangeLabel from './eui-range-label.gts';
import EuiRangeSlider from './eui-range-slider.gts';
import EuiRangeThumb from './eui-range-thumb.gts';
import EuiRangeTrack from './eui-range-track.gts';
import EuiRangeWrapper from './eui-range-wrapper.gts';

import type {
  EuiRangeInputArgs,
  EuiRangeInputSignature
} from './eui-range-input.gts';
import type { EuiFormControlLayoutSignature } from './eui-form-control-layout.gts';
import type { EuiRangeArgs } from './eui-range.gts';
import type { EuiRangeLevel } from './eui-range-levels.gts';
import type { EuiRangeTick } from './eui-range-ticks.gts';

export type ValueMember = number | string;

export interface EuiDualRangeArgs {
  value: [ValueMember, ValueMember];
  onBlur?: (event: FocusEvent) => void;
  onFocus?: (event: FocusEvent) => void;
  onChange: (
    values: [ValueMember, ValueMember],
    isValid: boolean,
    event: Event | MouseEvent | KeyboardEvent
  ) => void;
  fullWidth?: boolean;
  isInvalid?: boolean;
  /**
   * Create colored indicators for certain intervals
   */
  levels?: EuiRangeLevel[];
  /**
   * Shows static min/max labels on the sides of the range slider
   */
  showLabels?: boolean;
  /**
   * Pass `true` to displays an extra input control for direct manipulation.
   * Pass `'inputWithPopover'` to only show the input but show the range in a dropdown.
   */
  showInput?: EuiRangeArgs['showInput'];
  /**
   * Modifies the number of tick marks and at what interval
   */
  tickInterval?: number;
  /**
   * Specified ticks at specified values
   */
  ticks?: EuiRangeTick[];
  /**
   * Creates an input group with element(s) coming before input.  Will only show if `showInput = inputWithPopover`.
   * `string` | `Component` or an array of these
   */
  prepend?: EuiFormControlLayoutSignature['Blocks']['prepend'];
  /**
   * Creates an input group with element(s) coming after input. Will only show if `showInput = inputWithPopover`.
   * `string` | `Component` or an array of these
   */
  append?: EuiFormControlLayoutSignature['Blocks']['append'];
  /**
   *  Intended to be uses with aria attributes. Some attributes may be overwritten.
   */
  minInputProps?: Partial<EuiRangeInputArgs>;

  /**
   *  Intended to be uses with aria attributes. Some attributes may be overwritten.
   */
  maxInputProps?: Partial<EuiRangeInputArgs>;

  readOnly?: boolean;

  disabled?: boolean;

  isPrependProvided?: boolean;

  isAppendProvided?: boolean;

  isFakeMaxBlock?: boolean;

  isFakeMinBlock?: boolean;

  disable?: boolean;

  ariaDescribedby?: string;

  ariaLabel?: string;

  name?: string;

  id?: string;

  compressed?: boolean;

  showRange?: boolean;

  showTicks?: boolean;

  step?: number;

  min?: number;

  max?: number;
}

export interface EuiDualRangeSignature {
  Element: EuiRangeInputSignature['Element'];
  Args: EuiDualRangeArgs;
  Blocks: {
    prepend: EuiRangeInputSignature['Blocks']['prepend'];
    append: EuiRangeInputSignature['Blocks']['append'];
    min: [number?];
    max: [number?];
  };
}

export default class EuiDualRangeComponent extends Component<EuiDualRangeSignature> {
  // Defaults
  @argOrDefaultDecorator(0) min!: number;
  @argOrDefaultDecorator(100) max!: number;
  @argOrDefaultDecorator(1) step!: number;
  @argOrDefaultDecorator(false) fullWidth!: boolean;
  @argOrDefaultDecorator(false) compressed!: boolean;
  @argOrDefaultDecorator(false) showLabels!: boolean;
  @argOrDefaultDecorator(false) showInput!: boolean | string;
  @argOrDefaultDecorator(true) showRange!: boolean;
  @argOrDefaultDecorator(false) showTicks!: boolean;
  @argOrDefaultDecorator([]) levels!: EuiRangeLevel[];

  //State
  @tracked id: string = this.args.id || guidFor({});
  @tracked hasFocus = false;
  @tracked rangeSliderRefAvailable = false;
  @tracked isPopoverOpen = false;
  @tracked rangeWidth: number | undefined;
  @tracked isVisible = true;
  ///

  preventPopoverClose = false;
  rangeSliderRef: HTMLInputElement | null = null;

  @action
  didInsertRangeSlider(ref: HTMLInputElement | null): void {
    this.rangeSliderRef = ref;

    this.rangeSliderRefAvailable = !!ref;
    this.rangeWidth = ref ? ref.clientWidth : undefined;

    if (this.rangeSliderRef?.clientWidth && !this.isVisible) {
      this.isVisible = true;
    }
  }

  get lowerValue(): ValueMember {
    return this.args.value ? this.args.value[0] : this.min;
  }

  get upperValue(): ValueMember {
    return this.args.value ? this.args.value[1] : this.max;
  }

  get lowerValueIsValid(): boolean {
    return isWithinRange(this.min, this.upperValue, this.lowerValue);
  }

  get upperValueIsValid(): boolean {
    return isWithinRange(this.lowerValue, this.max, this.upperValue);
  }

  get isValid(): boolean {
    return this.lowerValueIsValid && this.upperValueIsValid;
  }

  @action
  _determineInvalidThumbMovement(
    newVal: ValueMember,
    lower: ValueMember,
    upper: ValueMember,
    e: Event
  ): void {
    // If the values are invalid, find whether the new value is in the upper
    // or lower half and move the appropriate handle to the new value,
    // while the other handle gets moved to the opposite bound (if invalid)
    const lowerHalf = Math.abs(this.max - this.min) / 2 + this.min;
    const newValIsLow = isWithinRange(this.min, lowerHalf, newVal);
    if (newValIsLow) {
      lower = newVal;
      upper = !this.upperValueIsValid ? this.max : upper;
    } else {
      lower = !this.lowerValueIsValid ? this.min : lower;
      upper = newVal;
    }
    this._handleOnChange(lower, upper, e);
  }

  @action
  _determineValidThumbMovement(
    newVal: ValueMember,
    lower: ValueMember,
    upper: ValueMember,
    e: Event
  ): void {
    // Lower thumb targeted or right-moving swap has occurred
    if (
      Math.abs((lower as number) - (newVal as number)) <
      Math.abs((upper as number) - (newVal as number))
    ) {
      lower = newVal;
    }
    // Upper thumb targeted or left-moving swap has occurred
    else {
      upper = newVal;
    }
    this._handleOnChange(lower, upper, e);
  }

  @action
  _determineThumbMovement(newVal: number, e: Event): void {
    // Determine thumb movement based on slider interaction
    if (!this.isValid) {
      // Non-standard positioning follows
      this._determineInvalidThumbMovement(
        newVal,
        this.lowerValue,
        this.upperValue,
        e
      );
    } else {
      // Standard positioning based on click event proximity to thumb locations
      this._determineValidThumbMovement(
        newVal,
        this.lowerValue,
        this.upperValue,
        e
      );
    }
  }

  @action
  _handleOnChange(lower: ValueMember, upper: ValueMember, e: Event): void {
    const isValid =
      isWithinRange(this.min, upper, lower) &&
      isWithinRange(lower, this.max, upper);
    this.args.onChange([lower, upper], isValid, e);
  }

  @action
  handleSliderChange(e: Event): void {
    this._determineThumbMovement(
      Number((e.currentTarget as HTMLInputElement).value),
      e
    );
  }

  @action
  _resetToRangeEnds(e: KeyboardEvent): void {
    // Arbitrary decision to pass `min` instead of `max`. Result is the same.
    this._determineInvalidThumbMovement(
      this.min,
      this.lowerValue,
      this.upperValue,
      e
    );
  }

  @action
  _isDirectionalKeyPress(event: KeyboardEvent): boolean {
    return (
      [
        keys.ARROW_UP,
        keys.ARROW_RIGHT,
        keys.ARROW_DOWN,
        keys.ARROW_LEFT
      ].indexOf(event.key as keys) > -1
    );
  }

  @action
  handleInputKeyDown(e: KeyboardEvent): void {
    // Relevant only when initial values are both `''` and `showInput` is set
    if (this._isDirectionalKeyPress(e) && !this.isValid) {
      e.preventDefault();
      this._resetToRangeEnds(e);
    }
  }

  @action
  handleLowerInputChange(e: Event): void {
    this._handleOnChange(
      (e.target as HTMLInputElement).value,
      this.upperValue,
      e
    );
  }

  @action
  handleUpperInputChange(e: Event): void {
    this._handleOnChange(
      this.lowerValue,
      (e.target as HTMLInputElement).value,
      e
    );
  }

  @action
  _handleKeyDown(value: ValueMember, event: KeyboardEvent): number {
    let newVal = Number(value);
    let stepRemainder = 0;
    const step = this.args.step || 1;
    switch (event.key) {
      case keys.ARROW_UP:
      case keys.ARROW_RIGHT:
        event.preventDefault();
        newVal += step;
        stepRemainder = (newVal - this.min) % step;
        if (step !== 1 && stepRemainder > 0) {
          newVal = newVal - stepRemainder;
        }
        break;
      case keys.ARROW_DOWN:
      case keys.ARROW_LEFT:
        event.preventDefault();
        newVal -= step;
        stepRemainder = (newVal - this.min) % step;
        if (step !== 1 && stepRemainder > 0) {
          newVal = newVal + (step - stepRemainder);
        }
        break;
    }
    return newVal;
  }

  @action
  handleLowerKeyDown(event: KeyboardEvent): void {
    let lower = this.lowerValue;
    switch (event.key) {
      case keys.TAB:
        return;
      default:
        if (!this.lowerValueIsValid) {
          // Relevant only when initial value is `''` and `showInput` is not set
          event.preventDefault();
          this._resetToRangeEnds(event);
          return;
        }
        lower = this._handleKeyDown(lower, event);
    }
    if (lower >= (this.upperValue as number) || lower < this.min) return;
    this._handleOnChange(lower, this.upperValue, event);
  }

  @action
  handleUpperKeyDown(event: KeyboardEvent): void {
    let upper = this.upperValue;
    switch (event.key) {
      case keys.TAB:
        return;
      default:
        if (!this.upperValueIsValid) {
          // Relevant only when initial value is `''` and `showInput` is not set
          event.preventDefault();
          this._resetToRangeEnds(event);
          return;
        }
        upper = this._handleKeyDown(upper, event);
    }
    if (upper <= (this.lowerValue as number) || upper > this.max) return;
    this._handleOnChange(this.lowerValue, upper, event);
  }

  @action
  calculateThumbPositionStyle(value: number, width?: number): { left: string } {
    // Calculate the left position based on value
    const decimal = (value - this.min) / (this.max - this.min);
    // Must be between 0-100%
    let valuePosition = decimal <= 1 ? decimal : 1;
    valuePosition = valuePosition >= 0 ? valuePosition : 0;

    const trackWidth =
      this.args.showInput === 'inputWithPopover' && !!width
        ? width
        : this.rangeSliderRef?.clientWidth;

    let thumbToTrackRatio = 0;
    if (trackWidth) {
      thumbToTrackRatio = EUI_THUMB_SIZE / trackWidth;
    } else {
      thumbToTrackRatio = EUI_THUMB_SIZE / 1;
    }
    const trackPositionScale = (1 - thumbToTrackRatio) * 100;
    return { left: `${valuePosition * trackPositionScale}%` };
  }

  @action
  setPreventPopoverClose(value: boolean): void {
    this.preventPopoverClose = value;
  }

  get calculateLowerValueThumbPositionStyle(): { left: string } {
    return this.calculateThumbPositionStyle(
      Number(this.lowerValue) || this.min,
      this.rangeWidth
    );
  }

  get calculateUpperValueThumbPositionStyle(): { left: string } {
    return this.calculateThumbPositionStyle(
      Number(this.upperValue) || this.max,
      this.rangeWidth
    );
  }

  @action
  toggleHasFocus(): void {
    this.hasFocus = !this.hasFocus;
  }

  @action
  onThumbFocus(e: FocusEvent): void {
    if (this.args.onFocus) {
      this.args.onFocus(e);
    }
    this.hasFocus = true;
  }

  @action
  onThumbBlur(e: FocusEvent): void {
    if (this.args.onBlur) {
      this.args.onBlur(e);
    }
    this.hasFocus = false;
  }

  @action
  onInputFocus(e: FocusEvent): void {
    if (this.args.onFocus) {
      this.args.onFocus(e);
    }
    this.preventPopoverClose = true;
    this.isPopoverOpen = true;
  }

  @action
  onInputBlur(e: FocusEvent): void {
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
  closePopover(): void {
    this.preventPopoverClose = false;
    this.isPopoverOpen = false;
  }

  @action
  onResize(width?: number): void {
    this.rangeWidth = width;
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

  <template>
    {{#let
      (and (argOrDefault @isPrependProvided true) (has-block "prepend"))
      (and (argOrDefault @isAppendProvided true) (has-block "append"))
      (and (not (argOrDefault @isFakeMaxBlock false)) (has-block "max"))
      (and (not (argOrDefault @isFakeMinBlock false)) (has-block "min"))
      as |hasPrepend hasAppend hasMaxBlock hasMinBlock|
    }}
      {{#if this.showInputOnly}}
        <EuiInputPopover
          class="euiRange__popover"
          @fullWidth={{this.fullWidth}}
          @isOpen={{this.isPopoverOpen}}
          @closePopover={{this.closePopover}}
          @disableFocusTrap={{true}}
          @onPanelResize={{this.onResize}}
        >
          <:input>
            <EuiFormControlLayoutDelimited
              @fullWidth={{this.fullWidth}}
              @compressed={{this.compressed}}
              @readOnly={{@readOnly}}
              @disabled={{@disabled}}
              @useGroup={{or hasPrepend hasAppend}}
            >
              <:prepend as |prependClasses|>
                {{yield prependClasses to="prepend"}}
              </:prepend>
              <:startControl as |classes|>
                <EuiRangeInput
                  class={{classes}}
                  @digitTolerance={{this.digitTolerance}}
                  @side="min"
                  @min={{this.min}}
                  {{!@glint-expect-error}}
                  @max={{castTo this.upperValue to="number"}}
                  @step={{this.step}}
                  @value={{this.lowerValue}}
                  @disabled={{@disabled}}
                  @compressed={{this.compressed}}
                  @onChange={{this.handleLowerInputChange}}
                  @name="{{@name}}-minValue"
                  @readOnly={{@readOnly}}
                  @autoSize={{false}}
                  @fullWidth={{this.fullWidth}}
                  @isInvalid={{@isInvalid}}
                  @isPrependProvided={{hasAppend}}
                  @isAppendProvided={{hasPrepend}}
                  @controlOnly={{true}}
                  @disable={{@disable}}
                  ...attributes
                  {{on "mousedown" (fn this.setPreventPopoverClose true)}}
                  {{onKey "_all" this.handleInputKeyDown}}
                  {{on
                    "focus"
                    (if
                      this.canShowDropdown this.onInputFocus (optional @onFocus)
                    )
                  }}
                  {{on
                    "blur"
                    (if
                      this.canShowDropdown this.onInputBlur (optional @onBlur)
                    )
                  }}
                  {{on "input" this.handleLowerInputChange}}
                >
                  <:prepend as |classes|>
                    {{yield classes to="prepend"}}
                  </:prepend>
                  <:append as |classes|>
                    {{yield classes to="append"}}
                  </:append>
                </EuiRangeInput>
              </:startControl>
              <:endControl as |classes|>
                <EuiRangeInput
                  class={{classes}}
                  @digitTolerance={{this.digitTolerance}}
                  @side="max"
                  {{!@glint-expect-error}}
                  @min={{castTo this.lowerValue to="number"}}
                  @max={{this.max}}
                  @step={{this.step}}
                  @value={{this.upperValue}}
                  @disabled={{@disabled}}
                  @compressed={{this.compressed}}
                  @name="{{@name}}-maxValue"
                  @readOnly={{@readOnly}}
                  @autoSize={{false}}
                  @fullWidth={{this.fullWidth}}
                  @isInvalid={{@isInvalid}}
                  @isPrependProvided={{hasAppend}}
                  @isAppendProvided={{hasPrepend}}
                  @controlOnly={{true}}
                  @disable={{@disable}}
                  ...attributes
                  {{on "mousedown" (fn this.setPreventPopoverClose true)}}
                  {{onKey "_all" this.handleInputKeyDown}}
                  {{on
                    "focus"
                    (if
                      this.canShowDropdown this.onInputFocus (optional @onFocus)
                    )
                  }}
                  {{on
                    "blur"
                    (if
                      this.canShowDropdown this.onInputBlur (optional @onBlur)
                    )
                  }}
                  {{on "input" this.handleUpperInputChange}}
                >
                  <:prepend as |classes|>
                    {{yield classes to="prepend"}}
                  </:prepend>
                  <:append as |classes|>
                    {{yield classes to="append"}}
                  </:append>
                </EuiRangeInput>
              </:endControl>
              <:append as |appendClasses|>
                {{yield appendClasses to="append"}}
              </:append>
            </EuiFormControlLayoutDelimited>
          </:input>
          <:content>
            <EuiRangeWrapper
              class="euiDualRange"
              @fullWidth={{this.fullWidth}}
              @compressed={{this.compressed}}
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
                aria-hidden={{if (eq this.showInput true) "true" "false"}}
                @compressed={{this.compressed}}
                @disabled={{@disabled}}
                @max={{this.max}}
                @min={{this.min}}
                @step={{this.step}}
                @showTicks={{this.showTicks}}
                @tickInterval={{@tickInterval}}
                @ticks={{@ticks}}
                @levels={{this.levels}}
                @onChange={{this.handleSliderChange}}
                @value={{@value}}
              >
                {{#if (and this.showRange this.isValid)}}
                  <EuiRangeHighlight
                    @compressed={{this.compressed}}
                    @hasFocus={{this.hasFocus}}
                    @showTicks={{this.showTicks}}
                    {{!@glint-expect-error}}
                    @min={{castTo this.min to="number"}}
                    {{!@glint-expect-error}}
                    @max={{castTo this.max to="number"}}
                    {{!@glint-expect-error}}
                    @lowerValue={{castTo this.lowerValue to="number"}}
                    {{!@glint-expect-error}}
                    @upperValue={{castTo this.upperValue to="number"}}
                  />
                {{/if}}
                <EuiRangeSlider
                  class="euiDualRange__slider"
                  aria-hidden="true"
                  @id={{this.id}}
                  @name={{@name}}
                  @min={{this.min}}
                  @max={{this.max}}
                  @step={{this.step}}
                  @disabled={{@disabled}}
                  @compressed={{this.compressed}}
                  @onChange={{this.handleSliderChange}}
                  @showTicks={{this.showTicks}}
                  @hasFocus={{this.hasFocus}}
                  tabindex="-1"
                  @showRange={{this.showRange}}
                  ...attributes
                  {{didInsert this.didInsertRangeSlider}}
                  {{on "mousedown" (fn this.setPreventPopoverClose true)}}
                  {{on "focus" (optional @onFocus)}}
                  {{on "blur" (optional @onBlur)}}
                  {{on "input" this.handleSliderChange}}
                />
                {{#if this.rangeSliderRefAvailable}}
                  <EuiRangeThumb
                    @min={{this.min}}
                    {{!@glint-expect-error}}
                    @max={{castTo this.upperValue to="number"}}
                    {{!@glint-expect-error}}
                    @value={{this.lowerValue}}
                    @disabled={{@disabled}}
                    @showTicks={{this.showTicks}}
                    @showInput={{not this.showInput}}
                    aria-describedby={{@ariaDescribedby}}
                    aria-label={{@ariaLabel}}
                    {{simpleStyle this.calculateLowerValueThumbPositionStyle}}
                    {{on "focus" this.onThumbFocus}}
                    {{on "blur" this.onThumbBlur}}
                    {{onKey "_all" this.handleLowerKeyDown}}
                  />
                  <EuiRangeThumb
                    {{!@glint-expect-error}}
                    @min={{castTo this.lowerValue to="number"}}
                    @max={{this.max}}
                    {{!@glint-expect-error}}
                    @value={{this.upperValue}}
                    @disabled={{@disabled}}
                    @showTicks={{this.showTicks}}
                    @showInput={{not this.showInput}}
                    aria-describedby={{@ariaDescribedby}}
                    aria-label={{@ariaLabel}}
                    {{simpleStyle this.calculateUpperValueThumbPositionStyle}}
                    {{on "focus" this.onThumbFocus}}
                    {{on "blur" this.onThumbBlur}}
                    {{onKey "_all" this.handleUpperKeyDown}}
                  />
                {{/if}}
              </EuiRangeTrack>
              {{#if this.showLabels}}
                <EuiRangeLabel @disabled={{@disabled}}>
                  {{#if hasMaxBlock}}
                    {{yield this.max to="max"}}
                  {{else}}
                    {{this.max}}
                  {{/if}}
                </EuiRangeLabel>
              {{/if}}
            </EuiRangeWrapper>
          </:content>
        </EuiInputPopover>
      {{else}}
        <EuiRangeWrapper
          class="euiDualRange"
          @fullWidth={{this.fullWidth}}
          @compressed={{this.compressed}}
        >
          {{#if this.showInput}}
            <EuiRangeInput
              @digitTolerance={{this.digitTolerance}}
              @side="min"
              @min={{this.min}}
              {{!@glint-expect-error}}
              @max={{castTo this.upperValue to="number"}}
              @step={{this.step}}
              @value={{this.lowerValue}}
              @disabled={{@disabled}}
              @compressed={{this.compressed}}
              @onChange={{this.handleLowerInputChange}}
              @name="{{@name}}-minValue"
              @readOnly={{@readOnly}}
              @fullWidth={{this.fullWidth}}
              @isInvalid={{@isInvalid}}
              @isPrependProvided={{false}}
              @isAppendProvided={{false}}
              @controlOnly={{true}}
              @disable={{@disable}}
              ...attributes
              {{onKey "_all" this.handleInputKeyDown}}
              {{on "focus" (optional @onFocus)}}
              {{on "blur" (optional @onBlur)}}
              {{on "input" this.handleLowerInputChange}}
            />
            <div class="euiRange__horizontalSpacer"></div>
          {{/if}}
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
            aria-hidden={{if (eq this.showInput true) "true" "false"}}
            @compressed={{this.compressed}}
            @disabled={{@disabled}}
            @max={{this.max}}
            @min={{this.min}}
            @step={{this.step}}
            @showTicks={{this.showTicks}}
            @tickInterval={{@tickInterval}}
            @ticks={{@ticks}}
            @levels={{this.levels}}
            @onChange={{this.handleSliderChange}}
            @value={{@value}}
          >
            {{#if (and this.showRange this.isValid)}}
              <EuiRangeHighlight
                @compressed={{this.compressed}}
                @hasFocus={{this.hasFocus}}
                @showTicks={{this.showTicks}}
                {{!@glint-expect-error}}
                @min={{castTo this.min to="number"}}
                {{!@glint-expect-error}}
                @max={{castTo this.max to="number"}}
                {{!@glint-expect-error}}
                @lowerValue={{castTo this.lowerValue to="number"}}
                {{!@glint-expect-error}}
                @upperValue={{castTo this.upperValue to="number"}}
              />
            {{/if}}
            <EuiRangeSlider
              class="euiDualRange__slider"
              aria-hidden="true"
              @id={{this.id}}
              @name={{@name}}
              @min={{this.min}}
              @max={{this.max}}
              @step={{this.step}}
              @disabled={{@disabled}}
              @compressed={{this.compressed}}
              @onChange={{this.handleSliderChange}}
              @showTicks={{this.showTicks}}
              @hasFocus={{this.hasFocus}}
              tabindex="-1"
              @showRange={{this.showRange}}
              ...attributes
              {{didInsert this.didInsertRangeSlider}}
              {{on "mousedown" (fn this.setPreventPopoverClose true)}}
              {{on "focus" (optional @onFocus)}}
              {{on "blur" (optional @onBlur)}}
              {{on "input" this.handleSliderChange}}
            />
            {{#if this.rangeSliderRefAvailable}}
              <EuiRangeThumb
                @min={{this.min}}
                {{!@glint-expect-error}}
                @max={{castTo this.upperValue to="number"}}
                {{!@glint-expect-error}}
                @value={{this.lowerValue}}
                @disabled={{@disabled}}
                @showTicks={{this.showTicks}}
                @showInput={{not this.showInput}}
                aria-describedby={{@ariaDescribedby}}
                aria-label={{@ariaLabel}}
                {{simpleStyle this.calculateLowerValueThumbPositionStyle}}
                {{on "focus" this.onThumbFocus}}
                {{on "blur" this.onThumbBlur}}
                {{!@glint-expect-error}}
                {{on "click" this.handleLowerKeyDown}}
              />
              <EuiRangeThumb
                {{!@glint-expect-error}}
                @min={{castTo this.lowerValue to="number"}}
                @max={{this.max}}
                {{!@glint-expect-error}}
                @value={{this.upperValue}}
                @disabled={{@disabled}}
                @showTicks={{this.showTicks}}
                @showInput={{not this.showInput}}
                aria-describedby={{@ariaDescribedby}}
                aria-label={{@ariaLabel}}
                {{simpleStyle this.calculateUpperValueThumbPositionStyle}}
                {{on "focus" this.onThumbFocus}}
                {{on "blur" this.onThumbBlur}}
                {{on "keydown" this.handleUpperKeyDown}}
              />
            {{/if}}
          </EuiRangeTrack>
          {{#if this.showLabels}}
            <EuiRangeLabel @disabled={{@disabled}}>
              {{#if hasMaxBlock}}
                {{yield this.max to="max"}}
              {{else}}
                {{this.max}}
              {{/if}}
            </EuiRangeLabel>
          {{/if}}
          {{#if this.showInput}}
            <div class="euiRange__horizontalSpacer"></div>
            {{! maxinput }}
            <EuiRangeInput
              @digitTolerance={{this.digitTolerance}}
              @side="max"
              {{!@glint-expect-error}}
              @min={{castTo this.lowerValue to="number"}}
              @max={{this.max}}
              @step={{this.step}}
              @value={{this.upperValue}}
              @disabled={{@disabled}}
              @compressed={{this.compressed}}
              @name="{{@name}}-maxValue"
              @readOnly={{@readOnly}}
              @fullWidth={{this.fullWidth}}
              @isInvalid={{@isInvalid}}
              @controlOnly={{this.showInputOnly}}
              @isPrependProvided={{false}}
              @isAppendProvided={{false}}
              @disable={{@disable}}
              ...attributes
              {{onKey "_all" this.handleInputKeyDown}}
              {{on "focus" (optional @onFocus)}}
              {{on "blur" (optional @onBlur)}}
              {{on "input" this.handleUpperInputChange}}
            />
          {{/if}}
        </EuiRangeWrapper>
      {{/if}}
    {{/let}}
  </template>
}
