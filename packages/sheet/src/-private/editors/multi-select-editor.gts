/**
 * The multi-select editor: a searchable EuiSelectable in multi-selection
 * mode in a panel beside the cell (as `SelectEditor`). Clicking an option
 * or Enter toggles it and the editor stays open; Tab, or focus leaving,
 * saves the chosen options (`onDraftValue`); Escape cancels. The type
 * claims Enter, ArrowUp, ArrowDown and Tab (`handlesKey`).
 */
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import EuiPanel from '@ember-eui/core/components/eui-panel';
import EuiSelectable from '@ember-eui/core/components/eui-selectable';

import { fieldOptions } from '../../core/index.ts';

import type { SheetEditorSignature } from '../../types.ts';
import type { EuiSelectableOption } from '@ember-eui/core/components/eui-selectable';

type Value = string | number;
type Option = EuiSelectableOption & { data?: { value: Value } };

export default class MultiSelectEditor extends Component<
  SheetEditorSignature<any, any>
> {
  /** The chosen values, in the order they were chosen. */
  @tracked chosen: Value[] = Array.isArray(this.args.value)
    ? [...(this.args.value as Value[])]
    : [];
  toggled = false;
  active: Option | null = null;
  matching: Option[] = [];
  searchValue = this.args.initialKey ?? '';

  get label(): string {
    return this.args.field.label ?? this.args.field.id;
  }

  get noMatches(): string {
    return this.args.messages.noMatches();
  }

  @cached
  get options(): Option[] {
    return fieldOptions(this.args.field, this.args.record).map((option) => ({
      label: option.label,
      key: String(option.value),
      checked: this.chosen.includes(option.value) ? 'on' : undefined,
      data: { value: option.value }
    }));
  }

  searchProps = {
    compressed: true,
    defaultValue: this.args.initialKey ?? '',
    inputRef: (input: HTMLInputElement) => input.focus(),
    onChange: (searchValue: string, matching: EuiSelectableOption[]) => {
      this.searchValue = searchValue;
      this.matching = matching as Option[];
    },
    'data-test-subj': 'euiSheetSelectSearch'
  };

  /** A new array each time: values are never mutated. */
  toggle(value: Value): void {
    this.chosen = this.chosen.includes(value)
      ? this.chosen.filter((v) => v !== value)
      : [...this.chosen, value];
    this.toggled = true;
    this.args.onDraftValue?.(this.chosen);
  }

  /** The option Enter toggles without a current one: the first match of a typed search (V5). */
  get target(): Option | null {
    if (this.active) return this.active;
    if (this.searchValue.trim() === '') return null;
    return this.matching.find((option) => !option.disabled) ?? null;
  }

  onChange = (
    _options: EuiSelectableOption[],
    _event: Event | undefined,
    changed: EuiSelectableOption
  ): void => {
    const value = (changed as Option).data?.value;
    if (value !== undefined) this.toggle(value);
  };

  setActive = (option: EuiSelectableOption | null): void => {
    this.active = option as Option | null;
  };

  /** Capture: before EuiSelectable's own handler (see `SelectEditor`). */
  onKeyDown = (event: KeyboardEvent): void => {
    if (event.key === 'Tab') {
      event.preventDefault();
      event.stopPropagation();
      this.args.onCommit(this.toggled ? { value: this.chosen } : undefined, {
        move: [0, event.shiftKey ? -1 : 1]
      });
      return;
    }
    if (event.key === 'Enter' && !this.active) {
      const target = this.target;
      if (!target) return;
      event.preventDefault();
      event.stopPropagation();
      const value = target.data?.value;
      if (value !== undefined) this.toggle(value);
    }
  };

  keepFocus = (event: MouseEvent): void => {
    if (!(event.target instanceof HTMLInputElement)) event.preventDefault();
  };

  <template>
    <div
      {{on "keydown" this.onKeyDown capture=true}}
      {{on "mousedown" this.keepFocus}}
    >
      <EuiPanel @paddingSize="s" @hasShadow={{true}}>
        <EuiSelectable
          aria-label={{this.label}}
          @options={{this.options}}
          @searchable={{true}}
          @searchProps={{this.searchProps}}
          @noMatchesMessage={{this.noMatches}}
          @onChange={{this.onChange}}
          @onActiveOptionChange={{this.setActive}}
        />
      </EuiPanel>
    </div>
  </template>
}
