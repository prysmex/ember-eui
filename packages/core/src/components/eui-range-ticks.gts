import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';

import classNames from '@ember-eui/core/helpers/class-names';
import { eq } from 'ember-truth-helpers';
import { on } from '@ember/modifier';
import optional from 'ember-composable-helpers/helpers/optional';
import getRangeTick from '@ember-eui/core/helpers/get-range-tick';

export interface EuiRangeTick {
  value: number;
  label: Component;
}

type Value = string | number;

export type EuiRangeTicksArgs = {
  ticks?: EuiRangeTick[];
  tickSequence: number[];
  value?: Value | Value[];
  min: number;
  max: number;
  compressed?: boolean;
  interval?: number;
  disabled?: boolean;
};

export default class EuiRangeTicksComponent extends Component<EuiRangeTicksArgs> {
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
            {{derivedState.label}}
          </button>
        {{/let}}
      {{/each}}
    </div>
  </template>
}
