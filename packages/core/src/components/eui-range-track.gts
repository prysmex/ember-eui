import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';

import { range } from 'lodash-es';
import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiRangeTrackStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { isEvenlyDivisibleBy } from '../utils/number/index.ts';
import { LEVEL_COLORS } from './eui-range-levels.gts';
import EuiRangeLevels from './eui-range-levels.gts';
import EuiRangeTicks from './eui-range-ticks.gts';

import type { EuiRangeLevel } from './eui-range-levels';
import type { EuiRangeTick } from './eui-range-ticks';

export { LEVEL_COLORS };
export type { EuiRangeTick };

type Value = number | string;

export type EuiRangeTrackArgs = {
  /** Lowest value. */
  min: number;
  /** Highest value. */
  max: number;
  /** Increment between values. */
  step?: number;
  /** The value. */
  value?: Value | Value[];
  /** Compressed (smaller) tick spacing. */
  compressed?: boolean;
  /** Disabled styling (half opacity) and disabled ticks. */
  disabled?: boolean;
  /** Shows the ticks and leaves room for them under the track. */
  showTicks?: boolean;
  /** Stripes the levels, so a highlighted range stands out. */
  showRange?: boolean;
  /** Interval between ticks. */
  tickInterval?: number;
  /** Custom ticks, see `EuiRangeTick`. */
  ticks?: EuiRangeTick[];
  /** Called when a tick is clicked. */
  onChange?: (e: MouseEvent) => void;
  /** Colored intervals, see `EuiRangeLevel`. */
  levels?: EuiRangeLevel[];
};

/**
 * @private The track (levels, ticks and the yielded slider/highlight/thumbs)
 * of EuiRange / EuiDualRange.
 */
export interface EuiRangeTrackSignature {
  Element: HTMLElement;
  Args: EuiRangeTrackArgs;
  Blocks: {
    /** Yields the measured track width in px (0 until measured). */
    default: [trackWidth: number];
  };
}

function validateValueIsInStep(
  value: number,
  { min, max, step }: { min: number; max: number; step?: number }
): number {
  assert(
    `The value of ${value} is lower than the min value of ${min}.`,
    !(value < min)
  );
  assert(
    `The value of ${value} is higher than the max value of ${max}.`,
    !(value > max)
  );
  assert(
    `The value of ${value} is not included in the possible sequence provided by the step of ${step}.`,
    isEvenlyDivisibleBy(value - min, step !== undefined ? step : 1)
  );
  return value;
}

/**
 * Upstream `EuiRangeTrack`: the 6px track line (`::after`), levels and ticks.
 * The track measures itself (like upstream's resize observer on the slider)
 * and yields the width for thumb, tick and level positions.
 */
export default class EuiRangeTrack extends Component<EuiRangeTrackSignature> {
  @tracked trackWidth = 0;
  /** Untracked copy, so the modifier never reads what it writes. */
  measuredWidth = 0;

  measure = modifier((element: HTMLElement) => {
    const update = () => {
      const width = element.clientWidth;
      if (width === this.measuredWidth) return;
      this.measuredWidth = width;
      this.trackWidth = width;
    };
    update();
    if (typeof ResizeObserver === 'undefined') return;
    const observer = new ResizeObserver(update);
    observer.observe(element);
    return () => observer.disconnect();
  });

  @cached
  get tickSequence(): number[] | undefined {
    const { showTicks, min, max, step, tickInterval, ticks } = this.args;
    validateValueIsInStep(max, { min, max, step });
    if (showTicks !== true) return undefined;
    if (ticks) {
      // Custom ticks must line up with the possible sequence
      return ticks.map((tick) =>
        validateValueIsInStep(tick.value, { min, max, step })
      );
    }
    // (adds a tiny number to the max since `range` is not inclusive of it)
    const interval = tickInterval || step;
    return range(min, max + 0.000000001, interval).map((tick) =>
      validateValueIsInStep(tick, { min, max, step })
    );
  }

  get hasLevels(): boolean {
    return !!this.args.levels && this.args.levels.length > 0;
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiRangeTrackStyles);
    const { disabled, showTicks, ticks } = this.args;
    return `euiRangeTrack ${euiClass(
      context,
      styles.euiRangeTrack,
      disabled && styles.disabled,
      this.hasLevels && styles.hasLevels,
      showTicks && (this.tickSequence || ticks) && styles.hasTicks
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes {{this.measure}}>
      {{#if this.hasLevels}}
        <EuiRangeLevels
          @levels={{@levels}}
          @max={{@max}}
          @min={{@min}}
          @showTicks={{@showTicks}}
          @showRange={{@showRange}}
          @trackWidth={{this.trackWidth}}
        />
      {{/if}}
      {{#if this.tickSequence}}
        <EuiRangeTicks
          @disabled={{@disabled}}
          @compressed={{@compressed}}
          @ticks={{@ticks}}
          @tickSequence={{this.tickSequence}}
          @value={{@value}}
          @min={{@min}}
          @max={{@max}}
          @interval={{if @tickInterval @tickInterval @step}}
          @onChange={{@onChange}}
          @trackWidth={{this.trackWidth}}
        />
      {{/if}}
      {{yield this.trackWidth}}
    </div>
  </template>
}
