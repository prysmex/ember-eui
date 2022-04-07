import Component from '@glimmer/component';
import { action } from '@ember/object';
import { assert } from '@ember/debug';

export type EuiRangeLevelColor = 'primary' | 'success' | 'warning' | 'danger';

export const LEVEL_COLORS: EuiRangeLevelColor[] = [
  'primary',
  'success',
  'warning',
  'danger'
];

export interface EuiRangeLevel {
  min: number;
  max: number;
  color: EuiRangeLevelColor;
}

export type EuiRangeLevelsArgs = {
  levels?: EuiRangeLevel[];
  max: number;
  min: number;
  showTicks?: boolean;
  compressed?: boolean;
};

export default class EuiRangeLevelsComponent extends Component<EuiRangeLevelsArgs> {
  @action
  validateLevels(): void {
    const { min, max } = this.args;
    this.args.levels?.forEach?.((level) => {
      if (level.min < min) {
        assert(
          `The level min of ${level.min} is lower than the min value of ${min}.`,
          true
        );
      }
      if (level.max > max) {
        assert(
          `The level max of ${level.max} is higher than the max value of ${max}.`,
          true
        );
      }
    });
  }
}
