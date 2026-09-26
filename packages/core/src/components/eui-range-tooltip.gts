import Component from '@glimmer/component';
import { concat } from '@ember/helper';
import { htmlSafe } from '@ember/template';

import classNames from '../helpers/class-names.ts';

/** A custom tick of EuiRange / EuiDualRange: `{ value: 20, label: '20kb' }`. */
export interface EuiRangeTick {
  /** Where the tick is. */
  value: number;
  /** Its label. */
  label: Component;
}

export type EuiRangeTooltipArgs = {
  /** The value. */
  value?: number | string;
  /** Content after the value. */
  valueAppend?: Component;
  /** Content before the value. */
  valuePrepend?: Component;
  /** Highest value. */
  max: number;
  /** Lowest value. */
  min: number;
  /** `name` of the input. */
  name?: string;
  /** Leaves room for ticks under the track. */
  showTicks?: boolean;
  /** Compressed (smaller) styling. */
  compressed?: boolean;
};

type Styling = {
  side: string;
  style: ReturnType<typeof htmlSafe>;
};

/** @private The value tooltip of EuiRange (`@showValue`). */
export interface EuiRangeTooltipSignature {
  Args: EuiRangeTooltipArgs;
  Blocks: {
    valuePrepend: [];
    value: [];
    valueAppend: [];
  };
}

export default class EuiRangeToolipComponent extends Component<EuiRangeTooltipSignature> {
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
