/**
 * The linked-record and user editor: a searchable EuiSelectable in a panel,
 * its options from `field.search(query, { record, signal })` (pre-filtered,
 * with a loading and an error state, as demo d04) or from a user field's
 * `options`; the chosen ones first. With `multiple` (linkedRecord's
 * default) a pick toggles and the editor stays open until Tab or focus
 * leaving saves; otherwise a pick saves. With `search`, a typed search left
 * without a pick is reported as text, so focus leaving resolves it
 * (`@onResolve`); a local list's typed search saves nothing.
 */
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { buildWaiter } from '@ember/test-waiters';

import EuiPanel from '@ember-eui/core/components/eui-panel';
import EuiSelectable from '@ember-eui/core/components/eui-selectable';

import type { SheetEditorSignature } from '../../types.ts';
import type { EuiSelectableOption } from '@ember-eui/core/components/eui-selectable';

interface Item {
  id: string | number;
  label: string;
}
type Option = EuiSelectableOption & { data?: { value: Item } };
type Search = (
  query: string,
  context: { record: unknown; signal: AbortSignal }
) => Promise<Item[]>;

const searchWaiter = buildWaiter('@ember-eui/sheet:record-search');

function itemsOf(value: unknown): Item[] {
  if (Array.isArray(value)) return value as Item[];
  return value && typeof value === 'object' ? [value as Item] : [];
}

export default class RecordPickerEditor extends Component<
  SheetEditorSignature<any, any>
> {
  @tracked chosen: Item[] = [...itemsOf(this.args.value)];
  @tracked results: Item[] = [];
  @tracked isLoading = false;
  @tracked error: string | null = null;
  toggled = false;
  active: Option | null = null;
  matching: Option[] = [];
  searchValue = this.args.initialKey ?? '';
  controller: AbortController | null = null;
  waiterToken: unknown = null;

  get label(): string {
    return this.args.field.label ?? this.args.field.id;
  }

  /** linkedRecord: several by default; user: one by default. */
  get multiple(): boolean {
    const multiple = this.args.field['multiple'] as boolean | undefined;
    return this.args.field.type === 'linkedRecord'
      ? multiple !== false
      : multiple === true;
  }

  /** A user field's own list: filtered by EuiSelectable, no search call. */
  get localOptions(): Item[] | null {
    const options = this.args.field['options'];
    return Array.isArray(options) ? (options as Item[]) : null;
  }

  get search(): Search | undefined {
    return this.args.field['search'] as Search | undefined;
  }

  get messages() {
    return this.args.messages;
  }

  /** The value to save for these items: an array, or one item (or null) without `multiple` on a user field. */
  valueFor(items: Item[]): unknown {
    if (this.args.field.type === 'user' && !this.multiple) {
      return items[0] ?? null;
    }
    return this.multiple ? items : items.slice(0, 1);
  }

  isChosen(item: Item): boolean {
    return this.chosen.some((c) => String(c.id) === String(item.id));
  }

  @cached
  get options(): Option[] {
    const source = this.localOptions ?? this.results;
    const rest = source.filter((item) => !this.isChosen(item));
    // the chosen ones first (only those that match, for a local list)
    const chosen =
      this.localOptions && this.searchValue.trim()
        ? this.chosen.filter((item) =>
            item.label
              .toLowerCase()
              .includes(this.searchValue.trim().toLowerCase())
          )
        : this.chosen;
    return [...chosen, ...rest].map((item) => ({
      label: item.label,
      key: String(item.id),
      checked: this.isChosen(item) ? 'on' : undefined,
      data: { value: item }
    }));
  }

  searchProps = {
    compressed: true,
    defaultValue: this.args.initialKey ?? '',
    inputRef: (input: HTMLInputElement) => input.focus(),
    // also called once after the first render
    onChange: (searchValue: string, matching: EuiSelectableOption[]) => {
      this.searchValue = searchValue;
      this.matching = matching as Option[];
      this.reportDraft();
      if (!this.localOptions) void this.runSearch(searchValue);
    },
    'data-test-subj': 'euiSheetSelectSearch'
  };

  /** A typed search was reported as the draft text. */
  reportedText = false;

  /**
   * What focus leaving saves: the toggled items; else, for a field that
   * searches (`search`, not a local list), a typed search, which the sheet
   * resolves (`@onResolve`); else nothing. A search typed and then cleared
   * reports the value as it was, so nothing changes.
   */
  reportDraft(): void {
    if (this.toggled) {
      this.args.onDraftValue?.(this.valueFor(this.chosen));
    } else if (!this.localOptions && this.searchValue.trim() !== '') {
      this.reportedText = true;
      this.args.onDraftChange(this.searchValue);
    } else if (this.reportedText) {
      this.reportedText = false;
      this.args.onDraftValue?.(this.args.value);
    }
  }

  async runSearch(query: string): Promise<void> {
    const search = this.search;
    if (!search) return;
    this.controller?.abort();
    const controller = new AbortController();
    this.controller = controller;
    this.isLoading = true;
    this.error = null;
    if (this.waiterToken === null) this.waiterToken = searchWaiter.beginAsync();
    try {
      const items = await search(query, {
        record: this.args.record,
        signal: controller.signal
      });
      if (controller.signal.aborted || this.isDestroying) return;
      this.results = items;
    } catch {
      if (controller.signal.aborted || this.isDestroying) return;
      this.error = this.messages.searchFailed();
    } finally {
      if (this.controller === controller) {
        if (!this.isDestroying && !this.isDestroyed) this.isLoading = false;
        this.endWaiter();
      }
    }
  }

  endWaiter(): void {
    if (this.waiterToken !== null) {
      searchWaiter.endAsync(this.waiterToken);
      this.waiterToken = null;
    }
  }

  willDestroy(): void {
    super.willDestroy();
    this.controller?.abort();
    this.endWaiter();
  }

  pick(item: Item, event: Event | undefined): void {
    if (!this.multiple) {
      this.args.onCommit(
        { value: this.valueFor([item]) },
        { move: event instanceof KeyboardEvent ? [1, 0] : [0, 0] }
      );
      return;
    }
    // a new array each time: values are never mutated
    this.chosen = this.isChosen(item)
      ? this.chosen.filter((c) => String(c.id) !== String(item.id))
      : [...this.chosen, item];
    this.toggled = true;
    this.reportDraft();
  }

  onChange = (
    _options: EuiSelectableOption[],
    event: Event | undefined,
    changed: EuiSelectableOption
  ): void => {
    const item = (changed as Option).data?.value;
    if (item) this.pick(item, event);
  };

  setActive = (option: EuiSelectableOption | null): void => {
    this.active = option as Option | null;
  };

  get target(): Option | null {
    if (this.active) return this.active;
    if (this.searchValue.trim() === '' || this.isLoading) return null;
    return this.matching.find((option) => !option.disabled) ?? null;
  }

  /** Capture: before EuiSelectable's own handler (see `SelectEditor`). */
  onKeyDown = (event: KeyboardEvent): void => {
    if (event.key === 'Tab') {
      event.preventDefault();
      event.stopPropagation();
      const move: [number, number] = [0, event.shiftKey ? -1 : 1];
      if (this.multiple) {
        this.args.onCommit(
          this.toggled ? { value: this.valueFor(this.chosen) } : undefined,
          { move }
        );
        return;
      }
      const target = this.target?.data?.value;
      this.args.onCommit(
        target ? { value: this.valueFor([target]) } : undefined,
        { move }
      );
      return;
    }
    if (event.key === 'Enter' && !this.active) {
      const target = this.target?.data?.value;
      if (!target) return;
      event.preventDefault();
      event.stopPropagation();
      this.pick(target, event);
    }
  };

  keepFocus = (event: MouseEvent): void => {
    if (!(event.target instanceof HTMLInputElement)) event.preventDefault();
  };

  get loadingMessage(): string {
    return this.messages.loading();
  }

  get noMatches(): string {
    return this.messages.noMatches();
  }

  get singleSelection(): boolean {
    return !this.multiple;
  }

  get isPreFiltered(): boolean {
    return !this.localOptions;
  }

  <template>
    <div
      {{on "keydown" this.onKeyDown capture=true}}
      {{on "mousedown" this.keepFocus}}
    >
      <EuiPanel @paddingSize="s" @hasShadow={{true}}>
        <EuiSelectable
          aria-label={{this.label}}
          @options={{this.options}}
          @singleSelection={{this.singleSelection}}
          @searchable={{true}}
          @isPreFiltered={{this.isPreFiltered}}
          @isLoading={{this.isLoading}}
          @errorMessage={{this.error}}
          @loadingMessage={{this.loadingMessage}}
          @noMatchesMessage={{this.noMatches}}
          @emptyMessage={{this.noMatches}}
          @searchProps={{this.searchProps}}
          @onChange={{this.onChange}}
          @onActiveOptionChange={{this.setActive}}
        />
      </EuiPanel>
    </div>
  </template>
}
