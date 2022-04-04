import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { uniqueId } from '../../helpers/unique-id';
import { isWithinRange } from '../../utils/number';

import { EuiRangeInputArgs } from '../eui-range-input/types';
import { EuiRangeSliderArgs } from '../eui-range-slider/types';
import { EuiFormControlLayoutArgs } from '../eui-form-control-layout/types';
import { EuiRangeArgs } from '../eui-range';
import { EuiRangeLevel } from '../eui-range-levels';
import { EuiRangeTick } from '../eui-range-ticks';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import { later } from '@ember/runloop';
import { keys } from '../../utils/keys';
import { EUI_THUMB_SIZE } from '../../utils/range';
type ValueMember = number | string;

export interface EuiDualRangeArgs
  extends Omit<
    EuiRangeSliderArgs,
    'onChange' | 'onBlur' | 'onFocus' | 'value' | 'append' | 'prepend'
  > {
  value: [ValueMember, ValueMember];
  onBlur?: (event: HTMLInputElement | HTMLDivElement) => void;
  onFocus?: (event: HTMLInputElement | HTMLDivElement) => void;
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
  prepend?: EuiFormControlLayoutArgs['prepend'];
  /**
   * Creates an input group with element(s) coming after input. Will only show if `showInput = inputWithPopover`.
   * `string` | `Component` or an array of these
   */
  append?: EuiFormControlLayoutArgs['append'];
  /**
   *  Intended to be uses with aria attributes. Some attributes may be overwritten.
   */
  minInputProps?: Partial<EuiRangeInputArgs>;

  /**
   *  Intended to be uses with aria attributes. Some attributes may be overwritten.
   */
  maxInputProps?: Partial<EuiRangeInputArgs>;
}

export default class EuiDualRangeComponent extends Component<EuiDualRangeArgs> {
  // Defaults
  @argOrDefault(0) min!: number;
  @argOrDefault(100) max!: number;
  @argOrDefault(1) step!: number;
  @argOrDefault(false) fullWidth!: boolean;
  @argOrDefault(false) compressed!: boolean;
  @argOrDefault(false) showLabels!: boolean;
  @argOrDefault(false) showInput!: boolean | string;
  @argOrDefault(true) showRange!: boolean;
  @argOrDefault(false) showTicks!: boolean;
  @argOrDefault([]) levels!: EuiRangeLevel[];

  //State
  @tracked id: string = this.args.id || uniqueId();
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
  handleSliderChange(e: Event & { currentTarget: HTMLInputElement }): void {
    this._determineThumbMovement(Number(e.currentTarget.value), e);
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
  handleLowerInputChange(e: Event & { target: HTMLInputElement }): void {
    this._handleOnChange(e.target.value, this.upperValue, e);
  }

  @action
  handleUpperInputChange(e: Event & { target: HTMLInputElement }): void {
    this._handleOnChange(this.lowerValue, e.target.value, e);
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
    if (lower >= this.upperValue || lower < this.min) return;
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
    if (upper <= this.lowerValue || upper > this.max) return;
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
  onThumbFocus(e: HTMLDivElement): void {
    if (this.args.onFocus) {
      this.args.onFocus(e);
    }
    this.hasFocus = true;
  }

  @action
  onThumbBlur(e: HTMLDivElement): void {
    if (this.args.onBlur) {
      this.args.onBlur(e);
    }
    this.hasFocus = false;
  }

  @action
  onInputFocus(e: HTMLInputElement): void {
    if (this.args.onFocus) {
      this.args.onFocus(e);
    }
    this.preventPopoverClose = true;
    this.isPopoverOpen = true;
  }

  @action
  onInputBlur(e: HTMLInputElement): void {
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
}
