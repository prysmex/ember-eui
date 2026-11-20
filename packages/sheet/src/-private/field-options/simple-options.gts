/**
 * The small option forms of the built-in types in the field editor (V03
 * 6.4): a currency's code and decimals, a percent's decimals, a rating's
 * stars, a date's day/month order, a duration's format, a date and
 * time's zone, clock and seconds (V03 10.3).
 */
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';

import EuiFieldNumber from '@ember-eui/core/components/eui-field-number';
import EuiFieldText from '@ember-eui/core/components/eui-field-text';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import EuiSelect from '@ember-eui/core/components/eui-select';
import EuiSwitch from '@ember-eui/core/components/eui-switch';

import type { SheetFieldOptionsSignature } from '../../types.ts';

/** A whole number from an input, clamped; `undefined` when empty. */
function wholeNumber(
  event: Event,
  min: number,
  max: number
): number | undefined {
  const text = (event.target as HTMLInputElement).value.trim();
  if (text === '') return undefined;
  const value = Math.round(Number(text));
  if (!Number.isFinite(value)) return undefined;
  return Math.min(Math.max(value, min), max);
}

class OptionsBase extends Component<SheetFieldOptionsSignature> {
  id = guidFor(this);

  get messages() {
    return this.args.messages;
  }

  option(name: string): unknown {
    return this.args.draft[name];
  }
}

/** Decimals of a currency or a percent (0 to 6). */
class PrecisionRow extends OptionsBase {
  get precision(): number | undefined {
    return this.option('precision') as number | undefined;
  }

  onPrecision = (event: Event): void => {
    this.args.onChange({ precision: wholeNumber(event, 0, 6) });
  };

  <template>
    <EuiFormRow
      @label={{(this.messages.fieldPrecision)}}
      @id="{{this.id}}-precision"
      @display="rowCompressed"
    >
      <EuiFieldNumber
        @compressed={{true}}
        @value={{this.precision}}
        @min={{0}}
        @max={{6}}
        id="{{this.id}}-precision"
        data-test-subj="euiSheetFieldPrecision"
        {{on "change" this.onPrecision}}
      />
    </EuiFormRow>
  </template>
}

export class CurrencyOptions extends OptionsBase {
  get code(): string {
    return (this.option('currency') as string | undefined) ?? '';
  }

  onCode = (event: Event): void => {
    const input = event.target as HTMLInputElement;
    const code = input.value
      .replace(/[^a-z]/gi, '')
      .toUpperCase()
      .slice(0, 3);
    if (code !== input.value) input.value = code;
    this.args.onChange({ currency: code });
  };

  <template>
    <div
      class="euiSheetFieldEditor__optionRow"
      data-test-subj="euiSheetFieldOptions"
    >
      <EuiFormRow
        @label={{(this.messages.fieldCurrency)}}
        @id="{{this.id}}-currency"
        @display="rowCompressed"
      >
        <EuiFieldText
          @compressed={{true}}
          @value={{this.code}}
          id="{{this.id}}-currency"
          maxlength="3"
          placeholder="USD"
          data-test-subj="euiSheetFieldCurrency"
          {{on "input" this.onCode}}
        />
      </EuiFormRow>
      <PrecisionRow
        @draft={{@draft}}
        @field={{@field}}
        @onChange={{@onChange}}
        @messages={{@messages}}
      />
    </div>
  </template>
}

export class PercentOptions extends OptionsBase {
  <template>
    <div
      class="euiSheetFieldEditor__optionRow"
      data-test-subj="euiSheetFieldOptions"
    >
      <PrecisionRow
        @draft={{@draft}}
        @field={{@field}}
        @onChange={{@onChange}}
        @messages={{@messages}}
      />
    </div>
  </template>
}

export class RatingOptions extends OptionsBase {
  get max(): number {
    return (this.option('max') as number | undefined) ?? 5;
  }

  onMax = (event: Event): void => {
    this.args.onChange({ max: wholeNumber(event, 1, 10) });
  };

  <template>
    <div
      class="euiSheetFieldEditor__optionRow"
      data-test-subj="euiSheetFieldOptions"
    >
      <EuiFormRow
        @label={{(this.messages.fieldRatingMax)}}
        @id="{{this.id}}-max"
        @display="rowCompressed"
      >
        <EuiFieldNumber
          @compressed={{true}}
          @value={{this.max}}
          @min={{1}}
          @max={{10}}
          id="{{this.id}}-max"
          data-test-subj="euiSheetFieldRatingMax"
          {{on "change" this.onMax}}
        />
      </EuiFormRow>
    </div>
  </template>
}

export class DateOptions extends OptionsBase {
  get order(): string {
    return (this.option('dateOrder') as string | undefined) ?? 'dmy';
  }

  get orders(): Array<{ value: string; text: string }> {
    return [
      { value: 'dmy', text: this.messages.dateOrderDmy() },
      { value: 'mdy', text: this.messages.dateOrderMdy() }
    ];
  }

  onOrder = (event: Event): void => {
    this.args.onChange({
      dateOrder: (event.target as HTMLSelectElement).value
    });
  };

  <template>
    <div
      class="euiSheetFieldEditor__optionRow"
      data-test-subj="euiSheetFieldOptions"
    >
      <EuiFormRow
        @label={{(this.messages.fieldDateOrder)}}
        @id="{{this.id}}-order"
        @display="rowCompressed"
      >
        <EuiSelect
          @compressed={{true}}
          @options={{this.orders}}
          @value={{this.order}}
          id="{{this.id}}-order"
          data-test-subj="euiSheetFieldDateOrder"
          {{on "change" this.onOrder}}
        />
      </EuiFormRow>
    </div>
  </template>
}

const DURATION_FORMATS = [
  { value: 'h:mm', text: 'h:mm' },
  { value: 'h:mm:ss', text: 'h:mm:ss' }
];

export class DurationOptions extends OptionsBase {
  formats = DURATION_FORMATS;

  get format(): string {
    return (this.option('durationFormat') as string | undefined) ?? 'h:mm';
  }

  onFormat = (event: Event): void => {
    this.args.onChange({
      durationFormat: (event.target as HTMLSelectElement).value
    });
  };

  <template>
    <div
      class="euiSheetFieldEditor__optionRow"
      data-test-subj="euiSheetFieldOptions"
    >
      <EuiFormRow
        @label={{(this.messages.fieldDurationFormat)}}
        @id="{{this.id}}-format"
        @display="rowCompressed"
      >
        <EuiSelect
          @compressed={{true}}
          @options={{this.formats}}
          @value={{this.format}}
          id="{{this.id}}-format"
          data-test-subj="euiSheetFieldDurationFormat"
          {{on "change" this.onFormat}}
        />
      </EuiFormRow>
    </div>
  </template>
}

/** A date and time (V03 10.3): its zone, day/month order, clock and seconds. */
export class DateTimeOptions extends DateOptions {
  get zone(): string {
    return (this.option('timeZone') as string | undefined) ?? '';
  }

  get clock(): string {
    return this.option('hour12') ? '12' : '24';
  }

  get clocks(): Array<{ value: string; text: string }> {
    return [
      { value: '24', text: this.messages.clock24() },
      { value: '12', text: this.messages.clock12() }
    ];
  }

  get seconds(): boolean {
    return !!this.option('seconds');
  }

  onZone = (event: Event): void => {
    const zone = (event.target as HTMLInputElement).value.trim();
    this.args.onChange({ timeZone: zone === '' ? undefined : zone });
  };

  onClock = (event: Event): void => {
    this.args.onChange({
      hour12: (event.target as HTMLSelectElement).value === '12'
    });
  };

  onSeconds = (): void => {
    this.args.onChange({ seconds: !this.seconds });
  };

  <template>
    <div
      class="euiSheetFieldEditor__optionRow"
      data-test-subj="euiSheetFieldOptions"
    >
      <EuiFormRow
        @label={{(this.messages.fieldTimeZone)}}
        @helpText={{(this.messages.fieldTimeZoneHelp)}}
        @id="{{this.id}}-zone"
        @display="rowCompressed"
      >
        <EuiFieldText
          @compressed={{true}}
          @value={{this.zone}}
          placeholder="local"
          id="{{this.id}}-zone"
          data-test-subj="euiSheetFieldTimeZone"
          {{on "change" this.onZone}}
        />
      </EuiFormRow>
      <EuiFormRow
        @label={{(this.messages.fieldDateOrder)}}
        @id="{{this.id}}-order"
        @display="rowCompressed"
      >
        <EuiSelect
          @compressed={{true}}
          @options={{this.orders}}
          @value={{this.order}}
          id="{{this.id}}-order"
          data-test-subj="euiSheetFieldDateOrder"
          {{on "change" this.onOrder}}
        />
      </EuiFormRow>
      <EuiFormRow
        @label={{(this.messages.fieldClock)}}
        @id="{{this.id}}-clock"
        @display="rowCompressed"
      >
        <EuiSelect
          @compressed={{true}}
          @options={{this.clocks}}
          @value={{this.clock}}
          id="{{this.id}}-clock"
          data-test-subj="euiSheetFieldClock"
          {{on "change" this.onClock}}
        />
      </EuiFormRow>
      <EuiSwitch
        @compressed={{true}}
        @label={{(this.messages.fieldSeconds)}}
        @checked={{this.seconds}}
        @onChange={{this.onSeconds}}
        data-test-subj="euiSheetFieldSeconds"
      />
    </div>
  </template>
}
