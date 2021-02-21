import Component from '@glimmer/component';
import { EuiRangeLevel, LEVEL_COLORS } from '../eui-range-levels';
import { assert } from '@ember/debug';
import { isEvenlyDivisibleBy } from 'ember-eui/utils/number';
import { range } from 'lodash-es';
import { action } from '@ember/object';

export { LEVEL_COLORS };

export interface EuiRangeTick {
  value: number;
  label: Component;
}

export type EuiRangeTrackArgs = {
  min: number;
  max: number;
  step?: number;
  value?: number | string | Array<string | number>;
  compressed?: boolean;
  disabled?: boolean;
  showTicks?: boolean;
  tickInterval?: number;
  ticks?: EuiRangeTick[];
  onChange?: MouseEvent;
  levels?: EuiRangeLevel[];
};

export default class EuiRangeToolipComponent extends Component<EuiRangeTrackArgs> {
  @action
  validateValueIsInStep(value: number) {
    let { min, max, step } = this.args;
    if (value < min) {
      assert(`The value of ${value} is lower than the min value of ${min}.`, true);
    }
    if (value > max) {
      assert(`The value of ${value} is higher than the max value of ${max}.`, true);
    }
    // Error out if the value doesn't line up with the sequence of steps
    if (!isEvenlyDivisibleBy(value - min, step !== undefined ? step : 1)) {
      assert(
        `The value of ${value} is not included in the possible sequence provided by the step of ${step}.`,
        true
      );
    }
    // Return the value if nothing fails
    return value;
  }

  calculateSequence(
    min: EuiRangeTrackArgs['min'],
    max: EuiRangeTrackArgs['max'],
    interval?: EuiRangeTrackArgs['tickInterval']
  ) {
    // Loop from min to max, creating adding values at each interval
    // (adds a very small number to the max since `range` is not inclusive of the max value)
    const toBeInclusive = 0.000000001;
    return range(min, max + toBeInclusive, interval);
  }

  calculateTicks(
    min: EuiRangeTrackArgs['min'],
    max: EuiRangeTrackArgs['max'],
    step?: EuiRangeTrackArgs['step'],
    tickInterval?: EuiRangeTrackArgs['tickInterval'],
    customTicks?: EuiRangeTick[]
  ) {
    let ticks;

    if (customTicks) {
      // If custom values were passed, use those for the sequence
      // But make sure they align with the possible sequence
      ticks = customTicks.map((tick) => {
        return this.validateValueIsInStep(tick.value);
      });
    } else {
      // If a custom interval was passed, use those for the sequence
      // But make sure they align with the possible sequence
      const interval = tickInterval || step;
      const tickSequence = this.calculateSequence(min, max, interval);

      ticks = tickSequence.map((tick) => {
        return this.validateValueIsInStep(tick);
      });
    }

    // Error out if there are too many ticks to render
    if (ticks.length > 20) {
      assert(
        `The number of ticks to render is too high (${ticks.length}), reduce the interval.`,
        true
      );
    }

    return ticks;
  }

  get derivedState() {
    let tickSequence;
    let styles;
    let { showTicks, min, max, step, tickInterval, ticks } = this.args;

    if (showTicks) {
      tickSequence = this.calculateTicks(min, max, step, tickInterval, ticks);

      // Calculate if any extra margin should be added to the inputWrapper
      // because of longer tick labels on the ends
      const lengthOfMinLabel = String(tickSequence[0]).length;
      const lenghtOfMaxLabel = String(tickSequence[tickSequence.length - 1]).length;
      const isLastTickTheMax = tickSequence[tickSequence.length - 1] === max;
      if (lengthOfMinLabel > 2) {
        styles = `margin-left: ${lengthOfMinLabel / 5}em`;
      }
      if (isLastTickTheMax && lenghtOfMaxLabel > 2) {
        styles = `margin-right: ${lenghtOfMaxLabel / 5}em`;
      }
    }

    return {
      tickSequence,
      styles,
    };
  }
}
