import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { service } from '@ember/service';

import { filterGroupContext } from '../-private/eui-filter-group-context.ts';
import { _compressedButtonFocusColors } from '../utils/eui/buttons-misc.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiButtonDisplayContentStyles,
  euiButtonDisplayStyles,
  euiButtonDisplaysColors,
  euiButtonEmptyStyles,
  euiFilterButtonChildStyles,
  euiFilterButtonStyles,
  euiFilterButtonWrapperStyles,
  euiFocusRing
} from '../utils/eui/styles.generated.ts';
import EuiEmotionProvider from './eui-emotion-provider.gts';
import EuiIcon from './eui-icon.gts';
import EuiInnerText from './eui-inner-text.gts';
import EuiNotificationBadge from './eui-notification-badge.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiButtonEmptySignature } from './eui-button-empty';
import type { CSSObject } from '@emotion/css/create-instance';

/** Upstream `EXTENDED_BUTTON_COLORS`. */
const COLORS = new Set([
  'text',
  'accent',
  'accentSecondary',
  'primary',
  'success',
  'warning',
  'danger',
  'neutral',
  'risk'
]);

/** Icons that make the button a popover/collapsible anchor (`aria-expanded`). */
const COLLAPSIBLE_ICONS = new Set(['chevronSingleDown', 'arrowDown']);

/**
 * A button in an `EuiFilterGroup`: a toggle ("On", "Off"), or the anchor
 * of a popover listing filter options, with the number of options or of
 * active filters.
 */
export interface EuiFilterButtonSignature {
  Element: EuiButtonEmptySignature['Element'];
  Args: {
    /** Icon, e.g. `'chevronSingleDown'` for a button opening a popover. */
    iconType?: EuiButtonEmptySignature['Args']['iconType'];
    /** `'left'` or `'right'` of the text. Defaults to `'right'`. */
    iconSide?: 'left' | 'right';
    /** Text color, any `EuiButtonEmpty` color. Defaults to `'text'`. */
    color?: EuiButtonEmptySignature['Args']['color'];
    /**
     * Color of the badge while `@hasActiveFilters`: `'accent'` or
     * `'success'`. Defaults to `'accent'`.
     */
    badgeColor?: 'accent' | 'success';
    /**
     * Pressed look, e.g. while its popover is open or a toggle is on. Sets
     * `aria-expanded` on popover anchors (`@iconType="chevronSingleDown"` or its
     * legacy alias `"arrowDown"`), `aria-pressed` otherwise.
     */
    isSelected?: boolean;
    /**
     * Renders an on/off toggle (upstream `isToggle`): a small `EuiButton`
     * look, highlighted while `@isSelected`.
     */
    isToggle?: boolean;
    /** Bold text and an accent badge: some of its filters are applied. */
    hasActiveFilters?: boolean;
    /** Number of available filters, shown in a badge. */
    numFilters?: number;
    /** Number of applied filters, shown instead of `@numFilters` when above 0. */
    numActiveFilters?: number;
    /** Disables the button. */
    isDisabled?: boolean;
    /** Grows to fill the group. Defaults to `true`. */
    grow?: boolean;
    /**
     * Removes the divider after it, to join it with the next button
     * (e.g. "On" and "Off" toggles).
     */
    withNext?: boolean;
    /** Same as `@withNext`. */
    noDivider?: boolean;
    /** `type` of the `<button>`. Defaults to `'button'`. */
    type?: string;
  };
  Blocks: {
    /** The button text. Leave it out for an icon-only button. */
    default: [];
  };
}

export default class EuiFilterButton extends Component<EuiFilterButtonSignature> {
  @service declare euiI18n: EuiI18n;

  get context() {
    return getEuiThemeContext(this);
  }
  get group() {
    return filterGroupContext(this);
  }
  get color() {
    const color = this.args.color === 'ghost' ? 'text' : this.args.color;
    return color && COLORS.has(color) ? color : 'text';
  }
  get isCollapsible() {
    return (
      !this.args.isToggle &&
      typeof this.args.iconType === 'string' &&
      COLLAPSIBLE_ICONS.has(this.args.iconType)
    );
  }
  get expanded() {
    return this.isCollapsible
      ? String(Boolean(this.args.isSelected ?? this.args.hasActiveFilters))
      : undefined;
  }
  get pressed() {
    return this.isCollapsible || this.args.isSelected === undefined
      ? undefined
      : String(this.args.isSelected);
  }
  get fill() {
    return Boolean(
      this.args.isToggle &&
        this.args.isSelected &&
        (this.group.display === 'highlighted' || this.color !== 'text')
    );
  }
  get iconRight() {
    return this.args.iconSide !== 'left';
  }
  get hasNumFilters(): boolean {
    return this.args.numFilters !== undefined && this.args.numFilters !== null;
  }
  get badgeCount(): number | undefined {
    return this.args.numActiveFilters || this.args.numFilters;
  }
  get showBadge(): boolean {
    return this.hasNumFilters || Boolean(this.args.numActiveFilters);
  }
  get badgeColor() {
    return this.args.isDisabled || !this.args.hasActiveFilters
      ? 'subdued'
      : (this.args.badgeColor ?? 'accent');
  }
  /** Upstream renders a selected toggle's badge in the inverse color mode. */
  get badgeColorMode(): 'light' | 'dark' | undefined {
    if (!(this.args.isToggle && this.args.isSelected)) return undefined;
    return this.context.upstream.colorMode === 'DARK' ? 'light' : 'dark';
  }
  get badgeLabel(): string {
    return this.args.hasActiveFilters
      ? this.euiI18n.lookupToken(
          'euiFilterButton.filterBadgeActiveAriaLabel',
          '{count} active filters',
          { count: this.badgeCount }
        )
      : this.euiI18n.lookupToken(
          'euiFilterButton.filterBadgeAvailableAriaLabel',
          '{count} available filters',
          { count: this.badgeCount }
        );
  }

  wrapperClasses = (isIconOnly: boolean) => {
    const context = this.context;
    const wrapper = useEuiBorealisStyles(context, euiFilterButtonWrapperStyles);
    const styles = useEuiBorealisStyles(context, euiFilterButtonStyles);
    const { compressed, showDividers } = this.group;
    return `euiFilterButton__wrapper ${euiClass(
      context,
      { boxSizing: 'border-box' },
      wrapper.wrapper,
      (this.args.withNext || this.args.noDivider) && styles.withNext,
      this.hasNumFilters && styles.hasNotification,
      compressed && wrapper.compressed,
      showDividers && wrapper.hasDividers,
      isIconOnly && wrapper.isIconOnly,
      this.args.grow === false && styles.noGrow
    )}`;
  };

  @cached
  get buttonStyles() {
    const context = this.context;
    const theme = context.upstream.euiTheme;
    const styles = useEuiBorealisStyles(context, euiFilterButtonStyles);
    const colors = useEuiBorealisStyles(context, euiButtonDisplaysColors);
    const focusColors = useEuiBorealisStyles(
      context,
      _compressedButtonFocusColors
    );
    const child = useEuiBorealisStyles(context, euiFilterButtonChildStyles);
    const { isToggle, isSelected, isDisabled, hasActiveFilters } = this.args;
    const color = this.color;
    const colorKey = isDisabled ? 'disabled' : color;
    // React's global `button` reset, scoped.
    const reset: CSSObject = {
      boxSizing: 'border-box',
      margin: 0,
      padding: 0,
      border: 'none',
      background: 'none',
      fontFamily: theme.font.family,
      textDecoration: 'none'
    };
    let base: unknown[];
    if (isToggle) {
      const display = useEuiBorealisStyles(context, euiButtonDisplayStyles);
      base = [
        display.euiButtonDisplay,
        display.s,
        isDisabled && display.isDisabled,
        colors[this.fill ? 'fill' : 'base']![colorKey]
      ];
    } else {
      const empty = useEuiBorealisStyles(context, euiButtonEmptyStyles);
      base = [
        empty.euiButtonEmpty,
        empty.m,
        colors['empty']![colorKey],
        isDisabled && empty.isDisabled
      ];
    }
    return [
      reset,
      `&:focus { ${euiFocusRing(context.upstream)} }`,
      ...base,
      styles.euiFilterButton,
      hasActiveFilters && styles.hasActiveFilters,
      this.group.compressed && styles.compressed,
      isToggle && styles.buttonType.toggle,
      isToggle &&
        isSelected &&
        this.group.display !== 'highlighted' &&
        color === 'text' &&
        styles.isSelected,
      !isToggle && !isDisabled && focusColors[color],
      // EuiNotificationBadge has no `@css` yet: upstream's badge slots are
      // scoped to this button instead of adding a second class to the badge.
      {
        '& .euiFilterButton__notification': [
          child.notification.euiFilterButton__notification,
          isDisabled && child.notification.disabled
        ]
      }
    ];
  }

  buttonClasses = (isIconOnly: boolean) => {
    const styles = useEuiBorealisStyles(this.context, euiFilterButtonStyles);
    const { isToggle, isSelected, hasActiveFilters } = this.args;
    return [
      isToggle ? 'euiButton' : 'euiButtonEmpty',
      'euiFilterButton',
      isSelected && 'euiFilterButton-isSelected',
      hasActiveFilters && 'euiFilterButton-hasActiveFilters',
      this.hasNumFilters && 'euiFilterButton-hasNotification',
      isIconOnly && 'euiFilterButton-isIconOnly',
      isToggle && 'euiFilterButton-isToggle',
      euiClass(
        this.context,
        ...(this.buttonStyles as Parameters<typeof euiClass>[1][]),
        isIconOnly && styles.isIconOnly
      )
    ]
      .filter(Boolean)
      .join(' ');
  };

  @cached
  get contentClasses() {
    const context = this.context;
    const display = useEuiBorealisStyles(context, euiButtonDisplayContentStyles);
    const child = useEuiBorealisStyles(context, euiFilterButtonChildStyles);
    return `euiFilterButton__content ${euiClass(
      context,
      { boxSizing: 'border-box' },
      display.euiButtonDisplayContent,
      child.content.euiFilterButton__content,
      this.args.iconType && child.content.hasIcon
    )}`;
  }

  @cached
  get textClasses() {
    const context = this.context;
    const child = useEuiBorealisStyles(context, euiFilterButtonChildStyles);
    return [
      'euiFilterButton__text',
      this.showBadge && 'euiFilterButton__text-hasNotification',
      euiClass(
        context,
        child.text.euiFilterButton__text,
        this.showBadge && child.text.hasNotification
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get wrapper() {
    return this.wrapperClasses(false);
  }
  @cached
  get wrapperIconOnly() {
    return this.wrapperClasses(true);
  }
  @cached
  get button() {
    return this.buttonClasses(false);
  }
  @cached
  get buttonIconOnly() {
    return this.buttonClasses(true);
  }

  get type() {
    return this.args.type ?? 'button';
  }

  <template>
    {{#let (not (has-block)) as |isIconOnly|}}
      <div class={{if isIconOnly this.wrapperIconOnly this.wrapper}}>
        <button
          class={{if isIconOnly this.buttonIconOnly this.button}}
          type={{this.type}}
          disabled={{@isDisabled}}
          aria-pressed={{this.pressed}}
          aria-expanded={{this.expanded}}
          ...attributes
        >
          <span class={{this.contentClasses}}>
            {{#if @iconType}}
              {{#unless this.iconRight}}
                <EuiIcon
                  @iconClasses="euiButtonContent__icon"
                  @type={{@iconType}}
                  @size="m"
                  @color="inherit"
                />
              {{/unless}}
            {{/if}}
            {{#if (has-block)}}
              <EuiInnerText as |ref innerText|>
                <span
                  class={{this.textClasses}}
                  data-text={{innerText}}
                  title={{innerText}}
                  {{didInsert ref}}
                >{{yield}}</span>
              </EuiInnerText>
            {{/if}}
            {{#if this.showBadge}}
              {{#if this.badgeColorMode}}
                <EuiEmotionProvider
                  @colorMode={{this.badgeColorMode}}
                  @globalStyles={{false}}
                >
                  <EuiNotificationBadge
                    class="euiFilterButton__notification"
                    @size="m"
                    @color={{this.badgeColor}}
                    role="marquee"
                    aria-label={{this.badgeLabel}}
                  >{{this.badgeCount}}</EuiNotificationBadge>
                </EuiEmotionProvider>
              {{else}}
                <EuiNotificationBadge
                  class="euiFilterButton__notification"
                  @size="m"
                  @color={{this.badgeColor}}
                  role="marquee"
                  aria-label={{this.badgeLabel}}
                >{{this.badgeCount}}</EuiNotificationBadge>
              {{/if}}
            {{/if}}
            {{#if @iconType}}
              {{#if this.iconRight}}
                <EuiIcon
                  @iconClasses="euiButtonContent__icon"
                  @type={{@iconType}}
                  @size="m"
                  @color="inherit"
                />
              {{/if}}
            {{/if}}
          </span>
        </button>
      </div>
    {{/let}}
  </template>
}

function not(value: unknown): boolean {
  return !value;
}
