import { action } from '@ember/object';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type { ApplyTime, TimeUnitId } from '../types/global';
import { parseTimeParts } from '../utils/quick-select';
import { NEXT } from '../utils/time-options';
import type { TimeOptions } from '../utils/time-options';
import moment from 'moment';
import dateMath from '@elastic/datemath';
import EuiFlexGroup from '../../eui-flex-group.gts';
import EuiFlexItem from '../../eui-flex-item.gts';
import EuiI18n from '../../eui-i18n.gts';
import EuiToolTip from '../../eui-tool-tip.gts';
import EuiButtonIcon from '../../eui-button-icon.gts';
import EuiFieldNumber from '../../eui-field-number.gts';
import EuiSpacer from '../../eui-spacer.gts';
import EuiSelect from '../../eui-select.gts';
import EuiButton from '../../eui-button.gts';
import pick from 'ember-composable-helpers/helpers/pick';
import set from 'ember-set-helper/helpers/set';
import { lte } from 'ember-truth-helpers';

import { on } from '@ember/modifier';

import uniqueId from '../../../helpers/unique-id';

interface EuiQuickSelectState {
  timeTense: string;
  timeValue: number;
  timeUnits: TimeUnitId;
}

interface EuiQuickSelectArgs {
  applyTime: ApplyTime;
  start: string;
  end: string;
  prevQuickSelect?: EuiQuickSelectState;
  timeOptions: TimeOptions;
}

interface EuiQuickSelectSignature {
  Args: EuiQuickSelectArgs;
  Blocks: { default: [] };
}

export default class EuiQuickSelect extends Component<EuiQuickSelectSignature> {
  @tracked timeTense: string;
  @tracked timeValue: number;
  @tracked timeUnits: TimeUnitId;

  constructor(owner: unknown, args: EuiQuickSelectArgs) {
    super(owner, args);

    const {
      timeTense: timeTenseDefault,
      timeUnits: timeUnitsDefault,
      timeValue: timeValueDefault
    } = parseTimeParts(this.args.start, this.args.end);

    this.timeTense =
      this.args.prevQuickSelect && this.args.prevQuickSelect.timeTense
        ? this.args.prevQuickSelect.timeTense
        : timeTenseDefault;
    this.timeValue =
      this.args.prevQuickSelect && this.args.prevQuickSelect.timeValue
        ? this.args.prevQuickSelect.timeValue
        : timeValueDefault;
    this.timeUnits =
      this.args.prevQuickSelect && this.args.prevQuickSelect.timeUnits
        ? this.args.prevQuickSelect.timeUnits
        : timeUnitsDefault;
  }

  getBounds() {
    const startMoment = dateMath.parse(this.args.start);
    const endMoment = dateMath.parse(this.args.end, { roundUp: true });
    return {
      min:
        startMoment && startMoment.isValid()
          ? startMoment
          : moment().subtract(15, 'minute'),
      max: endMoment && endMoment.isValid() ? endMoment : moment()
    };
  }

  @action applyQuickSelect() {
    if (this.timeTense === NEXT) {
      this.args.applyTime({
        start: 'now',
        end: `now+${this.timeValue}${this.timeUnits}`
        // quickSelect: { ...this.state },
      });
    } else {
      this.args.applyTime({
        start: `now-${this.timeValue}${this.timeUnits}`,
        end: 'now'
        // quickSelect: { ...this.state },
      });
    }
  }

  @action stepForward() {
    const { min, max } = this.getBounds();
    const diff = max.diff(min);
    this.args.applyTime({
      start: moment(max).add(1, 'ms').toISOString(),
      end: moment(max)
        .add(diff + 1, 'ms')
        .toISOString(),
      keepPopoverOpen: true
    });
  }

  @action stepBackward() {
    const { min, max } = this.getBounds();
    const diff = max.diff(min);
    this.args.applyTime({
      start: moment(min)
        .subtract(diff + 1, 'ms')
        .toISOString(),
      end: moment(min).subtract(1, 'ms').toISOString(),
      keepPopoverOpen: true
    });
  }

  <template>
    {{#let (uniqueId) as |legendId|}}
      <fieldset>
        <EuiFlexGroup
          @responsive={{false}}
          @alignItems="center"
          @justifyContent="spaceBetween"
          @gutterSize="s"
        >
          <EuiFlexItem @grow={{false}}>
            <EuiI18n
              @token="euiQuickSelect.quickSelectTitle"
              @default="Quick select"
              as |Token|
            >
              <Token as |quickSelectTitle|>
                <div aria-hidden class="euiFormLabel">
                  {{quickSelectTitle}}
                </div>
              </Token>
            </EuiI18n>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiFlexGroup
              @alignItems="center"
              @gutterSize="s"
              @responsive={{false}}
            >
              <EuiFlexItem @grow={{false}}>
                <EuiI18n
                  @token="euiQuickSelect.previousLabel"
                  @default="Previous time window"
                  as |Token|
                >
                  <Token as |previousLabel|>
                    <EuiToolTip @content={{previousLabel}}>
                      <EuiButtonIcon
                        aria-label={{previousLabel}}
                        @iconType="arrowLeft"
                        {{on "click" this.stepBackward}}
                      />
                    </EuiToolTip>
                  </Token>
                </EuiI18n>
              </EuiFlexItem>
              <EuiFlexItem @grow={{false}}>
                <EuiI18n
                  @token="euiQuickSelect.nextLabel"
                  @default="Next time window"
                  as |Token|
                >
                  <Token as |nextLabel|>
                    <EuiToolTip @content={{nextLabel}}>
                      <EuiButtonIcon
                        aria-label={{nextLabel}}
                        @iconType="arrowRight"
                        {{on "click" this.stepForward}}
                      />
                    </EuiToolTip>
                  </Token>
                </EuiI18n>
              </EuiFlexItem>
            </EuiFlexGroup>
          </EuiFlexItem>
        </EuiFlexGroup>
        <EuiSpacer @size="s" />
        <EuiFlexGroup @gutterSize="s" @responsive={{false}}>
          <EuiFlexItem>
            <EuiI18n
              @token="euiQuickSelect.tenseLabel"
              @default="Time tense"
              as |Token|
            >
              <Token as |tenseLabel|>
                <EuiSelect
                  @compressed={{true}}
                  aria-label={{tenseLabel}}
                  @value={{this.timeTense}}
                  @options={{@timeOptions.timeTenseOptions}}
                  {{on "change" (pick "target.value" (set this "timeTense"))}}
                />
              </Token>
            </EuiI18n>
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiI18n
              @token="euiQuickSelect.valueLabel"
              @default="Time value"
              as |Token|
            >
              <Token as |valueLabel|>
                <EuiFieldNumber
                  @compressed={{true}}
                  aria-label={{valueLabel}}
                  @value={{this.timeValue}}
                  {{on "input" (pick "target.value" (set this "timeValue"))}}
                />
              </Token>
            </EuiI18n>
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiI18n
              @token="euiQuickSelect.unitLabel"
              @default="Time unit"
              as |Token|
            >
              <Token as |unitLabel|>
                <EuiSelect
                  @compressed={{true}}
                  aria-label={{unitLabel}}
                  @value={{this.timeUnits}}
                  @options={{@timeOptions.timeUnitsOptions}}
                  {{on "change" (pick "target.value" (set this "timeUnits"))}}
                />
              </Token>
            </EuiI18n>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButton
              class="euiQuickSelect__applyButton"
              @size="s"
              @disabled={{lte this.timeValue 0}}
              {{on "click" this.applyQuickSelect}}
            >
              <EuiI18n
                @token="euiQuickSelect.applyButton"
                @default="Apply"
                as |Token|
              >
                <Token as |value|>
                  {{value}}
                </Token>
              </EuiI18n>
            </EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </fieldset>
    {{/let}}
  </template>
}
