import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';

import { randomId } from '../-private/random-id.ts';
import EuiFieldNumber from './eui-field-number.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiFormLabel from './eui-form-label.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';
import EuiSelect from './eui-select.gts';
import EuiSwitch from './eui-switch.gts';
import EuiQuickSelectPanel from './eui-super-date-picker/eui-quick-select-popover/eui-quick-select-panel.gts';

import type EuiI18n from '../services/eui-i18n';
import type Owner from '@ember/owner';

type Units = 's' | 'm' | 'h';

const SECOND = 1000;
const MINUTE = SECOND * 60;
const HOUR = MINUTE * 60;

function fromMilliseconds(
  ms: number,
  unit?: Units
): { value: number; units: Units } {
  const round = (value: number) => parseFloat(value.toFixed(2));

  if (unit === 'h' || (!unit && ms > HOUR))
    return { units: 'h', value: round(ms / HOUR) };
  if (unit === 'm' || (!unit && ms > MINUTE))
    return { units: 'm', value: round(ms / MINUTE) };

  return { units: 's', value: round(ms / SECOND) };
}

function toMilliseconds(units: Units, value: number): number {
  return Math.round(value * { h: HOUR, m: MINUTE, s: SECOND }[units]);
}

/** Upstream: the smallest whole number of `unit`s allowed by `minInterval`. */
function getMinInterval(minInterval: number | undefined, unit?: Units): number {
  if (!minInterval) return 0;

  return Math.floor(fromMilliseconds(minInterval, unit).value || 0);
}

/**
 * "[switch] Refresh every [5] [minutes]": sets how often data refreshes.
 * The switch turns refreshing on and off; the interval fields are
 * disabled while it is off (upstream EUI). `EuiSuperDatePicker` shows it in its quick select popover
 * when given `@onRefreshChange`; it also works on its own.
 */
export interface EuiRefreshIntervalSignature {
  Element: HTMLFieldSetElement;
  Args: {
    /** Whether refreshing is stopped. Defaults to `true`. */
    isPaused?: boolean;
    /** The interval in milliseconds. Defaults to `1000`. */
    refreshInterval?: number;
    /**
     * The smallest interval in milliseconds; edits are raised to it and the
     * number field's `min` follows it. Defaults to `0`.
     */
    minInterval?: number;
    /**
     * Shows the interval in this unit (`'s'`, `'m'` or `'h'`) instead of the
     * largest unit that fits (90 seconds becomes 2 minutes).
     */
    intervalUnits?: Units;
    /** Called with `{ refreshInterval, isPaused }` after a change. */
    applyRefreshInterval?: (args: { refreshInterval: number; isPaused: boolean }) => void;
    /**
     * Upstream's callback: called like `@applyRefreshInterval`, with the
     * chosen `intervalUnits` as well.
     */
    onRefreshChange?: (args: {
      refreshInterval: number;
      isPaused: boolean;
      intervalUnits: Units;
    }) => void;
  };
}

export default class EuiRefreshInterval extends Component<EuiRefreshIntervalSignature> {
  @service declare euiI18n: EuiI18n;

  // the fields, which may be empty or invalid while typing
  @tracked value: number | '';
  @tracked units: Units;
  private lastAppliedInterval?: number;

  descriptionId = `euiRefreshInterval_${randomId()}`;

  constructor(owner: Owner, args: EuiRefreshIntervalSignature['Args']) {
    super(owner, args);

    const { value, units } = fromMilliseconds(
      args.refreshInterval ?? 1000,
      args.intervalUnits
    );

    this.value = value;
    this.units = units;
  }

  get isPaused(): boolean {
    return this.args.isPaused ?? true;
  }

  @action
  syncInterval(): void {
    const interval = this.args.refreshInterval ?? 1000;

    // Preserve the user's units when the owner accepts an edit. Independent
    // argument changes replace the local draft, including invalid/empty input.
    if (interval !== this.lastAppliedInterval || this.value === '') {
      const { value, units } = fromMilliseconds(
        interval,
        this.args.intervalUnits
      );
      this.value = value;
      this.units = units;
    }

    this.lastAppliedInterval = undefined;
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
    const values = {
      optionValue: this.value,
      optionText: this.unitOptions.find((option) => option.value === this.units)?.text ?? ''
    };

    return this.isPaused
      ? this.t(
          'euiRefreshInterval.fullDescriptionOff',
          'Refresh is off, interval set to {optionValue} {optionText}.',
          values
        )
      : this.t(
          'euiRefreshInterval.fullDescriptionOn',
          'Refresh is on, interval set to {optionValue} {optionText}.',
          values
        );
  }

  get isInvalid(): boolean {
    return this.value === '' || this.value <= 0;
  }

  /** Upstream marks the value invalid only while refreshing. */
  get showInvalid(): boolean {
    return !this.isPaused && this.isInvalid;
  }

  get toggleLabel(): string {
    return this.t('euiRefreshInterval.toggleLabel', 'Refresh every');
  }

  get min(): number {
    return getMinInterval(this.args.minInterval, this.units);
  }

  private emit(change: { refreshInterval: number; isPaused: boolean }): void {
    this.args.applyRefreshInterval?.(change);
    this.args.onRefreshChange?.({ ...change, intervalUnits: this.units });
  }

  apply(): void {
    if (this.value === '') return;

    const refreshInterval = Math.max(
      toMilliseconds(this.units, this.value),
      this.args.minInterval || 0
    );
    this.lastAppliedInterval = refreshInterval;

    this.emit({
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

    this.emit({
      refreshInterval: toMilliseconds(this.units, this.value),
      isPaused: false
    });
  }

  /** Upstream toggles even an invalid (≤ 0) interval; only an empty one is ignored. */
  @action
  toggle(): void {
    if (this.value === '') return;

    this.emit({
      refreshInterval: toMilliseconds(this.units, this.value),
      isPaused: !this.isPaused
    });
  }

  <template>
    {{! A fieldset without a title (upstream renders a plain panel); the
      switch label names the control. }}
    <EuiQuickSelectPanel
      @tagName="fieldset"
      class="euiRefreshInterval"
      {{didUpdate this.syncInterval @refreshInterval}}
      ...attributes
    >
      <EuiFlexGroup
        @alignItems="center"
        @gutterSize="s"
        @responsive={{false}}
        @wrap={{true}}
      >
        <EuiFlexItem @grow={{false}}>
          {{! The visible label's id is unused: the aria-label names the switch (upstream). }}
          <EuiSwitch
            @checked={{if this.isPaused false true}}
            @compressed={{true}}
            @label={{this.toggleLabel}}
            @onChange={{this.toggle}}
            aria-label={{this.t
              "euiRefreshInterval.toggleAriaLabel"
              "Toggle refresh"
            }}
            aria-labelledby={{undefined}}
            aria-describedby={{this.descriptionId}}
            data-test-subj="superDatePickerToggleRefreshButton"
          >
            <:label>
              <EuiFormLabel>{{this.toggleLabel}}</EuiFormLabel>
            </:label>
          </EuiSwitch>
        </EuiFlexItem>
        <EuiFlexItem style="min-width: 60px">
          <EuiFieldNumber
            @compressed={{true}}
            @fullWidth={{true}}
            @value={{this.value}}
            @isInvalid={{this.showInvalid}}
            @disabled={{this.isPaused}}
            @min={{this.min}}
            aria-label={{this.t
              "euiRefreshInterval.valueAriaLabel"
              "Refresh interval value"
            }}
            aria-describedby={{this.descriptionId}}
            data-test-subj="superDatePickerRefreshIntervalInput"
            {{on "input" this.onValueInput}}
            {{on "keydown" this.onKeyDown}}
          />
        </EuiFlexItem>
        <EuiFlexItem @grow={{2}} style="min-width: 100px">
          <EuiSelect
            @compressed={{true}}
            @fullWidth={{true}}
            @value={{this.units}}
            @options={{this.unitOptions}}
            @disabled={{this.isPaused}}
            aria-label={{this.t
              "euiRefreshInterval.unitsAriaLabel"
              "Refresh interval units"
            }}
            aria-describedby={{this.descriptionId}}
            data-test-subj="superDatePickerRefreshIntervalUnitsSelect"
            {{on "change" this.onUnitsChange}}
            {{on "keydown" this.onKeyDown}}
          />
        </EuiFlexItem>
      </EuiFlexGroup>
      <EuiScreenReaderOnly><p
          id={{this.descriptionId}}
        >{{this.description}}</p></EuiScreenReaderOnly>
    </EuiQuickSelectPanel>
  </template>
}
