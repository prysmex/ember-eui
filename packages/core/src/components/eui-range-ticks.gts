import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { eq } from 'ember-truth-helpers';

import classNames from '../helpers/class-names.ts';
import getRangeTick from '../helpers/get-range-tick.ts';

/** A custom tick of EuiRange / EuiDualRange: `{ value: 20, label: '20kb' }`. */
export interface EuiRangeTick {
  /** Where the tick is. */
  value: number;
  /** Its label. */
  label: Component;
}

type Value = string | number;

export type EuiRangeTicksArgs = {
  /** Custom ticks; without them, ticks are rendered for every interval step */
  ticks?: EuiRangeTick[];
  /** Values to render ticks at. */
  tickSequence: number[];
  /** The value. */
  value?: Value | Value[];
  /** Lowest value. */
  min: number;
  /** Highest value. */
  max: number;
  /** Compressed (smaller) styling. */
  compressed?: boolean;
  /** Interval between ticks. */
  interval?: number;
  /** Disabled styling. */
  disabled?: boolean;
  /** Called when the value changes (a tick or the track is clicked). */
  onChange?: (e: MouseEvent) => void;
  /** Width of the track in px. */
  trackWidth?: number;
};

/** @private The ticks under the track of EuiRange / EuiDualRange. */
export interface EuiRangeTicksSignature {
  Element: HTMLDivElement;
  Args: EuiRangeTicksArgs;
}

export default class EuiRangeTicksComponent extends Component<EuiRangeTicksSignature> {
  get percentageWidth(): number {
    const { max, min, interval = 1 } = this.args;

    return (interval / (max - min + interval)) * 100;
  }

  get ticksStyle(): ReturnType<typeof htmlSafe> | undefined {
    const { ticks } = this.args;

    return !ticks
      ? undefined
      : htmlSafe(`margin: 0 ${this.percentageWidth / -2}%; left: 0; right: 0;`);
  }

  get trackWidth(): number {
    return this.args.trackWidth || 0;
  }

  <template>
    <div
      class="euiRangeTicks {{if @compressed 'euiRangeTicks--compressed'}}"
      style={{this.ticksStyle}}
      ...attributes
    >
      {{#each @tickSequence key="value" as |tickValue|}}
        {{#let
          (getRangeTick
            @ticks tickValue @min @max this.percentageWidth this.trackWidth
          )
          as |derivedState|
        }}
          <button
            type="button"
            class={{classNames
              (if (eq @value tickValue) "euiRangeTick--selected")
              (if derivedState.customTick "euiRangeTick--isCustom")
              "euiRangeTick"
            }}
            value={{tickValue}}
            disabled={{@disabled}}
            style={{derivedState.style}}
            tabindex="-1"
            {{on "click" (optional @onChange)}}
          >
            {{!@glint-expect-error}}
            {{derivedState.label}}
          </button>
        {{/let}}
      {{/each}}
    </div>
  </template>
}
