import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import type Owner from '@ember/owner';
import { service } from '@ember/service';

import dateMath from '@elastic/datemath';
import pick from '@nullvoxpopuli/ember-composable-helpers/helpers/pick';
import set from 'ember-set-helper/helpers/set';
import { lte } from 'ember-truth-helpers';
import moment from 'moment';

import { randomId } from '../../../-private/random-id.ts';
import { euiQuickSelectStyles } from '../../../utils/eui/date-pickers.ts';
import type { EuiCss } from '../../../utils/eui/styles.ts';
import EuiButton from '../../eui-button.gts';
import EuiButtonIcon from '../../eui-button-icon.gts';
import EuiFieldNumber from '../../eui-field-number.gts';
import EuiFlexGroup from '../../eui-flex-group.gts';
import EuiFlexItem from '../../eui-flex-item.gts';
import EuiI18n from '../../eui-i18n.gts';
import EuiScreenReaderOnly from '../../eui-screen-reader-only.gts';
import EuiSelect from '../../eui-select.gts';
import EuiToolTip from '../../eui-tool-tip.gts';
import { parseTimeParts } from '../utils/quick-select.ts';
import { NEXT } from '../utils/time-options.ts';
import EuiQuickSelectPanel from './eui-quick-select-panel.gts';

import type EuiI18nService from '../../../services/eui-i18n';

import type { ApplyTime, TimeUnitId } from '../types/global';
import type { TimeOptions } from '../utils/time-options.ts';

interface EuiQuickSelectState {
  timeTense: string;
  timeValue: number;
  timeUnits: TimeUnitId;
}

interface EuiQuickSelectArgs {
  /** Applies a new `{ start, end }` range. */
  applyTime: ApplyTime;
  /** Start of the range (date math or ISO date). */
  start: string;
  /** End of the range. */
  end: string;
  /** The last quick select, to prefill it. */
  prevQuickSelect?: EuiQuickSelectState;
  /** Time units and tenses for the quick select. */
  timeOptions: TimeOptions;
}

/** @private The "Quick select" part of the quick select popover. */
export interface EuiQuickSelectSignature {
  Args: EuiQuickSelectArgs;
  Blocks: { default: [] };
}

export default class EuiQuickSelect extends Component<EuiQuickSelectSignature> {
  @service('eui-i18n') declare euiI18n: EuiI18nService;

  legendId = randomId();
  timeSelectionId = randomId();
  panelCss = euiQuickSelectStyles.panel;
  @tracked timeTense: string;
  @tracked timeValue: number;
  @tracked timeUnits: TimeUnitId;

  constructor(owner: Owner, args: EuiQuickSelectArgs) {
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

  @action
  applyQuickSelect() {
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

  @action
  stepForward() {
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

  @action
  stepBackward() {
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

  get title() {
    return this.euiI18n.lookupToken(
      'euiQuickSelect.quickSelectTitle',
      'Quick select'
    );
  }

  get describedBy() {
    return `${this.timeSelectionId} ${this.legendId}`;
  }

  /** Upstream's screen reader summary of the current selection. */
  get description() {
    const unit = this.args.timeOptions.timeUnitsOptions.find(
      ({ value }) => value === this.timeUnits
    );
    return this.euiI18n.lookupToken(
      'euiQuickSelect.fullDescription',
      'Currently set to {timeTense} {timeValue} {timeUnit}.',
      {
        timeTense: this.timeTense,
        timeValue: this.timeValue,
        timeUnit: unit ? unit.text : ''
      }
    );
  }

  /**
   * The previous/next buttons sit above the inputs, next to the title
   * (upstream's `css` on their EuiFlexGroup).
   */
  get timeWindowButtonsCss(): EuiCss {
    return euiQuickSelectStyles.timeWindowButtons;
  }

  @action
  onTimeValueInput(event: Event) {
    // upstream: a non-number value becomes 0, which disables "Apply"
    const value = parseInt((event.target as HTMLInputElement).value, 10);
    this.timeValue = isNaN(value) ? 0 : value;
  }

  /** Enter in any of the fields applies the quick selection (upstream). */
  @action
  onKeyDown(event: KeyboardEvent) {
    if (event.key === 'Enter') this.applyQuickSelect();
  }

  <template>
    <EuiQuickSelectPanel
      @tagName="fieldset"
      @title={{this.title}}
      @titleId={{this.legendId}}
      @css={{this.panelCss}}
      aria-describedby={{this.timeSelectionId}}
    >
      <EuiFlexGroup
        class="euiQuickSelect__timeWindowButtons"
        @alignItems="center"
        @gutterSize="s"
        @responsive={{false}}
        @css={{this.timeWindowButtonsCss}}
      >
        <EuiFlexItem @grow={{false}}>
          <EuiI18n
            @token="euiQuickSelect.previousLabel"
            @default="Previous time window"
            as |Token|
          >
            <Token as |previousLabel|>
              <EuiToolTip
                @content={{previousLabel}}
                @disableScreenReaderOutput={{true}}
              >
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
              <EuiToolTip
                @content={{nextLabel}}
                @disableScreenReaderOutput={{true}}
              >
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
                aria-describedby={{this.describedBy}}
                @value={{this.timeTense}}
                @options={{@timeOptions.timeTenseOptions}}
                {{on "change" (pick "target.value" (set this "timeTense"))}}
                {{on "keydown" this.onKeyDown}}
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
                aria-describedby={{this.describedBy}}
                @value={{this.timeValue}}
                {{on "input" this.onTimeValueInput}}
                {{on "keydown" this.onKeyDown}}
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
                aria-describedby={{this.describedBy}}
                @value={{this.timeUnits}}
                @options={{@timeOptions.timeUnitsOptions}}
                {{on "change" (pick "target.value" (set this "timeUnits"))}}
                {{on "keydown" this.onKeyDown}}
              />
            </Token>
          </EuiI18n>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton
            class="euiQuickSelect__applyButton"
            aria-describedby={{this.describedBy}}
            data-test-subj="superDatePickerQuickSelectApplyButton"
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
      <EuiScreenReaderOnly>
        <p id={{this.timeSelectionId}}>{{this.description}}</p>
      </EuiScreenReaderOnly>
    </EuiQuickSelectPanel>
  </template>
}
