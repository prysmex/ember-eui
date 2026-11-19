/**
 * The options of a `singleSelect` or `multiSelect` field in the field
 * editor (V03 6.4): a name and one of EuiBadge's named colours per option,
 * add, remove. Existing options keep their `value`; a new one gets its
 * label as its value (as `createOnPaste` does), made unique. Hidden when
 * the field's `options` is a function of the record.
 */
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';

import EuiBadge from '@ember-eui/core/components/eui-badge';
import EuiButtonEmpty from '@ember-eui/core/components/eui-button-empty';
import EuiButtonIcon from '@ember-eui/core/components/eui-button-icon';
import EuiFieldText from '@ember-eui/core/components/eui-field-text';
import EuiSelect from '@ember-eui/core/components/eui-select';

import type { SheetMessages, SheetOption } from '../../core/index.ts';
import type { SheetFieldOptionsSignature } from '../../types.ts';

/** EuiBadge's named colours, in the order the select lists them. */
export const OPTION_COLORS = [
  'default',
  'primary',
  'success',
  'accent',
  'warning',
  'danger',
  'hollow'
] as const;

interface Row {
  key: number;
  /** Absent for an option added here. */
  value?: SheetOption['value'];
  label: string;
  color?: string;
}

export default class SelectOptions extends Component<SheetFieldOptionsSignature> {
  id = guidFor(this);
  nextKey = 0;
  @tracked rows: Row[] = (Array.isArray(this.args.draft['options'])
    ? (this.args.draft['options'] as SheetOption[])
    : []
  ).map((option) => ({
    key: this.nextKey++,
    value: option.value,
    label: option.label,
    color: option.color
  }));

  get editable(): boolean {
    return typeof this.args.field?.['options'] !== 'function';
  }

  get messages(): SheetMessages {
    return this.args.messages;
  }

  get colorOptions(): Array<{ value: string; text: string }> {
    const messages = this.messages as unknown as Record<string, () => string>;
    return [
      { value: '', text: this.messages.colorNone() },
      ...OPTION_COLORS.map((color) => ({
        value: color,
        text: messages[`color_${color}`]?.() ?? color
      }))
    ];
  }

  labelOf = (index: number): string => this.messages.optionLabel(index + 1);

  badgeColor = (color: string | undefined): string => color || 'hollow';

  /** The rows as options: unnamed rows left out, new ones valued by their label. */
  emit(rows: Row[]): void {
    this.rows = rows;
    const taken = new Set(
      rows.filter((row) => row.value !== undefined).map((row) => row.value)
    );
    const options: SheetOption[] = [];
    for (const row of rows) {
      const label = row.label.trim();
      if (!label) continue;
      let value = row.value;
      if (value === undefined) {
        value = label;
        for (let n = 2; taken.has(value); n++) value = `${label} ${n}`;
        taken.add(value);
      }
      const option: SheetOption = { value, label };
      if (row.color) option.color = row.color;
      options.push(option);
    }
    this.args.onChange({ options });
  }

  change(key: number, patch: Partial<Row>): void {
    this.emit(
      this.rows.map((row) => (row.key === key ? { ...row, ...patch } : row))
    );
  }

  onLabel = (key: number, event: Event): void => {
    this.change(key, { label: (event.target as HTMLInputElement).value });
  };

  onColor = (key: number, event: Event): void => {
    const color = (event.target as HTMLSelectElement).value;
    this.change(key, { color: color || undefined });
  };

  remove = (key: number): void => {
    this.emit(this.rows.filter((row) => row.key !== key));
  };

  add = (): void => {
    const key = this.nextKey++;
    this.rows = [...this.rows, { key, label: '' }];
    // the new row's name input, once rendered
    requestAnimationFrame(() => {
      document
        .querySelector<HTMLInputElement>(`#${this.id}-label-${key}`)
        ?.focus();
    });
  };

  <template>
    {{#if this.editable}}
      <fieldset
        class="euiSheetFieldEditor__options"
        data-test-subj="euiSheetFieldOptions"
      >
        <legend class="euiSheetFieldEditor__legend">
          {{this.messages.fieldOptions}}
        </legend>
        {{! keyed: a keystroke must not re-create the row's input (focus) }}
        {{#each this.rows key="key" as |row index|}}
          <div
            class="euiSheetFieldEditor__option"
            data-test-subj="euiSheetFieldOption"
          >
            <EuiBadge
              @color={{this.badgeColor row.color}}
              class="euiSheetFieldEditor__swatch"
              aria-hidden="true"
            >&nbsp;</EuiBadge>
            <EuiFieldText
              @compressed={{true}}
              @value={{row.label}}
              id="{{this.id}}-label-{{row.key}}"
              aria-label={{this.labelOf index}}
              data-test-subj="euiSheetFieldOptionLabel"
              {{on "input" (fn this.onLabel row.key)}}
            />
            <EuiSelect
              @compressed={{true}}
              @options={{this.colorOptions}}
              @value={{if row.color row.color ""}}
              aria-label={{(this.messages.optionColor)}}
              data-test-subj="euiSheetFieldOptionColor"
              {{on "change" (fn this.onColor row.key)}}
            />
            <EuiButtonIcon
              @iconType="cross"
              @color="text"
              @size="s"
              aria-label={{(this.messages.removeOption)}}
              title={{(this.messages.removeOption)}}
              data-test-subj="euiSheetFieldOptionRemove"
              {{on "click" (fn this.remove row.key)}}
            />
          </div>
        {{/each}}
        <EuiButtonEmpty
          @iconType="plus"
          @size="xs"
          @flush="left"
          data-test-subj="euiSheetFieldOptionAdd"
          {{on "click" this.add}}
        >{{this.messages.addOption}}</EuiButtonEmpty>
      </fieldset>
    {{/if}}
  </template>
}
