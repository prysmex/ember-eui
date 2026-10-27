import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import type Owner from '@ember/owner';

import dateMath from '@elastic/datemath';
import pick from '@nullvoxpopuli/ember-composable-helpers/helpers/pick';
import { service } from '@ember/service';

import { randomId } from '../../../-private/random-id.ts';
import { getEuiThemeContext } from '../../../utils/emotion/consume.ts';
import { euiPaddingSize } from '../../../utils/eui/styles.generated.ts';
import { euiClass } from '../../../utils/eui/styles.ts';

import EuiFieldNumber from '../../eui-field-number.gts';
import EuiFieldText from '../../eui-field-text.gts';
import EuiFlexGroup from '../../eui-flex-group.gts';
import EuiFlexItem from '../../eui-flex-item.gts';
import EuiForm from '../../eui-form.gts';
import EuiFormLabel from '../../eui-form-label.gts';
import EuiFormRow from '../../eui-form-row.gts';
import EuiPopoverFooter from '../../eui-popover-footer.gts';
import EuiScreenReaderOnly from '../../eui-screen-reader-only.gts';
import EuiSelect from '../../eui-select.gts';
import EuiSpacer from '../../eui-spacer.gts';
import EuiSwitch from '../../eui-switch.gts';
import { INVALID_DATE, toRelativeStringFromParts } from '../utils/index.ts';
import { parseRelativeParts } from '../utils/index.ts';

import EuiTimeZoneDisplay from './eui-time-zone-display.gts';

import type EuiI18n from '../../../services/eui-i18n';
import type { EuiTimeZoneDisplayProps } from './eui-time-zone-display.gts';
import type { TimeOptions } from '../utils/time-options.ts';
import type { LocaleSpecifier } from 'moment';

interface RelativeTabArgs {
  /** moment format of absolute dates. */
  dateFormat: string;
  /** moment locale; `'en'` when unset or `null`. */
  locale?: LocaleSpecifier | null;
  /** The date (date math or ISO date). */
  value: string;
  /** Called with the new value. */
  onChange: (value: string, event?: Event) => void;
  /** Rounds relative dates up (for the end of a range). */
  roundUp?: boolean;
  /** `'start'` or `'end'` of the range. */
  position: 'start' | 'end';
  /** Prefix of the input labels, e.g. "Start date". */
  labelPrefix: string;
  /** Time units and tenses for the quick select. */
  timeOptions: TimeOptions;
  /** Shows the time zone under the form (see `EuiTimeZoneDisplay`). */
  timeZoneDisplayProps?: EuiTimeZoneDisplayProps;
}

/** @private The "Relative" tab of the date popover. */
export interface RelativeTabSignature {
  Args: RelativeTabArgs;
}

export default class RelativeTab extends Component<RelativeTabSignature> {
  @tracked count?: number;
  @tracked unit: any = 'm';
  @tracked round = false;

  roundUnit;

  @service declare euiI18n: EuiI18n;

  labelId = randomId();
  descriptionId = randomId();
  timeZoneDescriptionId = randomId();

  /** Upstream pads the form with `useEuiPaddingCSS().s`. */
  @cached
  get paddingClass() {
    const context = getEuiThemeContext(this);
    return euiClass(context, {
      boxSizing: 'border-box',
      padding: euiPaddingSize(context.upstream, 's')
    });
  }

  get isInvalid() {
    return (
      this.count === undefined ||
      this.count < 0 ||
      this.args.value === INVALID_DATE
    );
  }

  get numberLabel() {
    return this.euiI18n.lookupToken(
      'euiRelativeTab.numberInputLabel',
      'Time span amount'
    );
  }

  get unitLabel() {
    return this.euiI18n.lookupToken(
      'euiRelativeTab.unitInputLabel',
      'Relative time span'
    );
  }

  get description() {
    return this.euiI18n.lookupToken(
      'euiRelativeTab.fullDescription',
      'The unit is changeable. Currently set to {unit}.',
      { unit: this.unit }
    );
  }

  constructor(owner: Owner, args: RelativeTabArgs) {
    super(owner, args);

    const parsed = parseRelativeParts(this.args.value);

    if (parsed) {
      this.count = parsed.count;
      this.unit = parsed.unit as any;
      this.round = parsed.round;
      this.roundUnit = parsed.roundUnit;
    }
  }

  get formattedValue() {
    const invalidDate = this.args.value === INVALID_DATE;
    const invalidValue = this.count === undefined || this.count < 0;
    const isInvalid = invalidValue || invalidDate;
    const parsedValue = dateMath.parse(this.args.value, {
      roundUp: this.args.roundUp
    });
    const invalid = isInvalid || !parsedValue || !parsedValue.isValid();

    return invalid
      ? ''
      : parsedValue
          .locale(this.args.locale || 'en')
          .format(this.args.dateFormat);
  }

  get roundingLabel() {
    //@ts-expect-error
    return this.args.timeOptions.relativeRoundingLabels[this.unit[0]];
  }

  @action
  onCountChange(e: Event) {
    const sanitizedValue = parseInt((e.target as HTMLInputElement).value, 10);

    this.count = isNaN(sanitizedValue) ? undefined : sanitizedValue;
    this.handleChange();
  }

  @action
  onUnitChange(unit: string) {
    this.unit = unit as any;
    this.handleChange();
  }

  @action
  onRoundChange(checked: boolean) {
    this.round = checked;
    this.handleChange();
  }

  handleChange(e?: Event) {
    if (this.count === undefined || this.count < 0) {
      return;
    }

    const date = toRelativeStringFromParts({
      count: this.count,
      round: this.round,
      roundUnit: this.roundUnit as any,
      unit: this.unit
    });

    this.args.onChange(date, e);
  }

  <template>
    <EuiForm class="euiDatePopoverContent__padded {{this.paddingClass}}">
      <EuiFlexGroup @gutterSize="s" @responsive={{false}}>
        <EuiFlexItem>
          <EuiFormRow @isInvalid={{this.isInvalid}}>
            <EuiFieldNumber
              @compressed={{true}}
              @value={{this.count}}
              @min="0"
              @isInvalid={{this.isInvalid}}
              aria-label={{this.numberLabel}}
              aria-describedby={{this.descriptionId}}
              data-test-subj="superDatePickerRelativeDateInputNumber"
              {{on "input" this.onCountChange}}
            />
          </EuiFormRow>
        </EuiFlexItem>
        <EuiFlexItem>
          <EuiSelect
            @compressed={{true}}
            @value={{this.unit}}
            @options={{@timeOptions.relativeOptions}}
            aria-label={{this.unitLabel}}
            data-test-subj="superDatePickerRelativeDateInputUnitSelector"
            {{on "change" (pick "target.value" this.onUnitChange)}}
          />
        </EuiFlexItem>
      </EuiFlexGroup>
      <EuiSpacer @size="s" />
      <EuiFieldText
        aria-labelledby={{this.labelId}}
        @compressed={{true}}
        @value={{this.formattedValue}}
        @readOnly={{true}}
        aria-describedby={{this.timeZoneDescriptionId}}
      >
        <:prepend as |classes|>
          <EuiFormLabel id={{this.labelId}} class={{classes}}>
            {{@labelPrefix}}
          </EuiFormLabel>
        </:prepend>
      </EuiFieldText>
      <EuiScreenReaderOnly>
        <p id={{this.descriptionId}}>{{this.description}}</p>
      </EuiScreenReaderOnly>
    </EuiForm>
    <EuiTimeZoneDisplay
      @id={{this.timeZoneDescriptionId}}
      @timeZone={{@timeZoneDisplayProps.timeZone}}
      @date={{@timeZoneDisplayProps.date}}
      @customRender={{@timeZoneDisplayProps.customRender}}
    />
    <EuiPopoverFooter @paddingSize="s">
      <EuiSwitch
        data-test-subj="superDatePickerRelativeDateRoundSwitch"
        @label={{this.roundingLabel}}
        @checked={{this.round}}
        @onChange={{pick "target.checked" this.onRoundChange}}
      />
    </EuiPopoverFooter>
  </template>
}
