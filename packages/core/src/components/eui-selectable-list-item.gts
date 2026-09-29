import Component from '@glimmer/component';
import { service } from '@ember/service';

import EuiBadge from './eui-badge.gts';
import EuiIcon from './eui-icon.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n';

/**
 * One option of an `EuiSelectable` list: a check mark (or a cross when
 * excluded), the label, and optional prepend / append content. Usually
 * rendered for you by `EuiSelectable`.
 */
export interface EuiSelectableListItemSignature {
  Element: HTMLLIElement;
  Args: {
    /** Highlights it as the keyboard's current option. */
    isFocused?: boolean;
    /** Disables the option. */
    disabled?: boolean;
    /** `'on'` (check mark), `'off'` (cross, excluded) or nothing. */
    checked?: boolean | 'on' | 'off';
    /** Shows the check mark / cross column. Defaults to `true`. */
    showIcons?: boolean;
    /** Text before the label. Use the `<:prepend>` block for markup. */
    prepend?: string;
    /** Text after the label. Use the `<:append>` block for markup. */
    append?: string;
    /** Tells screen readers that Enter includes / excludes the option. */
    allowExclusions?: boolean;
    /**
     * Shows a "return key" badge on the focused option, to hint that
     * Enter selects it: `true`, `false`, or `{ text, iconSide }` for a
     * badge with text (e.g. "Go to"). Defaults to `true`.
     */
    onFocusBadge?: boolean | { text?: string; iconSide?: 'left' | 'right' };
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

export default class EuiSelectableListItem extends Component<EuiSelectableListItemSignature> {
  @service declare euiI18n: EuiI18n;

  get isChecked(): boolean {
    return typeof this.args.checked === 'string' || this.args.checked === true;
  }

  get icon(): string {
    const { checked } = this.args;

    if (checked === 'off') return 'cross';

    return checked ? 'check' : 'empty';
  }

  get showIcons(): boolean {
    return this.args.showIcons !== false;
  }

  get focusBadge(): { text?: string; iconSide?: 'left' | 'right' } {
    const badge = this.args.onFocusBadge;

    return typeof badge === 'object' ? badge : {};
  }

  get hasPrepend(): boolean {
    return this.args.hasPrepend ?? Boolean(this.args.prepend);
  }

  get hasAppend(): boolean {
    return this.args.hasAppend ?? Boolean(this.args.append);
  }

  get showFocusBadge(): boolean {
    return this.args.onFocusBadge !== false && Boolean(this.args.isFocused) && !this.args.disabled;
  }

  get exclusionState(): { state: string; instruction: string } | undefined {
    if (!this.args.allowExclusions) return undefined;

    if (this.args.checked === 'on') {
      return {
        state: this.euiI18n.lookupToken('euiSelectableListItem.includedOption', 'Included option.'),
        instruction: this.euiI18n.lookupToken(
          'euiSelectableListItem.includedOptionInstructions',
          'To exclude this option, press enter.'
        )
      };
    }

    if (this.args.checked === 'off') {
      return {
        state: this.euiI18n.lookupToken('euiSelectableListItem.excludedOption', 'Excluded option.'),
        instruction: this.euiI18n.lookupToken(
          'euiSelectableListItem.excludedOptionInstructions',
          'To deselect this option, press enter.'
        )
      };
    }

    return undefined;
  }

  <template>
    <li
      role="option"
      aria-selected={{if (and2 (not2 @disabled) this.isChecked) "true" "false"}}
      class="euiSelectableListItem
        {{if @isFocused 'euiSelectableListItem-isFocused'}}"
      aria-disabled={{if @disabled "true"}}
      ...attributes
    >
      <span class="euiSelectableListItem__content">
        {{#if this.showIcons}}
          <EuiIcon
            class="euiSelectableListItem__icon"
            @type={{this.icon}}
            @color={{if @checked "text"}}
          />
        {{/if}}
        {{#if (or2 this.hasPrepend (and2 (has-block "prepend") (isUndefined @hasPrepend)))}}
          <span class="euiSelectableListItem__prepend">
            {{~#if (has-block "prepend")}}{{yield to="prepend"}}{{else}}{{@prepend}}{{/if~}}
          </span>
        {{/if}}
        <span class="euiSelectableListItem__text">
          {{#if this.exclusionState}}
            <EuiScreenReaderOnly>{{this.exclusionState.state}}</EuiScreenReaderOnly>
          {{/if}}
          {{yield}}
          {{#if this.exclusionState}}
            <EuiScreenReaderOnly>{{this.exclusionState.instruction}}</EuiScreenReaderOnly>
          {{/if}}
        </span>
        {{#if
          (or2
            (or2 this.hasAppend (and2 (has-block "append") (isUndefined @hasAppend)))
            this.showFocusBadge
          )
        }}
          <span class="euiSelectableListItem__append">
            {{#if (has-block "append")}}
              {{yield to="append"}}
            {{else}}
              {{@append}}
            {{/if}}
            {{#if this.showFocusBadge}}
              <EuiBadge
                class="euiSelectableListItem__onFocusBadge"
                @iconType="returnKey"
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

function not2(a: unknown): boolean {
  return !a;
}
