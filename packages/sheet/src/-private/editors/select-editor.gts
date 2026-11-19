/**
 * The single-select editor (PACKAGE-DESIGN.md 8.2, P5): a searchable
 * EuiSelectable in a panel beside the cell, inside the sheet's wrapper (not
 * EuiComboBox, whose list is in a wormhole). Focus stays in the search
 * field; the list is driven from it. The type claims Enter, ArrowUp,
 * ArrowDown and Tab (`handlesKey`).
 */
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import EuiPanel from '@ember-eui/core/components/eui-panel';
import EuiSelectable from '@ember-eui/core/components/eui-selectable';

import { fieldOptions } from '../../core/index.ts';

import type { SheetEditorSignature } from '../../types.ts';
import type { EuiSelectableOption } from '@ember-eui/core/components/eui-selectable';

type Option = EuiSelectableOption & { data?: { value: unknown } };

export default class SelectEditor extends Component<
  SheetEditorSignature<any, any>
> {
  /** EuiSelectable's current option (through @onActiveOptionChange). */
  active: Option | null = null;
  /** The options matching the search, and the search (through searchProps.onChange). */
  matching: Option[] = [];
  searchValue = this.args.initialKey ?? '';

  get label(): string {
    return this.args.field.label ?? this.args.field.id;
  }

  @cached
  get options(): Option[] {
    return fieldOptions(this.args.field, this.args.record).map((option) => ({
      label: option.label,
      key: String(option.value),
      checked: option.value === this.args.value ? 'on' : undefined,
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

  /**
   * The option Enter and Tab save: the current one, else the first match of
   * a typed search. EuiSelectable makes no option current when it opens
   * with a seeded search and the field focused (V5, PACKAGE-RESULTS.md).
   */
  get target(): Option | null {
    if (this.active) return this.active;
    if (this.searchValue.trim() === '') return null;
    return this.matching.find((option) => !option.disabled) ?? null;
  }

  onChange = (
    _options: EuiSelectableOption[],
    event: Event | undefined,
    changed: EuiSelectableOption
  ): void => {
    this.args.onCommit(
      { value: (changed as Option).data?.value },
      { move: event instanceof KeyboardEvent ? [1, 0] : [0, 0] }
    );
  };

  setActive = (option: EuiSelectableOption | null): void => {
    this.active = option as Option | null;
  };

  // capture, on the editor's root: runs before EuiSelectable's bubble
  // handler, whose default branch would reset the current option
  onKeyDown = (event: KeyboardEvent): void => {
    if (event.key === 'Tab') {
      event.preventDefault();
      event.stopPropagation();
      const target = this.target;
      this.args.onCommit(target ? { value: target.data?.value } : undefined, {
        move: [0, event.shiftKey ? -1 : 1]
      });
      return;
    }
    if (event.key === 'Enter' && !this.active) {
      const target = this.target;
      if (!target) return;
      event.preventDefault();
      event.stopPropagation();
      this.args.onCommit({ value: target.data?.value }, { move: [1, 0] });
    }
  };

  /** A press on an option keeps focus in the search field, so no focusout closes the editor before the click picks. */
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
          @singleSelection="always"
          @searchable={{true}}
          @searchProps={{this.searchProps}}
          @onChange={{this.onChange}}
          @onActiveOptionChange={{this.setActive}}
        />
      </EuiPanel>
    </div>
  </template>
}
