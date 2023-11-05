import Component from '@glimmer/component';
import dateMath from '@elastic/datemath';
import { INVALID_DATE, toRelativeStringFromParts } from '../utils';
import type { LocaleSpecifier } from 'moment';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { parseRelativeParts } from '../utils';
import type { TimeOptions } from '../utils/time-options';
import EuiForm from '../../eui-form.gts';
import EuiFlexGroup from '../../eui-flex-group.gts';
import EuiFlexItem from '../../eui-flex-item.gts';
import EuiFormRow from '../../eui-form-row.gts';
import EuiSelect from '../../eui-select.gts';
import EuiFieldText from '../../eui-field-text.gts';
import EuiFormLabel from '../../eui-form-label.gts';
import EuiFieldNumber from '../../eui-field-number.gts';
import EuiSpacer from '../../eui-spacer.gts';
import EuiPopoverFooter from '../../eui-popover-footer.gts';
import EuiSwitch from '../../eui-switch.gts';
import pick from 'ember-composable-helpers/helpers/pick';
import { on } from '@ember/modifier';

interface RelativeTabArgs {
  dateFormat: string;
  locale?: LocaleSpecifier;
  value: string;
  onChange: (value: string, event?: Event) => void;
  roundUp?: boolean;
  position: 'start' | 'end';
  labelPrefix: string;
  timeOptions: TimeOptions;
}

export interface RelativeTabSignature {
  Args: RelativeTabArgs;
}

export default class RelativeTab extends Component<RelativeTabSignature> {
  @tracked count?: number;
  @tracked unit: any = 'm';
  @tracked round = false;

  roundUnit;

  constructor(owner: unknown, args: RelativeTabArgs) {
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

  @action onCountChange(e: Event) {
    const sanitizedValue = parseInt((e.target as HTMLInputElement).value, 10);
    this.count = isNaN(sanitizedValue) ? undefined : sanitizedValue;
    this.handleChange();
  }

  @action onUnitChange(unit: string) {
    this.unit = unit as any;
    this.handleChange();
  }

  @action onRoundChange(checked: boolean) {
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
    <EuiForm class="euiDatePopoverContent__padded">
      <EuiFlexGroup @gutterSize="s" @responsive={{false}}>
        <EuiFlexItem>
          <EuiFormRow>
            <EuiFieldNumber
              @compressed={{true}}
              @value={{this.count}}
              @min="0"
              {{on "input" this.onCountChange}}
            />
          </EuiFormRow>
        </EuiFlexItem>
        <EuiFlexItem>
          <EuiSelect
            @compressed={{true}}
            @value={{this.unit}}
            @options={{@timeOptions.relativeOptions}}
            {{on "change" (pick "target.value" this.onUnitChange)}}
          />
        </EuiFlexItem>
      </EuiFlexGroup>
      <EuiSpacer @size="s" />
      <EuiFieldText
        @compressed={{true}}
        @value={{this.formattedValue}}
        @readOnly={{true}}
      >
        <:prepend>
          <EuiFormLabel>{{@labelPrefix}}</EuiFormLabel>
        </:prepend>
      </EuiFieldText>
    </EuiForm>
    <EuiPopoverFooter @paddingSize="s">
      <EuiSwitch
        @label={{this.roundingLabel}}
        @checked={{this.round}}
        @onChange={{pick "target.checked" this.onRoundChange}}
      />
    </EuiPopoverFooter>
  </template>
}
