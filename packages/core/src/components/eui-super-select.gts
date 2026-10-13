import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import argOrDefault from '../helpers/arg-or-default.ts';
import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiListItemLayoutStyles,
  euiScrollBarStyles,
  euiSuperSelectStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiIcon from './eui-icon.gts';
import EuiInputPopover from './eui-input-popover.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';
import EuiSuperSelectControl from './eui-super-select-control.gts';

import type { EuiInputPopoverArgs } from './eui-input-popover';
import type EuiI18n from '../services/eui-i18n';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';
import type { EuiSuperSelectOption } from './eui-super-select-control';

export type { EuiSuperSelectOption };

/** Scoped button reset for the options (no React global reset). */
const ITEM_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  border: 'none',
  background: 'none',
  font: 'inherit',
  textAlign: 'start'
} as const;

/**
 * `@itemLayoutAlign` (Ember extension; upstream removed it): where the
 * check mark sits relative to multi-line options.
 */
const LAYOUT_ALIGN = {
  center: undefined,
  top: { alignItems: 'flex-start' },
  bottom: { alignItems: 'flex-end' }
} as const;

/** Upstream's `eui-scrollBar` utility class (`euiScrollBarStyles` defaults). */
const listboxScrollBar = (context: EuiBorealisContext): string =>
  (euiScrollBarStyles as (c: EuiBorealisContext) => string)(context);

/** `@hasDividers` (Ember extension; upstream removed it). */
const dividerStyles = (context: EuiBorealisContext) =>
  `&:not(:last-child){border-block-end:${context.euiTheme.border.thin};};label:hasDividers;`;

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
    /** Shown in the control while no option is selected. */
    placeholder?: string;
    /** Called with the chosen option's value. */
    onChange?: (value: any) => void;
    /** Opens the list (e.g. on first render). */
    isOpen?: boolean;
    /** Invalid look and the warning icon. */
    isInvalid?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
    /** Disables the control. */
    disabled?: boolean;
    /** Read-only: shows the value, the list cannot be opened. */
    readOnly?: boolean;
    /**
     * Lines between the options, for options with several lines. Ember
     * extension: latest EUI removed it.
     */
    hasDividers?: boolean;
    /** Takes the container's full width. */
    fullWidth?: boolean;
    /** Smaller, for dense forms. */
    compressed?: boolean;
    /**
     * @deprecated Removed upstream. Aligns the check mark with the
     * `'center'` (default), the `'top'` or the `'bottom'` of each option.
     */
    itemLayoutAlign?: 'center' | 'top' | 'bottom';
    /** Extra classes for each option. */
    itemClassName?: string;
    /** `name` of the hidden input, for forms. */
    name?: string;
    /**
     * `id` of the hidden input. Pass the same `@id` to the `EuiFormRow`
     * so its label also labels the control.
     */
    id?: string;
    /**
     * Props of the underlying `EuiInputPopover` (upstream `popoverProps`),
     * e.g. `repositionOnScroll` inside scrollable containers, `panelStyle`
     * or `panelClassName`. `isOpen` is not accepted (use the top level
     * `@isOpen`); `fullWidth` and `disableFocusTrap` are managed by the
     * select. Its `className` is added to `euiSuperSelect`.
     */
    popoverProps?: Partial<Omit<EuiInputPopoverArgs, 'isOpen'>> & {
      className?: string;
    };
    /** @private Whether the `<:prepend>` block has content. Defaults to `has-block`; for wrappers that always forward the blocks. */
    isPrependProvided?: boolean;
    /** @private Whether the `<:append>` block has content. Defaults to `has-block`. */
    isAppendProvided?: boolean;
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
  /** Upstream `currentIndex`: the option highlighted and focused. */
  @tracked currentIndex = -1;

  idPrefix = `euiSuperSelect_${randomId()}`;
  describedById = `${this.idPrefix}_screenreaderDescribeId`;

  itemNodes: (HTMLButtonElement | undefined)[] = [];
  controlButton: HTMLButtonElement | null = null;

  get isOpen(): boolean {
    return Boolean(this.args.isOpen) || this.isPopoverOpen;
  }

  get announcement(): string {
    return this.euiI18n.lookupToken(
      'euiSuperSelect.screenReaderAnnouncement',
      'You are in a form selector and must select a single option. Use the Up and Down arrow keys to navigate or Escape to close.'
    );
  }

  get listboxLabel(): string {
    return this.euiI18n.lookupToken('euiSuperSelect.ariaLabel', 'Select listbox');
  }

  @cached
  get listboxClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSuperSelectStyles);

    return `euiSuperSelect__listbox eui-scrollBar ${euiClass(
      context,
      useEuiBorealisStyles(context, listboxScrollBar),
      styles.euiSuperSelect__listbox
    )}`;
  }

  /**
   * Option classes per state (upstream `EuiListItemLayout`: a button,
   * single selection, wrapping text). Only four combinations exist, so
   * they are composed once per theme/args, not per option.
   */
  @cached
  get itemStyles(): {
    item: (selected: boolean, focused: boolean, disabled: boolean) => string;
    content: string;
    text: string;
    icon: EuiCss;
  } {
    const context = getEuiThemeContext(this);
    const layout = useEuiBorealisStyles(context, euiListItemLayoutStyles);
    const dividers = this.args.hasDividers
      ? useEuiBorealisStyles(context, dividerStyles)
      : undefined;
    const extra = [
      'euiSuperSelect__item',
      dividers && 'euiSuperSelect__item--hasDividers',
      this.args.itemClassName
    ]
      .filter(Boolean)
      .join(' ');
    const cache = new Map<string, string>();

    return {
      item: (selected, focused, disabled) => {
        const key = `${+selected}${+focused}${+disabled}`;
        let value = cache.get(key);

        if (value === undefined) {
          value = `euiListItemLayout ${extra} ${euiClass(
            context,
            ITEM_RESET,
            layout.euiListItemLayout,
            !disabled && layout.isInteractive,
            !disabled && focused && layout.isFocused,
            !disabled && selected && layout.isSelected,
            !disabled && selected && focused && layout.isSelectedFocused,
            dividers,
            disabled && layout.isDisabled
          )}`;
          cache.set(key, value);
        }

        return value;
      },
      content: `euiListItemLayout__content ${euiClass(
        context,
        layout.euiListItemLayout__content,
        LAYOUT_ALIGN[this.args.itemLayoutAlign ?? 'center']
      )}`,
      text: `euiListItemLayout__text ${euiClass(
        context,
        layout.euiListItemLayout__text,
        layout.textWrap.wrap
      )}`,
      icon: layout.euiListItemLayout__icon
    };
  }

  itemClass = (index: number, option: EuiSuperSelectOption<unknown>): string =>
    this.itemStyles.item(
      this.isSelected(option),
      index === this.currentIndex,
      Boolean(option.disabled)
    );

  /** Upstream `resolveIconAndColor`: a check on the selected option. */
  iconColor = (option: EuiSuperSelectOption<unknown>): string =>
    option.disabled ? 'subdued' : this.isSelected(option) ? 'primary' : 'text';

  isSelected = (option: EuiSuperSelectOption<unknown>): boolean =>
    option.value === this.args.valueOfSelected;

  optionId = (index: number): string => `${this.idPrefix}_option-${index}`;

  get activeDescendant(): string | undefined {
    const option = this.args.options[this.currentIndex];

    return option?.value != null ? this.optionId(this.currentIndex) : undefined;
  }

  /**
   * Upstream: the selected option, else the first; disabled ones are
   * skipped forward (back to the candidate when every later one is
   * disabled).
   */
  get initialIndex(): number {
    const { options, valueOfSelected } = this.args;
    const selected = options.findIndex((option) => option?.value === valueOfSelected);
    const candidate = valueOfSelected != null && selected >= 0 ? selected : 0;
    let index = candidate;

    while (index < options.length && options[index]?.disabled) index++;

    return index >= options.length ? candidate : index;
  }

  /** What the popover focuses once it is positioned. */
  initialFocus = (): HTMLElement | null => {
    const index = this.initialIndex;

    this.currentIndex = index;

    return this.itemNodes[index] ?? document.getElementById(this.optionId(index));
  };

  @action
  openPopover(): void {
    if (this.args.disabled || this.args.readOnly) return;
    this.isPopoverOpen = this.args.options.length > 0;
    this.currentIndex = this.initialIndex;
    this.args.onFocus?.();
  }

  @action
  closePopover(): void {
    const panelHadFocus = this.itemNodes.some(
      (node) => node?.isConnected && node.contains(document.activeElement)
    );

    this.isPopoverOpen = false;
    this.currentIndex = -1;

    // Upstream returns focus to the control. Only when focus was in the
    // list (or lost), so an outside click keeps its own target focused.
    requestAnimationFrame(() => {
      const active = document.activeElement;

      if (panelHadFocus || !active || active === document.body) {
        this.controlButton?.focus();
      }
    });

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
    if (event.key === 'ArrowUp' || event.key === 'ArrowDown' || event.key === ' ') {
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
        // upstream: Tab picks the focused option
        event.preventDefault();
        event.stopPropagation();
        (event.target as HTMLElement).click();
        break;
      case 'ArrowUp':
        event.preventDefault();
        event.stopPropagation();
        this.shiftFocus(-1);
        break;
      case 'ArrowDown':
        event.preventDefault();
        event.stopPropagation();
        this.shiftFocus(1);
        break;
    }
  }

  /** Upstream `shiftFocus`: no wrapping, disabled options are skipped. */
  shiftFocus(step: 1 | -1): void {
    const { options } = this.args;

    if (this.currentIndex === -1) {
      this.focusItemAt(0);
      return;
    }

    for (
      let next = this.currentIndex + step;
      next >= 0 && next < options.length;
      next += step
    ) {
      if (!options[next]?.disabled) {
        this.focusItemAt(next);
        return;
      }
    }
  }

  focusItemAt(index: number): void {
    this.currentIndex = index;
    this.itemNodes[index]?.focus();
  }

  @action
  onItemFocus(index: number): void {
    if (this.currentIndex !== index) this.currentIndex = index;
  }

  registerItem = modifier((element: HTMLButtonElement, [index]: [number]) => {
    this.itemNodes[index] = element;

    return () => {
      if (this.itemNodes[index] === element) this.itemNodes[index] = undefined;
    };
  });

  registerControl = modifier((element: HTMLButtonElement) => {
    this.controlButton = element;

    return () => {
      if (this.controlButton === element) this.controlButton = null;
    };
  });

  <template>
    <EuiInputPopover
      class="euiSuperSelect {{@popoverProps.className}}"
      @isOpen={{this.isOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize={{argOrDefault @popoverProps.panelPaddingSize "none"}}
      @anchorPosition={{@popoverProps.anchorPosition}}
      @attachToAnchor={{@popoverProps.attachToAnchor}}
      @display={{@popoverProps.display}}
      @offset={{@popoverProps.offset}}
      @repositionToCrossAxis={{@popoverProps.repositionToCrossAxis}}
      @closeOnScroll={{@popoverProps.closeOnScroll}}
      @panelMinWidth={{@popoverProps.panelMinWidth}}
      @onPanelResize={{@popoverProps.onPanelResize}}
      @css={{@popoverProps.css}}
      @panelCss={{@popoverProps.panelCss}}
      @repositionOnScroll={{@popoverProps.repositionOnScroll}}
      @panelClassName={{@popoverProps.panelClassName}}
      @panelStyle={{@popoverProps.panelStyle}}
      @anchorClassName={{@popoverProps.anchorClassName}}
      @zIndex={{@popoverProps.zIndex}}
      @container={{@popoverProps.container}}
      @buffer={{@popoverProps.buffer}}
      @insert={{@popoverProps.insert}}
      @hasArrow={{@popoverProps.hasArrow}}
      @popoverScreenReaderText={{@popoverProps.popoverScreenReaderText}}
      @ariaLabel={{@popoverProps.ariaLabel}}
      @ariaLabelledBy={{@popoverProps.ariaLabelledBy}}
      @popoverRef={{@popoverProps.popoverRef}}
      @portalRef={{@popoverProps.portalRef}}
      @onTrapDeactivation={{@popoverProps.onTrapDeactivation}}
      @shouldAccountForOtherPopovers={{@popoverProps.shouldAccountForOtherPopovers}}
      @fullWidth={{@fullWidth}}
      @disableFocusTrap={{true}}
      @initialFocus={{this.initialFocus}}
    >
      <:input>
        <EuiSuperSelectControl
          @options={{@options}}
          @value={{@valueOfSelected}}
          @placeholder={{@placeholder}}
          @id={{@id}}
          @name={{@name}}
          @fullWidth={{@fullWidth}}
          @compressed={{@compressed}}
          @isLoading={{@isLoading}}
          @isInvalid={{@isInvalid}}
          @disabled={{@disabled}}
          @readOnly={{@readOnly}}
          @isDropdownOpen={{this.isPopoverOpen}}
          @isPrependProvided={{argOrDefault @isPrependProvided (has-block "prepend")}}
          @isAppendProvided={{argOrDefault @isAppendProvided (has-block "append")}}
          {{on "click" this.toggle}}
          {{on "keydown" this.onSelectKeyDown}}
          {{this.registerControl}}
          ...attributes
        >
          <:inputDisplay as |option|>
            {{#if (has-block "inputDisplay")}}
              {{yield option to="inputDisplay"}}
            {{else}}
              {{option.inputDisplay}}
            {{/if}}
          </:inputDisplay>
          <:prepend as |className|>{{yield className to="prepend"}}</:prepend>
          <:append as |className|>{{yield className to="append"}}</:append>
        </EuiSuperSelectControl>
      </:input>
      <:content>
        <EuiScreenReaderOnly>
          <p id={{this.describedById}}>{{this.announcement}}</p>
        </EuiScreenReaderOnly>
        <div
          class={{this.listboxClass}}
          role="listbox"
          aria-label={{this.listboxLabel}}
          aria-describedby={{this.describedById}}
          aria-activedescendant={{this.activeDescendant}}
          tabindex="0"
        >
          {{#each @options as |option index|}}
            {{#if (hasValue option)}}
              <button
                type="button"
                class={{this.itemClass index option}}
                id={{this.optionId index}}
                role="option"
                aria-selected={{if (this.isSelected option) "true" "false"}}
                disabled={{option.disabled}}
                data-test-subj="euiListItemLayout"
                {{on "click" (fn this.itemClicked option.value)}}
                {{on "keydown" this.onItemKeyDown}}
                {{on "focus" (fn this.onItemFocus index)}}
                {{this.registerItem index}}
              >
                <span class={{this.itemStyles.content}}>
                  <EuiIcon
                    class="euiListItemLayout__icon"
                    @css={{this.itemStyles.icon}}
                    @type={{if (this.isSelected option) "check" "empty"}}
                    @color={{this.iconColor option}}
                  />
                  <span class={{this.itemStyles.text}}>
                    {{#if (has-block "dropdownDisplay")}}
                      {{yield option to="dropdownDisplay"}}
                    {{else if option.dropdownDisplay}}
                      {{option.dropdownDisplay}}
                    {{else}}
                      {{option.inputDisplay}}
                    {{/if}}
                  </span>
                </span>
              </button>
            {{/if}}
          {{/each}}
        </div>
      </:content>
    </EuiInputPopover>
  </template>
}

/** Upstream skips options without a value. */
function hasValue(option: EuiSuperSelectOption<unknown>): boolean {
  return option.value != null;
}
