import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';
import { fn } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { htmlSafe } from '@ember/template';

import { and, gt,or } from 'ember-truth-helpers';
import { range } from 'lodash-es';

import classNames from '../helpers/class-names.ts';
import { isEvenlyDivisibleBy } from '../utils/number/index.ts';
import { LEVEL_COLORS } from './eui-range-levels.gts';
import EuiRangeLevels from './eui-range-levels.gts';
import EuiRangeTicks from './eui-range-ticks.gts';

import type { EuiRangeLevel } from './eui-range-levels';

export { LEVEL_COLORS };

export interface EuiRangeTick {
  value: number;
  label: Component;
}

type Value = number | string;

export type EuiRangeTrackArgs = {
  min: number;
  max: number;
  step?: number;
  value?: Value | Value[];
  compressed?: boolean;
  disabled?: boolean;
  showTicks?: boolean;
  tickInterval?: number;
  ticks?: EuiRangeTick[];
  onChange?: (e: MouseEvent) => void;
  levels?: EuiRangeLevel[];
};

type Styling = {
  tickSequence?: number[];
  styles: ReturnType<typeof htmlSafe>;
};

export interface EuiRangeTrackSignature {
  Element: HTMLElement;
  Args: EuiRangeTrackArgs;
  Blocks: {
    default: [];
  };
}

export default class EuiRangeTrackComponent extends Component<EuiRangeTrackSignature> {
  @tracked declare trackEl: HTMLElement;

  @action
  registerTrack(el: HTMLElement) {
    this.trackEl = el;
  }

  @action
  validateValueIsInStep(value: number): number {
    const { min, max, step } = this.args;

    if (value < min) {
      assert(
        `The value of ${value} is lower than the min value of ${min}.`,
        false
      );
    }

    if (value > max) {
      assert(
        `The value of ${value} is higher than the max value of ${max}.`,
        false
      );
    }

    // Error out if the value doesn't line up with the sequence of steps
    if (!isEvenlyDivisibleBy(value - min, step !== undefined ? step : 1)) {
      assert(
        `The value of ${value} is not included in the possible sequence provided by the step of ${step}.`,
        false
      );
    }

    // Return the value if nothing fails
    return value;
  }

  calculateSequence(
    min: EuiRangeTrackArgs['min'],
    max: EuiRangeTrackArgs['max'],
    interval?: EuiRangeTrackArgs['tickInterval']
  ): number[] {
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
  ): number[] {
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
        `The number of ticks to render is too high (${ticks.length}), increase the interval.`,
        true
      );
    }

    return ticks;
  }

  get derivedState(): Styling {
    let tickSequence;
    let styles = '';
    const { showTicks, min, max, step, tickInterval, ticks } = this.args;

    if (showTicks) {
      tickSequence = this.calculateTicks(min, max, step, tickInterval, ticks);

      // Calculate if any extra margin should be added to the inputWrapper
      // because of longer tick labels on the ends
      const lengthOfMinLabel = String(tickSequence[0]).length;
      const lenghtOfMaxLabel = String(
        tickSequence[tickSequence.length - 1]
      ).length;
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
      styles: htmlSafe(styles)
    };
  }

  <template>
    <div
      class={{classNames
        "euiRangeTrack"
        (if @disabled "euiRangeTrack--disabled")
        (if @showTicks "euiRangeTrack--hasTicks")
        (if (and @levels (gt @levels.length 0)) "euiRangeTrack--hasLevels")
      }}
      style={{if this.derivedState.styles this.derivedState.styles}}
      ...attributes
      {{didInsert (fn this.validateValueIsInStep @max)}}
      {{didInsert this.registerTrack}}
      {{didUpdate (fn this.validateValueIsInStep @max) @max}}
      {{didUpdate (fn this.validateValueIsInStep @max) @min}}
      {{didUpdate (fn this.validateValueIsInStep @max) @step}}
    >
      {{#if (gt @levels.length 0)}}
        <EuiRangeLevels
          @compressed={{@compressed}}
          @levels={{@levels}}
          @max={{@max}}
          @min={{@min}}
          @showTicks={{@showTicks}}
          @trackWidth={{this.trackEl.clientWidth}}
        />
      {{/if}}
      {{#if this.derivedState.tickSequence}}
        {{#if @ticks}}
          <EuiRangeTicks
            @disabled={{@disabled}}
            @compressed={{@compressed}}
            @ticks={{@ticks}}
            @tickSequence={{this.derivedState.tickSequence}}
            @value={{@value}}
            @min={{@min}}
            @max={{@max}}
            @interval={{or @tickInterval @step}}
            @onChange={{@onChange}}
            @trackWidth={{this.trackEl.clientWidth}}
          />
        {{/if}}
      {{/if}}
      {{yield}}
    </div>
  </template>
}
