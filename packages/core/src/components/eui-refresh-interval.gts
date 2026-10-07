import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

import { randomId } from '../-private/random-id.ts';
import EuiButton from './eui-button.gts';
import EuiFieldNumber from './eui-field-number.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';
import EuiSelect from './eui-select.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiTitle from './eui-title.gts';

import type EuiI18n from '../services/eui-i18n';
import type Owner from '@ember/owner';

type Units = 's' | 'm' | 'h';

const SECOND = 1000;
const MINUTE = SECOND * 60;
const HOUR = MINUTE * 60;

function fromMilliseconds(ms: number): { value: number; units: Units } {
  const round = (value: number) => parseFloat(value.toFixed(2));

  if (ms > HOUR) return { units: 'h', value: round(ms / HOUR) };
  if (ms > MINUTE) return { units: 'm', value: round(ms / MINUTE) };

  return { units: 's', value: round(ms / SECOND) };
}

function toMilliseconds(units: Units, value: number): number {
  return Math.round(value * { h: HOUR, m: MINUTE, s: SECOND }[units]);
}

/**
 * "Refresh every [5] [minutes] [Start / Stop]": sets how often data
 * refreshes. `EuiSuperDatePicker` shows it in its quick select popover
 * when given `@onRefreshChange`; it also works on its own.
 */
export interface EuiRefreshIntervalSignature {
  Element: HTMLFieldSetElement;
  Args: {
    /** Whether refreshing is stopped. Defaults to `true`. */
    isPaused?: boolean;
    /** The interval in milliseconds. Defaults to `1000`. */
    refreshInterval?: number;
    /** Called with `{ refreshInterval, isPaused }` after a change. */
    applyRefreshInterval: (args: { refreshInterval: number; isPaused: boolean }) => void;
  };
}

export default class EuiRefreshInterval extends Component<EuiRefreshIntervalSignature> {
  @service declare euiI18n: EuiI18n;

  // the fields, which may be empty or invalid while typing
  @tracked value: number | '';
  @tracked units: Units;

  legendId = `euiRefreshInterval_${randomId()}`;
  descriptionId = `euiRefreshInterval_${randomId()}`;

  constructor(owner: Owner, args: EuiRefreshIntervalSignature['Args']) {
    super(owner, args);

    const { value, units } = fromMilliseconds(args.refreshInterval ?? 1000);

    this.value = value;
    this.units = units;
  }

  get isPaused(): boolean {
    return this.args.isPaused ?? true;
  }

  t = (token: string, text: string, values?: Record<string, unknown>): string =>
    this.euiI18n.lookupToken(token, text, values);

  get unitOptions(): { value: Units; text: string }[] {
    return [
      { value: 's', text: this.t('euiTimeOptions.seconds', 'Seconds') },
      { value: 'm', text: this.t('euiTimeOptions.minutes', 'Minutes') },
      { value: 'h', text: this.t('euiTimeOptions.hours', 'Hours') }
    ];
  }

  get description(): string {
    return this.t(
      'euiRefreshInterval.fullDescription',
      'Refresh interval currently set to {optionValue} {optionText}.',
      {
        optionValue: this.value,
        optionText: this.unitOptions.find((option) => option.value === this.units)?.text ?? ''
      }
    );
  }

  get isInvalid(): boolean {
    return this.value === '' || this.value <= 0;
  }

  apply(): void {
    if (this.value === '') return;

    const refreshInterval = toMilliseconds(this.units, this.value);

    this.args.applyRefreshInterval({
      refreshInterval,
      isPaused: refreshInterval <= 0 ? true : this.isPaused
    });
  }

  @action
  onValueInput(event: Event): void {
    const value = parseFloat((event.target as HTMLInputElement).value);

    this.value = isNaN(value) ? '' : value;
    this.apply();
  }

  @action
  onUnitsChange(event: Event): void {
    this.units = (event.target as HTMLSelectElement).value as Units;
    this.apply();
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    // Enter starts refreshing
    if (event.key !== 'Enter' || this.isInvalid || this.value === '') return;

    this.args.applyRefreshInterval({
      refreshInterval: toMilliseconds(this.units, this.value),
      isPaused: false
    });
  }

  @action
  toggle(): void {
    if (this.value === '') return;

    this.args.applyRefreshInterval({
      refreshInterval: toMilliseconds(this.units, this.value),
      isPaused: !this.isPaused
    });
  }

  <template>
    <fieldset ...attributes>
      <EuiTitle @size="xxxs" @tagName="legend" id={{this.legendId}}>
        {{this.t "euiRefreshInterval.legend" "Refresh every"}}
      </EuiTitle>
      <EuiSpacer @size="s" />
      <EuiFlexGroup @gutterSize="s" @responsive={{false}}>
        <EuiFlexItem>
          <EuiFieldNumber
            @compressed={{true}}
            @value={{this.value}}
            aria-label="Refresh interval value"
            aria-describedby="{{this.descriptionId}} {{this.legendId}}"
            data-test-subj="superDatePickerRefreshIntervalInput"
            {{on "input" this.onValueInput}}
            {{on "keydown" this.onKeyDown}}
          />
        </EuiFlexItem>
        <EuiFlexItem>
          <EuiSelect
            @compressed={{true}}
            @value={{this.units}}
            @options={{this.unitOptions}}
            aria-label="Refresh interval units"
            aria-describedby="{{this.descriptionId}} {{this.legendId}}"
            data-test-subj="superDatePickerRefreshIntervalUnitsSelect"
            {{on "change" this.onUnitsChange}}
            {{on "keydown" this.onKeyDown}}
          />
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton
            class="euiRefreshInterval__startButton"
            @iconType={{if this.isPaused "play" "stop"}}
            @size="s"
            @isDisabled={{this.isInvalid}}
            data-test-subj="superDatePickerToggleRefreshButton"
            aria-describedby={{this.descriptionId}}
            {{on "click" this.toggle}}
          >
            {{#if this.isPaused}}
              {{this.t "euiRefreshInterval.start" "Start"}}
            {{else}}
              {{this.t "euiRefreshInterval.stop" "Stop"}}
            {{/if}}
          </EuiButton>
        </EuiFlexItem>
      </EuiFlexGroup>
      <EuiScreenReaderOnly><p id={{this.descriptionId}}>{{this.description}}</p></EuiScreenReaderOnly>
    </fieldset>
  </template>
}
