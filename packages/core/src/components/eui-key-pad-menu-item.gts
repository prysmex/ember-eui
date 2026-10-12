import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiKeyPadMenuItemChildStyles, euiKeyPadMenuItemStyles } from '../utils/eui/lists.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import EuiBetaBadge from './eui-beta-badge.gts';
import EuiCheckbox from './eui-checkbox.gts';
import { getSecureRelForTarget, isValidHref } from './eui-link.gts';
import EuiRadio from './eui-radio.gts';

import type { EuiIconSignature } from './eui-icon';

export interface EuiKeyPadMenuItemSignature {
  Element: HTMLButtonElement | HTMLAnchorElement | HTMLLabelElement;
  Args: {
    /**
     * Makes the item a `<label>` with a checkbox (`'multi'`, or the legacy
     * `'label'`) or a radio (`'single'`, share a `@name`) inside a
     * checkable EuiKeyPadMenu.
     */
    checkable?: 'single' | 'multi' | 'label';
    /** Makes the item a link. A `javascript:` URL disables the item. */
    href?: string;
    /** Disables the item. */
    isDisabled?: boolean;
    /**
     * Selected state: `aria-pressed` on buttons (omitted when not set),
     * `aria-current` on links, `checked` on checkable items.
     */
    isSelected?: boolean;
    /** Text under the icon. */
    label?: string;
    /** `name` of the radio or checkbox. */
    name?: string;
    /** `value` of the radio. */
    value?: string;
    /**
     * Called when a checkable item changes, with its id (and value for
     * radios). Buttons use `{{on "click" …}}`.
     */
    onChange?: (id: string, value?: string | Event) => void;
    /** Shows a beta badge with the first letter of this label (full label on hover). */
    betaBadgeLabel?: string;
    /** Icon in the beta badge instead of the letter. */
    betaBadgeIconType?: EuiIconSignature['Args']['type'];
    /** Tooltip of the beta badge. */
    betaBadgeTooltipContent?: string;
    /** Id of the checkable input. Defaults to a random id. */
    id?: string;
    /** `target` of the `@href` link. */
    target?: string;
    /** `rel` of the link; `noreferrer` (and `noopener` for `_blank`) is added. */
    rel?: string;
  };
  Blocks: {
    /** The icon, e.g. `<EuiIcon @type="discoverApp" @size="l" />`. */
    default: [];
  };
}

const noop = () => {};

/** Native Ember key pad menu item using the upstream EUI 123 / Borealis styles. */
export default class EuiKeyPadMenuItem extends Component<EuiKeyPadMenuItemSignature> {
  generatedId = randomId();

  get context() {
    return getEuiThemeContext(this);
  }

  get itemId(): string {
    return this.args.id ?? this.generatedId;
  }

  get isDisabled(): boolean {
    const { href, isDisabled } = this.args;
    return Boolean(isDisabled || (href && !isValidHref(href)));
  }

  get isSelected(): boolean {
    return Boolean(this.args.isSelected);
  }

  get tagName(): 'a' | 'button' | 'label' {
    if (this.args.checkable) return 'label';
    return this.args.href && !this.isDisabled ? 'a' : 'button';
  }

  get isLink(): boolean {
    return this.tagName === 'a';
  }

  get isButton(): boolean {
    return this.tagName === 'button';
  }

  get isRadio(): boolean {
    return this.args.checkable === 'single';
  }

  get rel(): string | undefined {
    return this.isLink
      ? getSecureRelForTarget(this.args.target, this.args.rel)
      : undefined;
  }

  get ariaPressed(): string | undefined {
    const { isSelected } = this.args;
    return this.isButton && isSelected !== undefined
      ? String(isSelected)
      : undefined;
  }

  get betaBadgeLetter(): string | undefined {
    return this.args.betaBadgeLabel?.charAt(0);
  }

  get onChange() {
    return this.args.onChange ?? noop;
  }

  @cached
  get childStyles() {
    return useEuiBorealisStyles(this.context, euiKeyPadMenuItemChildStyles);
  }

  @cached
  get classes(): string {
    const context = this.context;
    const theme = context.upstream.euiTheme;
    const styles = useEuiBorealisStyles(context, euiKeyPadMenuItemStyles);
    const disabled = this.isDisabled;
    // Scoped stand-in for React's global button/link reset; upstream after.
    const reset = {
      boxSizing: 'border-box' as const,
      margin: 0,
      border: 0,
      background: 'none',
      fontFamily: theme.font.family,
      fontSize: 'inherit',
      textDecoration: 'none'
    };
    return `euiKeyPadMenuItem ${euiClass(
      context,
      reset,
      styles.euiKeyPadMenuItem,
      disabled ? styles.disabled.disabled : styles.enabled,
      this.isSelected && (disabled ? styles.disabled.selected : styles.selected)
    )}`;
  }

  @cached
  get innerClass(): string {
    return `euiKeyPadMenuItem__inner ${euiClass(
      this.context,
      { boxSizing: 'border-box' },
      this.childStyles.euiKeyPadMenuItem__inner
    )}`;
  }

  @cached
  get iconClass(): string {
    return `euiKeyPadMenuItem__icon ${euiClass(
      this.context,
      this.childStyles.euiKeyPadMenuItem__icon
    )}`;
  }

  @cached
  get labelClass(): string {
    return `euiKeyPadMenuItem__label ${euiClass(
      this.context,
      this.childStyles.euiKeyPadMenuItem__label
    )}`;
  }

  @cached
  get betaBadgeCss(): EuiCss {
    return this.childStyles.euiKeyPadMenuItem__betaBadge;
  }

  @cached
  get checkableCss(): EuiCss {
    const styles = this.childStyles;
    const selected = this.isSelected;
    const disabled = this.isDisabled;
    return [
      styles.euiKeyPadMenuItem__checkableInput,
      !selected && disabled && styles.hideCheckableInput,
      !selected && !disabled && styles.showCheckableInputOnInteraction
    ];
  }

  <template>
    {{#if this.isLink}}
      <a
        class={{this.classes}}
        href={{@href}}
        target={{@target}}
        rel={{this.rel}}
        aria-current={{if this.isSelected "true"}}
        ...attributes
      >
        <span class={{this.innerClass}}>
          {{#if @betaBadgeLabel}}
            <EuiBetaBadge
              @size="s"
              @color="subdued"
              class="euiKeyPadMenuItem__betaBadge"
              @css={{this.betaBadgeCss}}
              @label={{this.betaBadgeLetter}}
              @title={{@betaBadgeLabel}}
              @iconType={{@betaBadgeIconType}}
              @tooltipContent={{@betaBadgeTooltipContent}}
            />
          {{/if}}
          <span class={{this.iconClass}}>{{yield}}</span>
          <span class={{this.labelClass}}>{{@label}}</span>
        </span>
      </a>
    {{else if this.isButton}}
      <button
        class={{this.classes}}
        type="button"
        disabled={{this.isDisabled}}
        aria-pressed={{this.ariaPressed}}
        ...attributes
      >
        <span class={{this.innerClass}}>
          {{#if @betaBadgeLabel}}
            <EuiBetaBadge
              @size="s"
              @color="subdued"
              class="euiKeyPadMenuItem__betaBadge"
              @css={{this.betaBadgeCss}}
              @label={{this.betaBadgeLetter}}
              @title={{@betaBadgeLabel}}
              @iconType={{@betaBadgeIconType}}
              @tooltipContent={{@betaBadgeTooltipContent}}
            />
          {{/if}}
          <span class={{this.iconClass}}>{{yield}}</span>
          <span class={{this.labelClass}}>{{@label}}</span>
        </span>
      </button>
    {{else}}
      <label class={{this.classes}} for={{this.itemId}} ...attributes>
        <span class={{this.innerClass}}>
          {{#if this.isRadio}}
            <EuiRadio
              id={{this.itemId}}
              @containerClass="euiKeyPadMenuItem__checkableInput"
              @css={{this.checkableCss}}
              @checked={{this.isSelected}}
              @disabled={{this.isDisabled}}
              @name={{@name}}
              value={{@value}}
              {{on "change" (fn this.onChange this.itemId @value)}}
            />
          {{else}}
            <EuiCheckbox
              id={{this.itemId}}
              @containerClass="euiKeyPadMenuItem__checkableInput"
              @css={{this.checkableCss}}
              @checked={{this.isSelected}}
              @disabled={{this.isDisabled}}
              @name={{@name}}
              {{on "change" (fn this.onChange this.itemId)}}
            />
          {{/if}}
          <span class={{this.iconClass}}>{{yield}}</span>
          <span class={{this.labelClass}}>{{@label}}</span>
        </span>
      </label>
    {{/if}}
  </template>
}
