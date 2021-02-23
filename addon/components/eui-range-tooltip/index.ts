import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';
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

export default class EuiRangeToolipComponent extends Component<EuiRangeTooltopArgs> {
  get styling() {
    let { value, max, min } = this.args;
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
      style: htmlSafe(valuePositionStyleStr),
    };
  }
}
