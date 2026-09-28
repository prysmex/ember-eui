import Component from '@glimmer/component';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { service } from '@ember/service';

import EuiButtonEmpty from './eui-button-empty.gts';
import EuiInnerText from './eui-inner-text.gts';
import EuiNotificationBadge from './eui-notification-badge.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiButtonEmptySignature } from './eui-button-empty';

/**
 * A button in an `EuiFilterGroup`: a toggle ("On", "Off"), or the anchor
 * of a popover listing filter options, with the number of options or of
 * active filters.
 */
export interface EuiFilterButtonSignature {
  Element: EuiButtonEmptySignature['Element'];
  Args: {
    /** Icon, e.g. `'arrowDown'` for a button opening a popover. */
    iconType?: EuiButtonEmptySignature['Args']['iconType'];
    /** `'left'` or `'right'` of the text. Defaults to `'right'`. */
    iconSide?: 'left' | 'right';
    /** Text color, any `EuiButtonEmpty` color. Defaults to `'text'`. */
    color?: EuiButtonEmptySignature['Args']['color'];
    /** Pressed look, e.g. while its popover is open or a toggle is on. */
    isSelected?: boolean;
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
    /** The button text. */
    default: [];
  };
}

export default class EuiFilterButton extends Component<EuiFilterButtonSignature> {
  @service declare euiI18n: EuiI18n;

  get hasNumFilters(): boolean {
    return this.args.numFilters !== undefined && this.args.numFilters !== null;
  }

  get badgeCount(): number | undefined {
    return this.args.numActiveFilters || this.args.numFilters;
  }

  get showBadge(): boolean {
    return this.hasNumFilters || (this.args.numActiveFilters ?? 0) > 0;
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

  get classes(): string {
    const { isSelected, hasActiveFilters, iconType, grow, noDivider, withNext } = this.args;

    return [
      'euiFilterButton',
      isSelected && 'euiFilterButton-isSelected',
      hasActiveFilters && 'euiFilterButton-hasActiveFilters',
      this.hasNumFilters && 'euiFilterButton-hasNotification',
      iconType && 'euiFilterButton--hasIcon',
      grow === false && 'euiFilterButton--noGrow',
      (noDivider || withNext) && 'euiFilterButton--withNext'
    ]
      .filter(Boolean)
      .join(' ');
  }

  get textClasses(): string | undefined {
    return this.hasNumFilters || this.args.numActiveFilters
      ? 'euiFilterButton__text-hasNotification'
      : undefined;
  }

  <template>
    <EuiButtonEmpty
      class={{this.classes}}
      @color={{if @color @color "text"}}
      @iconType={{@iconType}}
      @iconSide={{iconSide @iconSide}}
      @isDisabled={{@isDisabled}}
      @isSelected={{@isSelected}}
      @type={{@type}}
      @textClasses={{this.textClasses}}
      ...attributes
    >
      <EuiInnerText as |ref innerText|>
        <span
          class="euiFilterButton__textShift"
          data-text={{innerText}}
          title={{innerText}}
          {{didInsert ref}}
        >{{yield}}</span>
      </EuiInnerText>
      {{#if this.showBadge}}
        <EuiNotificationBadge
          class="euiFilterButton__notification"
          @size="m"
          @color={{if (badgeIsAccent @isDisabled @hasActiveFilters) "accent" "subdued"}}
          aria-label={{this.badgeLabel}}
        >{{this.badgeCount}}</EuiNotificationBadge>
      {{/if}}
    </EuiButtonEmpty>
  </template>
}

// EuiButtonEmpty puts the icon on the left unless told 'right'
function iconSide(side?: 'left' | 'right'): 'right' | undefined {
  return side === 'left' ? undefined : 'right';
}

function badgeIsAccent(isDisabled?: boolean, hasActiveFilters?: boolean): boolean {
  return !isDisabled && Boolean(hasActiveFilters);
}
