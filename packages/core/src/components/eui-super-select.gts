import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import { randomId } from '../-private/random-id.ts';
import EuiContextMenuItem from './eui-context-menu-item.gts';
import EuiInputPopover from './eui-input-popover.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';
import EuiSuperSelectControl from './eui-super-select-control.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiContextMenuItemSignature } from './eui-context-menu-item';
import type { EuiSuperSelectOption } from './eui-super-select-control';

export type { EuiSuperSelectOption };

/**
 * A select whose options can show more than text: a title with a
 * description, an icon, a color. Pick it over `EuiSelect` when options
 * need that; for plain text options `EuiSelect` is simpler and native.
 */
export interface EuiSuperSelectSignature {
  Element: HTMLButtonElement;
  Args: {
    /**
     * The options: `{ value, inputDisplay, dropdownDisplay, disabled }`.
     * Use the `<:inputDisplay>` / `<:dropdownDisplay>` blocks for markup.
     */
    options: EuiSuperSelectOption<any>[];
    /** Value of the selected option. */
    valueOfSelected?: unknown;
    /** Called with the chosen option's value. */
    onChange?: (value: any) => void;
    /** Opens the list (e.g. on first render). */
    isOpen?: boolean;
    /** Invalid look. */
    isInvalid?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
    /** Lines between the options, for options with several lines. */
    hasDividers?: boolean;
    /** Takes the container's full width. */
    fullWidth?: boolean;
    /** Smaller, for dense forms. */
    compressed?: boolean;
    /** Aligns the check mark with the `'center'` or the `'top'` of each option. */
    itemLayoutAlign?: EuiContextMenuItemSignature['Args']['layoutAlign'];
    /** `name` of the hidden input, for forms. */
    name?: string;
    /** `id` of the hidden input. */
    id?: string;
    /** Called when the list opens. */
    onFocus?: () => void;
    /** Called when the list closes. */
    onBlur?: () => void;
  };
  Blocks: {
    /** Renders the selected option in the control; yields it. */
    inputDisplay: [option: EuiSuperSelectOption<any>];
    /** Renders an option in the list; yields it. */
    dropdownDisplay: [option: EuiSuperSelectOption<any>];
    /** Content before the control; yields the class to put on it. */
    prepend: [className: string];
    /** Content after the control; yields the class to put on it. */
    append: [className: string];
  };
}

export default class EuiSuperSelect extends Component<EuiSuperSelectSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isPopoverOpen = false;

  labelledById = `euiSuperSelect_${randomId()}_screenreaderLabelId`;
  describedById = `euiSuperSelect_${randomId()}_screenreaderDescribeId`;

  itemNodes: HTMLElement[] = [];

  get isOpen(): boolean {
    return Boolean(this.args.isOpen) || this.isPopoverOpen;
  }

  get announcement(): string {
    return this.euiI18n.lookupToken(
      'euiSuperSelect.screenReaderAnnouncement',
      'You are in a form selector and must select a single option. Use the up and down keys to navigate or escape to close.'
    );
  }

  get itemClasses(): string {
    return this.args.hasDividers
      ? 'euiSuperSelect__item euiSuperSelect__item--hasDividers'
      : 'euiSuperSelect__item';
  }

  isSelected = (option: EuiSuperSelectOption<unknown>): boolean =>
    option.value === this.args.valueOfSelected;

  optionId = (index: number): string => `${this.labelledById}_option-${index}`;

  get activeDescendant(): string | undefined {
    const index = this.args.options.findIndex(this.isSelected);

    return index === -1 ? undefined : this.optionId(index);
  }

  /**
   * What the popover focuses once it is positioned: the selected option,
   * or the first enabled one.
   */
  initialFocus = (): HTMLElement | null => {
    const selected = this.args.options.findIndex(this.isSelected);
    const index =
      selected !== -1 ? selected : this.args.options.findIndex((option) => !option.disabled);

    return index === -1 ? null : document.getElementById(this.optionId(index));
  };

  @action
  openPopover(): void {
    this.isPopoverOpen = true;
    this.args.onFocus?.();
  }

  @action
  closePopover(): void {
    this.isPopoverOpen = false;
    this.args.onBlur?.();
  }

  @action
  toggle(): void {
    if (this.isPopoverOpen) this.closePopover();
    else this.openPopover();
  }

  @action
  itemClicked(value: unknown): void {
    this.closePopover();
    this.args.onChange?.(value);
  }

  @action
  onSelectKeyDown(event: KeyboardEvent): void {
    if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
      event.preventDefault();
      event.stopPropagation();
      this.openPopover();
    }
  }

  @action
  onItemKeyDown(event: KeyboardEvent): void {
    switch (event.key) {
      case 'Escape':
        event.preventDefault();
        event.stopPropagation();
        this.closePopover();
        break;
      case 'Tab':
        event.preventDefault();
        event.stopPropagation();
        break;
      case 'ArrowUp':
      case 'ArrowDown': {
        event.preventDefault();
        event.stopPropagation();

        const items = this.itemNodes.filter((node) => node.isConnected);
        const current = items.indexOf(document.activeElement as HTMLElement);
        const step = event.key === 'ArrowUp' ? -1 : 1;
        const next = current === -1 ? 0 : (current + step + items.length) % items.length;

        items[next]?.focus();
        break;
      }
    }
  }

  registerItem = modifier((element: HTMLElement, [index]: [number]) => {
    this.itemNodes[index] = element;
  });

  <template>
    <EuiInputPopover
      class="euiSuperSelect"
      @isOpen={{this.isOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize="none"
      @fullWidth={{@fullWidth}}
      @disableFocusTrap={{true}}
      @initialFocus={{this.initialFocus}}
    >
      <:input>
        <EuiSuperSelectControl
          class={{if this.isPopoverOpen "euiSuperSelect--isOpen__button"}}
          @options={{@options}}
          @value={{@valueOfSelected}}
          @id={{@id}}
          @name={{@name}}
          @fullWidth={{@fullWidth}}
          @compressed={{@compressed}}
          @isLoading={{@isLoading}}
          @isInvalid={{@isInvalid}}
          @screenReaderId={{this.labelledById}}
          {{on "click" this.toggle}}
          {{on "keydown" this.onSelectKeyDown}}
          ...attributes
        >
          <:inputDisplay as |option|>
            {{#if (has-block "inputDisplay")}}
              {{yield option to="inputDisplay"}}
            {{else}}
              {{option.inputDisplay}}
            {{/if}}
          </:inputDisplay>
        </EuiSuperSelectControl>
      </:input>
      <:content>
        <EuiScreenReaderOnly>
          <p id={{this.describedById}}>{{this.announcement}}</p>
        </EuiScreenReaderOnly>
        <div
          class="euiSuperSelect__listbox"
          role="listbox"
          aria-labelledby={{this.labelledById}}
          aria-describedby={{this.describedById}}
          aria-activedescendant={{this.activeDescendant}}
          tabindex="0"
        >
          {{#each @options as |option index|}}
            <EuiContextMenuItem
              class={{this.itemClasses}}
              id={{this.optionId index}}
              role="option"
              aria-selected={{if (this.isSelected option) "true" "false"}}
              @icon={{if (this.isSelected option) "check" "empty"}}
              @layoutAlign={{@itemLayoutAlign}}
              @disabled={{option.disabled}}
              {{on "click" (fn this.itemClicked option.value)}}
              {{on "keydown" this.onItemKeyDown}}
              {{this.registerItem index}}
            >
              {{#if (has-block "dropdownDisplay")}}
                {{yield option to="dropdownDisplay"}}
              {{else if option.dropdownDisplay}}
                {{option.dropdownDisplay}}
              {{else}}
                {{option.inputDisplay}}
              {{/if}}
            </EuiContextMenuItem>
          {{/each}}
        </div>
      </:content>
    </EuiInputPopover>
  </template>
}
