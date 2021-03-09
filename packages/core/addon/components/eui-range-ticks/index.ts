import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';

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
}
