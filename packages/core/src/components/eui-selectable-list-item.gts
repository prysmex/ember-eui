import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiCheckboxControlStyles,
  euiListItemLayoutStyles
} from '../utils/eui/styles.generated.ts';
import EuiBadge from './eui-badge.gts';
import EuiIcon from './eui-icon.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiIconSignature } from './eui-icon';
import type { CSSInterpolation } from '@emotion/css/create-instance';

export type EuiSelectableOptionCheckedType = 'on' | 'off' | 'mixed' | undefined;

/** Roles that take `aria-checked` (upstream EuiListItemLayout). */
const ROLES_THAT_CAN_USE_ARIA_CHECKED = [
  'option',
  'checkbox',
  'menuitemcheckbox',
  'radio',
  'menuitemradio',
  'switch'
];
const NATIVELY_CHECKABLE_ROLES = ROLES_THAT_CAN_USE_ARIA_CHECKED.slice(1);
const ROLES_THAT_CAN_BE_MIXED = ['option', 'checkbox', 'menuitemcheckbox'];
const ROLES_THAT_CAN_USE_ARIA_SELECTED = [
  'tab',
  'gridcell',
  'option',
  'row',
  'treeitem'
];

/**
 * One option of an `EuiSelectable` list: a selection indicator, the label,
 * and optional prepend / append content. Usually rendered for you by
 * `EuiSelectable`.
 */
export interface EuiSelectableListItemSignature {
  Element: HTMLLIElement;
  Args: {
    /** Highlights it as the keyboard's current option. */
    isFocused?: boolean;
    /** Disables the option. */
    disabled?: boolean;
    /**
     * `'on'` (checked), `'off'` (excluded), `'mixed'` (checked for some) or
     * nothing. `true` is treated as `'on'`.
     */
    checked?: boolean | 'on' | 'off' | 'mixed';
    /**
     * Shows the selection indicator: a check box for multiple selection,
     * else a check mark / cross / dash. Defaults to `true`.
     */
    showIcons?: boolean;
    /** Text before the label. Use the `<:prepend>` block for markup. */
    prepend?: string;
    /** Text after the label. Use the `<:append>` block for markup. */
    append?: string;
    /** Tells screen readers that Enter excludes the option. */
    allowExclusions?: boolean;
    /**
     * `false` for an option of a multiple selection list: a check box
     * indicator and `aria-checked`. Otherwise (the default, as upstream)
     * a single selection option: an icon indicator, the selected
     * background and `aria-selected`.
     */
    singleSelection?: boolean | 'always';
    /**
     * The list is driven from a search field: adds the "press Enter"
     * instructions for screen readers.
     */
    searchable?: boolean;
    /**
     * Shows a "return key" badge on the focused option, to hint that
     * Enter selects it: `true`, `false`, or `{ text, iconSide }` for a
     * badge with text (e.g. "Go to"). Defaults to `false` (upstream).
     */
    onFocusBadge?: boolean | { text?: string; iconSide?: 'left' | 'right' };
    /** `role` of the `<li>`. Defaults to `'option'`. */
    role?: string;
    /** Hover styles and pointer cursor (set when the list handles clicks). */
    isInteractive?: boolean;
    /** Text of the label's `title` (on the text, not the option). */
    title?: string;
    /** Renders the prepend wrapper (for blocks that may be empty). */
    hasPrepend?: boolean;
    /** Renders the append wrapper (for blocks that may be empty). */
    hasAppend?: boolean;
  };
  Blocks: {
    /** The label. */
    default: [];
    /** Content before the label, e.g. an icon or avatar. */
    prepend: [];
    /** Content after the label, e.g. a count badge. */
    append: [];
  };
}

// Scoped stand-in for React's global reset; upstream styles come after.
const ITEM_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  listStyle: 'none',
  '& :where(*, *::before, *::after)': { boxSizing: 'border-box' }
} as const;

const HIDDEN_ICON = { display: 'none' } as const;

export default class EuiSelectableListItem extends Component<EuiSelectableListItemSignature> {
  @service declare euiI18n: EuiI18n;

  get context() {
    return getEuiThemeContext(this);
  }

  /** `true` is a legacy alias of `'on'`. */
  get checked(): EuiSelectableOptionCheckedType {
    const { checked } = this.args;
    if (checked === true) return 'on';
    return checked || undefined;
  }

  get role(): string {
    return this.args.role ?? 'option';
  }

  get isSingleSelection(): boolean {
    return this.args.singleSelection !== false;
  }

  get showIcons(): boolean {
    return this.args.showIcons !== false;
  }

  get isSelected(): boolean {
    return this.checked !== undefined;
  }

  get isDisabled(): boolean {
    return Boolean(this.args.disabled);
  }

  get isFocused(): boolean {
    return Boolean(this.args.isFocused) && !this.isDisabled;
  }

  /** Upstream `selectionMode`: `'checked'` uses `aria-checked`. */
  get selectionMode(): 'checked' | 'selected' {
    if (this.args.allowExclusions || this.checked === 'mixed') return 'checked';
    if (!this.isSingleSelection) return 'checked';
    if (NATIVELY_CHECKABLE_ROLES.includes(this.role)) return 'checked';
    return 'selected';
  }

  get ariaChecked(): 'true' | 'false' | 'mixed' | undefined {
    if (this.selectionMode !== 'checked') return undefined;
    if (!ROLES_THAT_CAN_USE_ARIA_CHECKED.includes(this.role)) return undefined;
    switch (this.checked) {
      case 'on':
      case 'off':
        return 'true';
      case 'mixed':
        return ROLES_THAT_CAN_BE_MIXED.includes(this.role) ? 'mixed' : 'false';
      default:
        return 'false';
    }
  }

  get ariaSelected(): 'true' | 'false' | undefined {
    if (this.ariaChecked !== undefined) return undefined;
    if (!ROLES_THAT_CAN_USE_ARIA_SELECTED.includes(this.role)) return undefined;
    return this.isSelected ? 'true' : 'false';
  }

  get ariaCurrent(): 'true' | undefined {
    return this.ariaChecked === undefined &&
      this.ariaSelected === undefined &&
      this.isSelected
      ? 'true'
      : undefined;
  }

  /** Upstream `resolveIconAndColor` for the single selection indicator. */
  get indicatorIcon(): {
    type: EuiIconSignature['Args']['type'];
    color: EuiIconSignature['Args']['color'];
  } {
    const color = this.isDisabled
      ? 'subdued'
      : this.isSelected
        ? 'primary'
        : 'text';
    switch (this.checked) {
      case 'on':
        return { type: 'check', color };
      case 'off':
        return { type: 'cross', color };
      case 'mixed':
        return { type: 'minus', color };
      default:
        return { type: 'empty', color: this.isDisabled ? 'subdued' : 'text' };
    }
  }

  get focusBadge(): { text?: string; iconSide?: 'left' | 'right' } | undefined {
    const badge = this.args.onFocusBadge;
    if (badge === true) return {};
    if (badge && typeof badge === 'object') return badge;
    return undefined;
  }

  get showFocusBadge(): boolean {
    return this.isFocused && this.focusBadge !== undefined;
  }

  get hasPrepend(): boolean {
    return this.args.hasPrepend ?? Boolean(this.args.prepend);
  }

  get hasAppend(): boolean {
    return this.args.hasAppend ?? Boolean(this.args.append);
  }

  /** Upstream screen reader state and instructions. */
  get screenReaderText(): { state?: string; instructions?: string } | undefined {
    const t = (token: string, fallback: string) =>
      this.euiI18n.lookupToken(token, fallback);
    const { allowExclusions, searchable } = this.args;
    const checkInstructions = () =>
      t('euiSelectableListItem.checkOptionInstructions', 'To check this option, press Enter.');
    const uncheckInstructions = () =>
      t('euiSelectableListItem.uncheckOptionInstructions', 'To uncheck this option, press Enter.');
    const excludeInstructions = () =>
      t('euiSelectableListItem.excludeOptionInstructions', 'To exclude this option, press Enter.');
    let state: string | undefined;
    let instructions: string | undefined;

    switch (this.checked) {
      case 'on':
        instructions = allowExclusions
          ? excludeInstructions()
          : searchable
            ? uncheckInstructions()
            : undefined;
        break;
      case 'off':
        state = t('euiSelectableListItem.excludedOption', 'Excluded option.');
        instructions = uncheckInstructions();
        break;
      case 'mixed':
        state = t('euiSelectableListItem.mixedOption', 'Mixed (indeterminate) option.');
        instructions = `${t(
          'euiSelectableListItem.mixedOptionInstructions',
          'To check this option for all, press Enter once.'
        )} ${
          allowExclusions
            ? t(
                'euiSelectableListItem.mixedOptionExcludeInstructions',
                'To exclude this option for all, press Enter twice.'
              )
            : t(
                'euiSelectableListItem.mixedOptionUncheckInstructions',
                'To uncheck this option for all, press Enter twice.'
              )
        }`;
        break;
      default:
        instructions =
          allowExclusions || searchable ? checkInstructions() : undefined;
    }

    const enabledInstructions = this.isDisabled ? undefined : instructions;
    if (!state && !enabledInstructions) return undefined;
    return { state, instructions: enabledInstructions };
  }

  get screenReaderString(): string | undefined {
    const text = this.screenReaderText;
    if (!text) return undefined;
    return ['.', text.state, text.instructions].filter(Boolean).join(' ');
  }

  @cached
  get layout() {
    return useEuiBorealisStyles(this.context, euiListItemLayoutStyles);
  }

  @cached
  get itemClass(): string {
    const layout = this.layout;
    const interactive: CSSInterpolation[] = this.isDisabled
      ? []
      : [
          this.args.isInteractive && layout.isInteractive,
          this.isFocused && layout.isFocused,
          (this.isSingleSelection || !this.showIcons) &&
            this.isSelected &&
            layout.isSelected,
          (this.isSingleSelection || !this.showIcons) &&
            this.isSelected &&
            this.isFocused &&
            layout.isSelectedFocused
        ];
    return euiClass(
      this.context,
      ITEM_RESET,
      { fontFamily: this.context.upstream.euiTheme.font.family },
      layout.euiListItemLayout,
      ...interactive,
      this.isDisabled && layout.isDisabled
    );
  }

  @cached
  get partClasses() {
    const context = this.context;
    const layout = this.layout;
    return {
      content: euiClass(context, layout.euiListItemLayout__content),
      prepend: euiClass(context, layout.euiListItemLayout__prepend),
      append: euiClass(context, layout.euiListItemLayout__append),
      text: euiClass(
        context,
        layout.euiListItemLayout__text,
        layout.textWrap.truncate
      )
    };
  }

  @cached
  get iconCss(): EuiCss {
    return this.layout.euiListItemLayout__icon;
  }

  /** Upstream EuiCheckboxControl for multiple selection. */
  @cached
  get checkbox(): { className: string; icon: EuiIconSignature['Args']['type']; iconCss: EuiCss } {
    const control = useEuiBorealisStyles(this.context, euiCheckboxControlStyles);
    const checked = this.checked;
    const indeterminate = checked === 'mixed';
    const excluded = checked === 'off';
    const isSelected = checked === 'on' || indeterminate || excluded;
    const isExcluded = excluded && !indeterminate;
    const state = this.isDisabled
      ? isSelected
        ? control.disabled.selected
        : control.disabled.unselected
      : isExcluded
        ? control.enabled.excluded
        : isSelected
          ? control.enabled.selected
          : control.enabled.unselected;
    const icon = indeterminate
      ? 'stopFill'
      : excluded
        ? 'cross'
        : checked === 'on'
          ? 'check'
          : 'empty';
    return {
      className: euiClass(
        this.context,
        { boxSizing: 'border-box' },
        control.euiCheckboxControl,
        state
      ),
      icon,
      iconCss: [
        control.icon.euiCheckbox__icon,
        indeterminate ? control.icon.indeterminate : control.icon.check,
        // nothing to draw: keep forced colors from revealing an empty glyph
        icon === 'empty' ? HIDDEN_ICON : undefined
      ]
    };
  }

  <template>
    <li
      role={{this.role}}
      class="euiListItemLayout euiSelectableListItem
        {{if @isFocused 'euiSelectableListItem-isFocused'}}
        {{this.itemClass}}"
      aria-checked={{this.ariaChecked}}
      aria-selected={{this.ariaSelected}}
      aria-current={{this.ariaCurrent}}
      aria-disabled={{if this.isDisabled "true"}}
      data-test-subj="euiListItemLayout"
      ...attributes
    >
      <span
        class="euiListItemLayout__content euiSelectableListItem__content
          {{this.partClasses.content}}"
      >
        {{#if this.showIcons}}
          {{#if this.isSingleSelection}}
            <EuiIcon
              class="euiListItemLayout__icon euiSelectableListItem__icon"
              @type={{this.indicatorIcon.type}}
              @color={{this.indicatorIcon.color}}
              @css={{this.iconCss}}
            />
          {{else}}
            <span
              class="euiCheckboxControl euiListItemLayout__checkbox euiSelectableListItem__icon
                {{this.checkbox.className}}"
            >
              <EuiIcon
                role="presentation"
                @type={{this.checkbox.icon}}
                @size="m"
                @css={{this.checkbox.iconCss}}
              />
            </span>
          {{/if}}
        {{/if}}
        {{#if
          (or2 this.hasPrepend (and2 (has-block "prepend") (isUndefined @hasPrepend)))
        }}
          <span
            class="euiListItemLayout__prepend euiSelectableListItem__prepend
              {{this.partClasses.prepend}}"
          >
            {{~#if (has-block "prepend")}}{{yield to="prepend"}}{{else}}{{@prepend}}{{/if~}}
          </span>
        {{/if}}
        <span
          class="euiListItemLayout__text euiSelectableListItem__text
            {{this.partClasses.text}}"
          title={{@title}}
        >
          {{yield}}
          {{#if this.screenReaderString}}
            <EuiScreenReaderOnly>
              <div>{{this.screenReaderString}}</div>
            </EuiScreenReaderOnly>
          {{/if}}
        </span>
        {{#if
          (or2
            (or2 this.hasAppend (and2 (has-block "append") (isUndefined @hasAppend)))
            this.showFocusBadge
          )
        }}
          <span
            class="euiListItemLayout__append euiSelectableListItem__append
              {{this.partClasses.append}}"
          >
            {{#if (has-block "append")}}
              {{yield to="append"}}
            {{else}}
              {{@append}}
            {{/if}}
            {{#if this.showFocusBadge}}
              <EuiBadge
                class="euiSelectableListItem__onFocusBadge"
                @iconType="return"
                @iconSide={{if this.focusBadge.iconSide this.focusBadge.iconSide "left"}}
                @color="hollow"
                aria-hidden="true"
              >{{this.focusBadge.text}}</EuiBadge>
            {{/if}}
          </span>
        {{/if}}
      </span>
    </li>
  </template>
}

function and2(a: unknown, b: unknown): boolean {
  return Boolean(a && b);
}

function or2(a: unknown, b: unknown): boolean {
  return Boolean(a || b);
}

function isUndefined(a: unknown): boolean {
  return a === undefined;
}
