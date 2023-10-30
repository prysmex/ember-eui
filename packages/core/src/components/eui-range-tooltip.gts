import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';

import classNames from '../helpers/class-names';
import { concat } from '@ember/helper';

export interface EuiRangeTick {
  value: number;
  label: Component;
}

export type EuiRangeTooltopArgs = {
  value?: number | string;
  valueAppend?: Component;
  valuePrepend?: Component;
  max: number;
  min: number;
  name?: string;
  showTicks?: boolean;
  compressed?: boolean;
};

type Styling = {
  side: string;
  style: ReturnType<typeof htmlSafe>;
};

export default class EuiRangeToolipComponent extends Component<EuiRangeTooltopArgs> {
  get styling(): Styling {
    const { value, max, min } = this.args;
    let val = 0;
    if (typeof value === 'number') {
      val = value;
    } else if (typeof value === 'string') {
      val = parseFloat(value);
    }
    const decimal = (val - min) / (max - min);
    // Must be between 0-100%
    let valuePosition = decimal <= 1 ? decimal : 1;
    valuePosition = valuePosition >= 0 ? valuePosition : 0;

    let valuePositionSide;
    let valuePositionStyleStr;
    if (valuePosition > 0.5) {
      valuePositionSide = 'left';
      valuePositionStyleStr = `right: ${(1 - valuePosition) * 100}%;`;
    } else {
      valuePositionSide = 'right';
      valuePositionStyleStr = `left: ${valuePosition * 100}%;`;
    }

    return {
      side: valuePositionSide,
      style: htmlSafe(valuePositionStyleStr)
    };
  }

  <template>
    {{! @glint-nocheck: not typesafe yet }}
    <div
      class="euiRangeTooltip {{if @compressed 'euiRangeTooltip--compressed'}}"
    >
      <output
        class={{classNames
          "euiRangeTooltip__value"
          (concat "euiRangeTooltip__value--" this.styling.side)
          (if @showTicks "euiRangeTooltip__value--hasTicks")
        }}
        for={{@name}}
        style={{this.styling.style}}
      >
        {{yield to="valuePrepend"}}
        {{yield to="value"}}
        {{yield to="valueAppend"}}
      </output>
    </div>
  </template>
}
