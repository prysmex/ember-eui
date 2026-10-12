import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { concat, fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { later } from '@ember/runloop';
import { service } from '@ember/service';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { modifier } from 'ember-modifier';
import { and, eq, not } from 'ember-truth-helpers';

import argOrDefault, {
  argOrDefaultDecorator
} from '../helpers/arg-or-default.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { calculateThumbPosition, logicalStyle } from '../utils/eui/range.ts';
import {
  euiDualRangeStyles,
  euiRangeDraggableInnerStyles,
  euiRangeDraggableStyles,
  euiRangeLevelColor,
  euiRangeStyles,
  getLevelColor
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { keys } from '../utils/keys.ts';
import { isWithinRange } from '../utils/number/index.ts';
import EuiFormControlLayoutDelimited from './eui-form-control-layout-delimited.gts';
import EuiInputPopover from './eui-input-popover.gts';
import EuiRangeHighlight from './eui-range-highlight.gts';
import EuiRangeInput from './eui-range-input.gts';
import EuiRangeLabel from './eui-range-label.gts';
import EuiRangeSlider from './eui-range-slider.gts';
import EuiRangeThumb from './eui-range-thumb.gts';
import EuiRangeTrack from './eui-range-track.gts';
import EuiRangeWrapper from './eui-range-wrapper.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';
import type { EuiRangeArgs } from './eui-range';
import type {
  EuiRangeInputArgs,
  EuiRangeInputSignature
} from './eui-range-input';
import type { EuiRangeLevel } from './eui-range-levels';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { EuiRangeTick } from './eui-range-ticks';

export type ValueMember = number | string;

export interface EuiDualRangeArgs {
  /** The selected range, `[lower, upper]`. Update it in `@onChange`. */
  value: [ValueMember, ValueMember];
  /** Called when a thumb or input loses focus. */
  onBlur?: (event: FocusEvent) => void;
  /** Called when a thumb or input gets focus. */
  onFocus?: (event: FocusEvent) => void;
  /**
   * Called with the new `[lower, upper]` values, whether they are valid
   * (within `@min`/`@max` and lower ≤ upper) and the event.
   */
  onChange: (
    values: [ValueMember, ValueMember],
    isValid: boolean,
    event: Event | MouseEvent | KeyboardEvent
  ) => void;
  /** Stretches the slider to its container's width. */
  fullWidth?: boolean;
  /** Shows the invalid state. */
  isInvalid?: boolean;
  /**
   * Create colored indicators for certain intervals:
   * `[{ min: 0, max: 20, color: 'danger' }, …]`.
   */
  levels?: EuiRangeLevel[];
  /**
   * Shows static min/max labels on the sides of the range slider.
   * Defaults to `false`.
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
   * Specified ticks at specified values: `[{ label: '20kb', value: 20 }]`.
   */
  ticks?: EuiRangeTick[];
  /**
   * @deprecated Has no effect, use the `<:prepend>` block (shown with
   * `@showInput="inputWithPopover"`).
   */
  prepend?: EuiFormControlLayoutSignature['Blocks']['prepend'];
  /**
   * @deprecated Has no effect, use the `<:append>` block (shown with
   * `@showInput="inputWithPopover"`).
   */
  append?: EuiFormControlLayoutSignature['Blocks']['append'];
  /** @deprecated Has no effect. */
  minInputProps?: Partial<EuiRangeInputArgs>;
  /** @deprecated Has no effect. */
  maxInputProps?: Partial<EuiRangeInputArgs>;
  /** Makes the inputs read-only. */
  readOnly?: boolean;
  /** Disables the slider and inputs. */
  disabled?: boolean;
  /** @private Show the `<:prepend>` block. Defaults to `true`. */
  isPrependProvided?: boolean;
  /** @private Show the `<:append>` block. Defaults to `true`. */
  isAppendProvided?: boolean;
  /** @private Ignore the `<:max>` block. */
  isFakeMaxBlock?: boolean;
  /** @private Ignore the `<:min>` block. */
  isFakeMinBlock?: boolean;
  /** Disables the number inputs. */
  disable?: boolean;
  /** Id of the element(s) describing the slider thumbs. */
  ariaDescribedby?: string;
  /** Accessible label of the slider thumbs. */
  ariaLabel?: string;
  /** `name` of the inputs; the number inputs get `-minValue` / `-maxValue` suffixes. */
  name?: string;
  /** Id of the slider. Defaults to a generated id. */
  id?: string;
  /** Smaller slider, for dense forms. Defaults to `false`. */
  compressed?: boolean;
  /**
   * Makes the highlighted range draggable (moves both values at once), with
   * its own `role="slider"` for the keyboard. Defaults to `false`.
   */
  isDraggable?: boolean;
  /**
   * Shows a spinner in the delimited input (`@showInput="inputWithPopover"`).
   */
  isLoading?: boolean;
  /** Highlights the selected range on the track. Defaults to `true`. */
  showRange?: boolean;
  /** Shows tick marks, every `@step` (or `@tickInterval`). Defaults to `false`. */
  showTicks?: boolean;
  /** Increment between values. Defaults to `1`. */
  step?: number;
  /** Lowest selectable value. Defaults to `0`. */
  min?: number;
  /** Highest selectable value. Defaults to `100`. */
  max?: number;
}

/**
 * A slider with two thumbs to pick a range, e.g. a price range. For one
 * value use EuiRange.
 */
export interface EuiDualRangeSignature {
  Element: EuiRangeInputSignature['Element'];
  Args: EuiDualRangeArgs;
  Blocks: {
    /** Content before the inputs (`@showInput="inputWithPopover"`). */
    prepend: EuiRangeInputSignature['Blocks']['prepend'];
    /** Content after the inputs (`@showInput="inputWithPopover"`). */
    append: EuiRangeInputSignature['Blocks']['append'];
    /** Custom min label (`@showLabels`); yields `@min`. */
    min: [number?];
    /** Custom max label (`@showLabels`); yields `@max`. */
    max: [number?];
  };
}

/**
 * One number input of EuiDualRange (`@side` min or max), wired to the
 * range's handlers. `@class` is the delimited layout's input class.
 */
const DualRangeInput: TemplateOnlyComponent<{
  Element: HTMLInputElement;
  Args: {
    range: EuiDualRangeComponent;
    side: 'min' | 'max';
    class?: string;
  };
}> = <template>
  {{#let (eq @side "min") as |isMin|}}
    <EuiRangeInput
      class={{@class}}
      @side={{@side}}
      @min={{if isMin @range.min @range.upperMin}}
      @max={{if isMin @range.lowerMax @range.max}}
      @step={{@range.step}}
      @value={{if isMin @range.lowerValue @range.upperValue}}
      @disabled={{@range.args.disabled}}
      @compressed={{@range.compressed}}
      @name={{concat @range.args.name (if isMin "-minValue" "-maxValue")}}
      @readOnly={{@range.args.readOnly}}
      @autoSize={{not @range.showInputOnly}}
      @fullWidth={{and @range.showInputOnly @range.fullWidth}}
      @isInvalid={{@range.args.isInvalid}}
      @isPrependProvided={{false}}
      @isAppendProvided={{false}}
      @controlOnly={{@range.showInputOnly}}
      aria-label={{@range.args.ariaLabel}}
      aria-describedby={{@range.args.ariaDescribedby}}
      ...attributes
      {{on
        "mousedown"
        (if
          @range.showInputOnly (fn @range.setPreventPopoverClose true) (optional)
        )
      }}
      {{on "keydown" @range.handleInputKeyDown}}
      {{on
        "focus"
        (if
          @range.canShowDropdown
          @range.onInputFocus
          (optional @range.args.onFocus)
        )
      }}
      {{on
        "blur"
        (if
          @range.canShowDropdown @range.onInputBlur (optional @range.args.onBlur)
        )
      }}
      {{on
        "input"
        (if
          isMin @range.handleLowerInputChange @range.handleUpperInputChange
        )
      }}
    />
  {{/let}}
</template>;

const borderBox = { boxSizing: 'border-box' } as const;

/** Mouse drag on the draggable range: calls `onChange(x, isFirstInteraction)`. */
const mouseMove = modifier(
  (
    element: HTMLElement,
    _: unknown[],
    { onChange }: { onChange: (x: number, isFirst: boolean) => void }
  ) => {
    let cleanup: (() => void) | undefined;
    const onMouseDown = (event: MouseEvent) => {
      onChange(event.clientX, true);
      const onMove = (e: MouseEvent) => onChange(e.clientX, false);
      const onUp = () => cleanup?.();
      cleanup = () => {
        document.removeEventListener('mousemove', onMove);
        document.removeEventListener('mouseup', onUp);
        cleanup = undefined;
      };
      document.addEventListener('mousemove', onMove);
      document.addEventListener('mouseup', onUp);
    };
    const onTouch = (event: TouchEvent) => {
      const touch = event.touches[0];
      if (touch) onChange(touch.clientX, event.type === 'touchstart');
    };
    element.addEventListener('mousedown', onMouseDown);
    element.addEventListener('touchstart', onTouch);
    element.addEventListener('touchmove', onTouch);
    return () => {
      cleanup?.();
      element.removeEventListener('mousedown', onMouseDown);
      element.removeEventListener('touchstart', onTouch);
      element.removeEventListener('touchmove', onTouch);
    };
  }
);

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

  @service declare euiI18n: EuiI18n;

  //State
  @tracked id: string = this.args.id || guidFor({});
  @tracked isPopoverOpen = false;
  ///

  preventPopoverClose = false;
  rangeSliderRef: HTMLInputElement | null = null;
  leftPosition = 0;
  dragAcc = 0;

  @action
  didInsertRangeSlider(ref: HTMLInputElement | null): void {
    this.rangeSliderRef = ref;
  }

  get context() {
    return getEuiThemeContext(this);
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

  get lowerNumber(): number {
    return Number(this.lowerValue);
  }

  get upperNumber(): number {
    return Number(this.upperValue);
  }

  /** Upper bound of the lower thumb/input (`@max` while the upper value is empty). */
  get lowerMax(): number {
    return this.upperValue === '' ? this.max : Number(this.upperValue);
  }

  /** Lower bound of the upper thumb/input (`@min` while the lower value is empty). */
  get upperMin(): number {
    return this.lowerValue === '' ? this.min : Number(this.lowerValue);
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

  /** Arrow keys on the draggable range move both values by a step. */
  @action
  handleDraggableKeyDown(event: KeyboardEvent): void {
    if (event.key === keys.TAB) return;
    const lower = this._handleKeyDown(this.lowerValue, event);
    const upper = this._handleKeyDown(this.upperValue, event);

    if (lower >= Number(this.upperValue) || lower < this.min) return;
    if (upper <= Number(this.lowerValue) || upper > this.max) return;
    this._handleOnChange(lower, upper, event);
  }

  getNearestStep(value: number): number {
    const { min, max, step } = this;
    const steps = (max - min) / step;
    const approx = Math.round(((value - min) * steps) / (max - min)) / steps;
    const bound = Math.min(Math.max(approx, 0), 1);
    const nearest = bound * (max - min) + min;
    return (Number(nearest.toPrecision(10)) * 100) / 100;
  }

  /** Upstream `handleDrag`: moves both values by the dragged distance. */
  @action
  handleDrag(x: number, isFirstInteraction: boolean): void {
    if (this.args.disabled) return;
    if (isFirstInteraction) {
      this.leftPosition = x;
      this.dragAcc = 0;
    }
    const { min, max } = this;
    const lowerValue = Number(this.lowerValue);
    const upperValue = Number(this.upperValue);
    const delta = this.leftPosition - x;
    this.leftPosition = x;
    this.dragAcc = this.dragAcc + delta;
    const rangeWidth = this.rangeSliderRef?.clientWidth ?? 0;
    if (!rangeWidth) return;
    const percentageOfArea = this.dragAcc / rangeWidth;
    const percentageOfRange = percentageOfArea * (max - min);
    const newLower = this.getNearestStep(lowerValue - percentageOfRange);
    const newUpper = this.getNearestStep(upperValue - percentageOfRange);
    const noMovement = newLower === lowerValue;
    const isMin = min === lowerValue && min === newLower;
    const isMax = max === upperValue && max === newUpper;
    const isOutOfRange = newLower < min || newUpper > max;
    if (noMovement || isMin || isMax || isOutOfRange) return;
    this._handleOnChange(newLower, newUpper, new Event('drag'));
    this.dragAcc = 0;
  }

  /** Thumb start position in % of the track (`0` until the track is measured). */
  thumbPosition = (value: number, trackWidth: number): string =>
    trackWidth
      ? `${calculateThumbPosition(value, this.min, this.max, trackWidth)}%`
      : '0';

  thumbColor(value: ValueMember): string | undefined {
    const color = getLevelColor(this.levels ?? [], Number(value));
    return color ? euiRangeLevelColor(color, this.context.upstream) : undefined;
  }

  lowerThumbStyle = (trackWidth: number) =>
    logicalStyle({
      left: this.thumbPosition(this.lowerNumber || this.min, trackWidth),
      '--euiRangeThumbColor': this.thumbColor(this.lowerValue)
    });

  upperThumbStyle = (trackWidth: number) =>
    logicalStyle({
      left: this.thumbPosition(this.upperNumber || this.max, trackWidth),
      '--euiRangeThumbColor': this.thumbColor(this.upperValue)
    });

  draggableStyle = (trackWidth: number) =>
    logicalStyle({
      left: this.thumbPosition(this.lowerNumber || this.min, trackWidth),
      right: `calc(100% - ${this.thumbPosition(
        this.upperNumber || this.max,
        trackWidth
      )} - ${this.context.upstream.euiTheme.size.base})`
    });

  @cached
  get styles() {
    const context = this.context;
    const dual = useEuiBorealisStyles(context, euiDualRangeStyles);
    const range = useEuiBorealisStyles(context, euiRangeStyles);
    const draggable = useEuiBorealisStyles(context, euiRangeDraggableStyles);
    const inner = useEuiBorealisStyles(context, euiRangeDraggableInnerStyles);
    const { disabled } = this.args;
    const slim = this.showTicks || !!this.args.ticks;
    return {
      rootCss: dual.euiDualRange,
      sliderCss: dual.euiDualRange__slider,
      spacer: slim
        ? `euiRange__slimHorizontalSpacer ${euiClass(context, range.euiRange__slimHorizontalSpacer)}`
        : `euiRange__horizontalSpacer ${euiClass(context, range.euiRange__horizontalSpacer)}`,
      draggable: `euiRangeDraggable ${euiClass(
        context,
        borderBox,
        draggable.euiRangeDraggable,
        this.showTicks && draggable.hasTicks,
        disabled && draggable.disabled
      )}`,
      draggableInner: `euiRangeDraggable__inner ${euiClass(
        context,
        inner.euiRangeDraggable__inner,
        disabled ? draggable.disabled : inner.enabled
      )}`
    };
  }

  get draggableValueText(): string {
    return `${this.lowerValue}, ${this.upperValue}`;
  }

  get screenReaderInstructions(): string {
    return this.euiI18n.lookupToken(
      'euiDualRange.sliderScreenReaderInstructions',
      'You are in a custom range slider. Use the Up and Down arrow keys to change the minimum value. Press Tab to interact with the maximum value.'
    );
  }

  @action
  setPreventPopoverClose(value: boolean): void {
    this.preventPopoverClose = value;
  }

  @action
  onThumbFocus(e: FocusEvent): void {
    this.args.onFocus?.(e);
  }

  @action
  onThumbBlur(e: FocusEvent): void {
    this.args.onBlur?.(e);
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

  /** @deprecated The track measures itself; kept for callers. */
  @action
  onResize(): void {}

  get digitTolerance(): number {
    return Math.max(String(this.min).length, String(this.max).length);
  }

  get showInputOnly(): boolean {
    return this.showInput === 'inputWithPopover';
  }

  get canShowDropdown(): boolean {
    return this.showInputOnly && !this.args.readOnly && !this.args.disabled;
  }

  /** Thumb `aria-label`/`aria-describedby` (the inputs carry them in a popover). */
  get thumbAriaLabel(): string | undefined {
    return this.showInputOnly ? undefined : this.args.ariaLabel;
  }

  get thumbAriaDescribedby(): string | undefined {
    return this.showInputOnly ? undefined : this.args.ariaDescribedby;
  }

  willDestroy() {
    super.willDestroy();

    this.rangeSliderRef = null;
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
          class="euiDualRange__popover"
          @fullWidth={{this.fullWidth}}
          @isOpen={{this.isPopoverOpen}}
          @closePopover={{this.closePopover}}
          @disableFocusTrap={{true}}
          @popoverScreenReaderText={{this.screenReaderInstructions}}
        >
          <:input>
            {{! Delimited renders a side wrapper for every block it is given }}
            {{#if (and hasPrepend hasAppend)}}
              <EuiFormControlLayoutDelimited
                @fullWidth={{this.fullWidth}}
                @compressed={{this.compressed}}
                @readOnly={{@readOnly}}
                @disabled={{@disabled}}
                @isLoading={{@isLoading}}
                @isInvalid={{@isInvalid}}
              >
                <:prepend as |prependClasses|>
                  {{yield prependClasses to="prepend"}}
                </:prepend>
                <:startControl as |classes|>
                  <DualRangeInput @range={{this}} @side="min" @class={{classes}} ...attributes />
                </:startControl>
                <:endControl as |classes|>
                  <DualRangeInput @range={{this}} @side="max" @class={{classes}} ...attributes />
                </:endControl>
                <:append as |appendClasses|>
                  {{yield appendClasses to="append"}}
                </:append>
              </EuiFormControlLayoutDelimited>
            {{else if hasPrepend}}
              <EuiFormControlLayoutDelimited
                @fullWidth={{this.fullWidth}}
                @compressed={{this.compressed}}
                @readOnly={{@readOnly}}
                @disabled={{@disabled}}
                @isLoading={{@isLoading}}
                @isInvalid={{@isInvalid}}
              >
                <:prepend as |prependClasses|>
                  {{yield prependClasses to="prepend"}}
                </:prepend>
                <:startControl as |classes|>
                  <DualRangeInput @range={{this}} @side="min" @class={{classes}} ...attributes />
                </:startControl>
                <:endControl as |classes|>
                  <DualRangeInput @range={{this}} @side="max" @class={{classes}} ...attributes />
                </:endControl>
              </EuiFormControlLayoutDelimited>
            {{else if hasAppend}}
              <EuiFormControlLayoutDelimited
                @fullWidth={{this.fullWidth}}
                @compressed={{this.compressed}}
                @readOnly={{@readOnly}}
                @disabled={{@disabled}}
                @isLoading={{@isLoading}}
                @isInvalid={{@isInvalid}}
              >
                <:startControl as |classes|>
                  <DualRangeInput @range={{this}} @side="min" @class={{classes}} ...attributes />
                </:startControl>
                <:endControl as |classes|>
                  <DualRangeInput @range={{this}} @side="max" @class={{classes}} ...attributes />
                </:endControl>
                <:append as |appendClasses|>
                  {{yield appendClasses to="append"}}
                </:append>
              </EuiFormControlLayoutDelimited>
            {{else}}
              <EuiFormControlLayoutDelimited
                @fullWidth={{this.fullWidth}}
                @compressed={{this.compressed}}
                @readOnly={{@readOnly}}
                @disabled={{@disabled}}
                @isLoading={{@isLoading}}
                @isInvalid={{@isInvalid}}
              >
                <:startControl as |classes|>
                  <DualRangeInput @range={{this}} @side="min" @class={{classes}} ...attributes />
                </:startControl>
                <:endControl as |classes|>
                  <DualRangeInput @range={{this}} @side="max" @class={{classes}} ...attributes />
                </:endControl>
              </EuiFormControlLayoutDelimited>
            {{/if}}
          </:input>
          <:content>
            <EuiRangeWrapper
              class="euiDualRange"
              @css={{this.styles.rootCss}}
              @fullWidth={{this.fullWidth}}
              @compressed={{this.compressed}}
            >
              {{#if (and this.showInput (not this.showInputOnly))}}
                <DualRangeInput @range={{this}} @side="min" ...attributes />
                <div class={{this.styles.spacer}}></div>
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
                aria-hidden={{if (eq this.showInput true) "true"}}
                @compressed={{this.compressed}}
                @disabled={{@disabled}}
                @max={{this.max}}
                @min={{this.min}}
                @step={{this.step}}
                @showTicks={{this.showTicks}}
                @showRange={{this.showRange}}
                @tickInterval={{@tickInterval}}
                @ticks={{@ticks}}
                @levels={{this.levels}}
                @onChange={{this.handleSliderChange}}
                @value={{@value}}
                as |trackWidth|
              >
                <EuiRangeSlider
                  class="euiDualRange__slider"
                  aria-hidden="true"
                  tabindex="-1"
                  @css={{this.styles.sliderCss}}
                  @id={{this.id}}
                  @name={{@name}}
                  @min={{this.min}}
                  @max={{this.max}}
                  @step={{this.step}}
                  @disabled={{@disabled}}
                  @showTicks={{this.showTicks}}
                  @showRange={{this.showRange}}
                  ...attributes
                  {{didInsert this.didInsertRangeSlider}}
                  {{on "mousedown" (fn this.setPreventPopoverClose true)}}
                  {{on "focus" (optional @onFocus)}}
                  {{on "blur" (optional @onBlur)}}
                  {{on "input" this.handleSliderChange}}
                />
                {{#if (and @isDraggable this.isValid)}}
                  <div
                    class={{this.styles.draggable}}
                    role="slider"
                    aria-valuemin={{this.min}}
                    aria-valuemax={{this.max}}
                    aria-valuenow={{this.lowerNumber}}
                    aria-valuetext={{this.draggableValueText}}
                    aria-disabled={{if @disabled "true" "false"}}
                    aria-label={{this.thumbAriaLabel}}
                    aria-describedby={{this.thumbAriaDescribedby}}
                    tabindex={{if @disabled "-1" "0"}}
                    style={{this.draggableStyle trackWidth}}
                    {{on "focus" this.onThumbFocus}}
                    {{on "blur" this.onThumbBlur}}
                    {{on "keydown" this.handleDraggableKeyDown}}
                  >
                    <div
                      class={{this.styles.draggableInner}}
                      {{mouseMove onChange=this.handleDrag}}
                    ></div>
                  </div>
                {{/if}}
                <EuiRangeThumb
                  @min={{this.min}}
                  @max={{this.upperNumber}}
                  @value={{this.lowerValue}}
                  @disabled={{@disabled}}
                  @showTicks={{this.showTicks}}
                  @showInput={{if this.showInput true false}}
                  aria-describedby={{this.thumbAriaDescribedby}}
                  aria-label={{this.thumbAriaLabel}}
                  style={{this.lowerThumbStyle trackWidth}}
                  {{on "focus" this.onThumbFocus}}
                  {{on "blur" this.onThumbBlur}}
                  {{on "keydown" this.handleLowerKeyDown}}
                />
                <EuiRangeThumb
                  @min={{this.lowerNumber}}
                  @max={{this.max}}
                  @value={{this.upperValue}}
                  @disabled={{@disabled}}
                  @showTicks={{this.showTicks}}
                  @showInput={{if this.showInput true false}}
                  aria-describedby={{this.thumbAriaDescribedby}}
                  aria-label={{this.thumbAriaLabel}}
                  style={{this.upperThumbStyle trackWidth}}
                  {{on "focus" this.onThumbFocus}}
                  {{on "blur" this.onThumbBlur}}
                  {{on "keydown" this.handleUpperKeyDown}}
                />
                {{#if (and this.showRange this.isValid)}}
                  <EuiRangeHighlight
                    @showTicks={{this.showTicks}}
                    @min={{this.min}}
                    @max={{this.max}}
                    @lowerValue={{this.lowerNumber}}
                    @upperValue={{this.upperNumber}}
                    @levels={{this.levels}}
                    @trackWidth={{trackWidth}}
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
              {{#if (and this.showInput (not this.showInputOnly))}}
                <div class={{this.styles.spacer}}></div>
                <DualRangeInput @range={{this}} @side="max" ...attributes />
              {{/if}}
            </EuiRangeWrapper>
          </:content>
        </EuiInputPopover>
      {{else}}
        <EuiRangeWrapper
          class="euiDualRange"
          @css={{this.styles.rootCss}}
          @fullWidth={{this.fullWidth}}
          @compressed={{this.compressed}}
        >
          {{#if (and this.showInput (not this.showInputOnly))}}
            <DualRangeInput @range={{this}} @side="min" ...attributes />
            <div class={{this.styles.spacer}}></div>
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
            aria-hidden={{if (eq this.showInput true) "true"}}
            @compressed={{this.compressed}}
            @disabled={{@disabled}}
            @max={{this.max}}
            @min={{this.min}}
            @step={{this.step}}
            @showTicks={{this.showTicks}}
            @showRange={{this.showRange}}
            @tickInterval={{@tickInterval}}
            @ticks={{@ticks}}
            @levels={{this.levels}}
            @onChange={{this.handleSliderChange}}
            @value={{@value}}
            as |trackWidth|
          >
            <EuiRangeSlider
              class="euiDualRange__slider"
              aria-hidden="true"
              tabindex="-1"
              @css={{this.styles.sliderCss}}
              @id={{this.id}}
              @name={{@name}}
              @min={{this.min}}
              @max={{this.max}}
              @step={{this.step}}
              @disabled={{@disabled}}
              @showTicks={{this.showTicks}}
              @showRange={{this.showRange}}
              ...attributes
              {{didInsert this.didInsertRangeSlider}}
              {{on "mousedown" (fn this.setPreventPopoverClose true)}}
              {{on "focus" (optional @onFocus)}}
              {{on "blur" (optional @onBlur)}}
              {{on "input" this.handleSliderChange}}
            />
            {{#if (and @isDraggable this.isValid)}}
              <div
                class={{this.styles.draggable}}
                role="slider"
                aria-valuemin={{this.min}}
                aria-valuemax={{this.max}}
                aria-valuenow={{this.lowerNumber}}
                aria-valuetext={{this.draggableValueText}}
                aria-disabled={{if @disabled "true" "false"}}
                aria-label={{this.thumbAriaLabel}}
                aria-describedby={{this.thumbAriaDescribedby}}
                tabindex={{if @disabled "-1" "0"}}
                style={{this.draggableStyle trackWidth}}
                {{on "focus" this.onThumbFocus}}
                {{on "blur" this.onThumbBlur}}
                {{on "keydown" this.handleDraggableKeyDown}}
              >
                <div
                  class={{this.styles.draggableInner}}
                  {{mouseMove onChange=this.handleDrag}}
                ></div>
              </div>
            {{/if}}
            <EuiRangeThumb
              @min={{this.min}}
              @max={{this.upperNumber}}
              @value={{this.lowerValue}}
              @disabled={{@disabled}}
              @showTicks={{this.showTicks}}
              @showInput={{if this.showInput true false}}
              aria-describedby={{this.thumbAriaDescribedby}}
              aria-label={{this.thumbAriaLabel}}
              style={{this.lowerThumbStyle trackWidth}}
              {{on "focus" this.onThumbFocus}}
              {{on "blur" this.onThumbBlur}}
              {{on "keydown" this.handleLowerKeyDown}}
            />
            <EuiRangeThumb
              @min={{this.lowerNumber}}
              @max={{this.max}}
              @value={{this.upperValue}}
              @disabled={{@disabled}}
              @showTicks={{this.showTicks}}
              @showInput={{if this.showInput true false}}
              aria-describedby={{this.thumbAriaDescribedby}}
              aria-label={{this.thumbAriaLabel}}
              style={{this.upperThumbStyle trackWidth}}
              {{on "focus" this.onThumbFocus}}
              {{on "blur" this.onThumbBlur}}
              {{on "keydown" this.handleUpperKeyDown}}
            />
            {{#if (and this.showRange this.isValid)}}
              <EuiRangeHighlight
                @showTicks={{this.showTicks}}
                @min={{this.min}}
                @max={{this.max}}
                @lowerValue={{this.lowerNumber}}
                @upperValue={{this.upperNumber}}
                @levels={{this.levels}}
                @trackWidth={{trackWidth}}
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
          {{#if (and this.showInput (not this.showInputOnly))}}
            <div class={{this.styles.spacer}}></div>
            <DualRangeInput @range={{this}} @side="max" ...attributes />
          {{/if}}
        </EuiRangeWrapper>
      {{/if}}
    {{/let}}
  </template>
}
