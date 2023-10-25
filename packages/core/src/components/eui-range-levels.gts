import Component from '@glimmer/component';
import { action } from '@ember/object';
import { assert } from '@ember/debug';

import classNames from '@ember-eui/core/helpers/class-names';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { hash } from '@ember/helper';
import simpleStyle from '@ember-eui/core/modifiers/simple-style';
import inlineStyles from '@ember-eui/core/helpers/inline-styles';

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

  <template>
    <div
      class={{classNames
        "euiRangeLevels"
        (if @showTicks "euiRangeLevels--hasTicks")
        (if @compressed "euiRangeLevels--compressed")
      }}
      {{didInsert this.validateLevels}}
      {{didUpdate this.validateLevels @levels}}
      {{didUpdate this.validateLevels @min}}
      {{didUpdate this.validateLevels @max}}
    >
      {{#each @levels as |level|}}
        <span
          class="euiRangeLevel euiRangeLevel--{{level.color}}"
          {{simpleStyle
            (inlineStyles
              componentName="EuiRangeLevels"
              componentArgs=(hash
                level=level max=@max min=@min trackWidth=@trackWidth
              )
            )
          }}
        ></span>
      {{/each}}
    </div>
  </template>
}
