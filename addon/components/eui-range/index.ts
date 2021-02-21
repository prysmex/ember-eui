import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { uniqueId } from 'ember-eui/helpers/unique-id';
import { isWithinRange } from 'ember-eui/utils/number';
import { CommonArgs } from '../common';
import { EuiRangeInputArgs } from '../eui-range-input/types';
import { EuiRangeLevel } from '../eui-range-levels';
import { EuiRangeTick } from '../eui-range-ticks';
import { argOrDefaultDecorator as argOrDefault } from 'ember-eui/helpers/arg-or-default';
import { later } from '@ember/runloop';
export interface EuiRangeArgs
  extends CommonArgs,
    Omit<EuiRangeInputArgs, 'onChange' | 'digitTolerance'> {
  compressed?: boolean;
  readOnly?: boolean;
  fullWidth?: boolean;
  id: string;
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
  valueAppend?: Component;
  /**
   * Prepends to the tooltip
   */
  valuePrepend?: Component;

  onChange?: (event: Event, isValid: boolean) => void;
  onBlur?: (event: Event) => void;
  onFocus?: (event: Event) => void;
}

export default class EuiRangeComponent extends Component<EuiRangeArgs> {
  // Defaults
  @argOrDefault(0) min!: number;
  @argOrDefault(100) max!: number;
  @argOrDefault(1) step!: number;
  @argOrDefault(false) fullWidth!: boolean;
  @argOrDefault(false) compressed!: boolean;
  @argOrDefault(false) isLoading!: boolean;
  @argOrDefault(false) showLabels!: boolean;
  @argOrDefault(false) showInput!: boolean | string;
  @argOrDefault(false) showRange!: boolean;
  @argOrDefault(false) showTicks!: boolean;
  @argOrDefault(false) showValue!: boolean;
  @argOrDefault([]) levels!: EuiRangeLevel[];

  preventPopoverClose: boolean = false;

  //State
  @tracked id: string = this.args.id || uniqueId();
  @tracked isPopoverOpen: boolean = false;
  ///

  @action
  handleOnChange(e: Event & { currentTarget: HTMLInputElement }) {
    const isValid = isWithinRange(this.min, this.max, e.currentTarget.value);
    if (this.args.onChange) {
      this.args.onChange(e, isValid);
    }
  }

  get isValid() {
    return isWithinRange(this.min, this.max, this.args.value || '');
  }

  get digitTolerance() {
    return Math.max(String(this.min).length, String(this.max).length);
  }

  get showInputOnly() {
    return this.showInput === 'inputWithPopover';
  }

  get canShowDropdown() {
    return this.showInputOnly && !this.args.readOnly && !this.args.disabled;
  }

  get showRangeTooltip() {
    return this.showValue && !!String(this.args.value).length;
  }

  @action
  onInputFocus(e: Event) {
    console.log('received focus');
    if (this.args.onFocus) {
      this.args.onFocus(e);
    }
    this.isPopoverOpen = true;
  }

  @action
  onInputBlur(e: Event) {
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
  closePopover() {
    this.preventPopoverClose = false;
    this.isPopoverOpen = false;
  }

  @action
  setPreventPopoverClose(bool: boolean) {
    this.preventPopoverClose = bool;
  }
}
