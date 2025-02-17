import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { eq } from 'ember-truth-helpers';

import classNames from '../helpers/class-names.ts';
import getRangeTick from '../helpers/get-range-tick.ts';

export interface EuiRangeTick {
  value: number;
  label: Component;
}

type Value = string | number;

export type EuiRangeTicksArgs = {
  ticks: EuiRangeTick[];
  tickSequence: number[];
  value?: Value | Value[];
  min: number;
  max: number;
  compressed?: boolean;
  interval?: number;
  disabled?: boolean;
  onChange?: (e: MouseEvent) => void;
  trackWidth: number;
};

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

  <template>
    <div
      class="euiRangeTicks {{if @compressed 'euiRangeTicks--compressed'}}"
      style={{this.ticksStyle}}
      ...attributes
    >
      {{#each @tickSequence key="value" as |tickValue|}}
        {{#let
          (getRangeTick
            @ticks tickValue @min @max this.percentageWidth @trackWidth
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
