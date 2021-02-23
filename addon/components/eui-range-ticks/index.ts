import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';

export interface EuiRangeTick {
  value: number;
  label: Component;
}

export type EuiRangeTicksArgs = {
  ticks?: EuiRangeTick[];
  tickSequence: number[];
  value?: number | string | Array<string | number>;
  min: number;
  max: number;
  compressed?: boolean;
  interval?: number;
  disabled?: boolean;
};

export default class EuiRangeTicksComponent extends Component<EuiRangeTicksArgs> {
  get percentageWidth() {
    const { max, min, interval = 1 } = this.args;

    return (interval / (max - min + interval)) * 100;
  }

  get ticksStyle() {
    const { ticks } = this.args;
    return !!ticks
      ? undefined
      : htmlSafe(`margin: 0 ${this.percentageWidth / -2}%; left: 0; right: 0;`);
  }
}
