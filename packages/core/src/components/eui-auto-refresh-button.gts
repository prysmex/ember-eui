import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { prettyInterval } from './eui-super-date-picker/utils/pretty-interval.ts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiPopover from './eui-popover.gts';
import EuiRefreshInterval from './eui-refresh-interval.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiButtonEmptySignature } from './eui-button-empty.gts';
import type { EuiRefreshIntervalSignature } from './eui-refresh-interval.gts';

type OnRefreshChange = NonNullable<
  EuiRefreshIntervalSignature['Args']['onRefreshChange']
>;

/**
 * A button showing the auto refresh state ("Auto refresh is off", "5 minutes")
 * that opens a popover with `EuiRefreshInterval` to change it. Upstream's
 * `EuiAutoRefreshButton`; for a text input look-alike use `EuiAutoRefresh`.
 */
export interface EuiAutoRefreshButtonSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    /** Whether refreshing is paused. Defaults to `true`. */
    isPaused?: boolean;
    /** The interval in milliseconds. Defaults to `1000`. */
    refreshInterval?: number;
    /** The smallest allowed interval in milliseconds. Defaults to `0`. */
    minInterval?: number;
    /**
     * By default the unit is rounded up to the next largest one (90 seconds
     * becomes 2 minutes). Pass `'s'`, `'m'` or `'h'` to fix it.
     */
    intervalUnits?: 's' | 'm' | 'h';
    /**
     * Called with `{ isPaused, refreshInterval, intervalUnits }` when the user
     * changes the refresh settings.
     */
    onRefreshChange: OnRefreshChange;
    /**
     * Disables the button. It stays focusable (`aria-disabled`) so that its
     * tooltip still shows, unless `@hasAriaDisabled={{false}}`.
     */
    isDisabled?: boolean;
    /**
     * With `@isDisabled`, renders `aria-disabled="true"` instead of the
     * native `disabled` attribute. Defaults to `@isDisabled` (upstream).
     */
    hasAriaDisabled?: boolean;
    /** Reduces the time unit to a single letter. Defaults to `false`. */
    shortHand?: boolean;
    /** `EuiButtonEmpty` color. Defaults to `'text'`. */
    color?: EuiButtonEmptySignature['Args']['color'];
    /** `EuiButtonEmpty` size. Defaults to `'s'`. */
    size?: EuiButtonEmptySignature['Args']['size'];
    /** `EuiButtonEmpty` flush. */
    flush?: EuiButtonEmptySignature['Args']['flush'];
    /** Shows the loading spinner and disables the button. */
    isLoading?: boolean;
    /** Extra styles composed last into the button's class. */
    css?: EuiCss;
  };
}

export default class EuiAutoRefreshButton extends Component<EuiAutoRefreshButtonSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isOpen = false;

  get isPaused(): boolean {
    return this.args.isPaused ?? true;
  }

  get refreshInterval(): number {
    return this.args.refreshInterval ?? 1000;
  }

  /** Upstream passes `hasAriaDisabled={isDisabled}` before the rest props. */
  get hasAriaDisabled(): boolean {
    return this.args.hasAriaDisabled ?? Boolean(this.args.isDisabled);
  }

  get label(): string {
    return prettyInterval(this.euiI18n, this.isPaused, this.refreshInterval, {
      shortHand: this.args.shortHand ?? false,
      unit: this.args.intervalUnits
    });
  }

  /** The tooltip and popover screen reader text. */
  get statusLabel(): string {
    if (this.isPaused) {
      return this.euiI18n.lookupToken(
        'euiAutoRefresh.buttonLabelOff',
        'Auto refresh is off'
      );
    }

    return this.euiI18n.lookupToken(
      'euiAutoRefresh.buttonLabelOn',
      'Auto refresh is on and set to {prettyInterval}',
      {
        prettyInterval: prettyInterval(
          this.euiI18n,
          this.isPaused,
          this.refreshInterval,
          { unit: this.args.intervalUnits }
        )
      }
    );
  }

  @action
  toggle(): void {
    this.isOpen = !this.isOpen;
  }

  @action
  close(): void {
    this.isOpen = false;
  }

  <template>
    <EuiPopover
      class="euiAutoRefreshButtonPopover"
      @isOpen={{this.isOpen}}
      @closePopover={{this.close}}
      @popoverScreenReaderText={{this.statusLabel}}
    >
      <:button>
        <EuiToolTip @content={{this.statusLabel}}>
          <EuiButtonEmpty
            class="euiAutoRefreshButton"
            @iconType="refreshTime"
            @size={{if @size @size "s"}}
            @color={{if @color @color "text"}}
            @flush={{@flush}}
            @isLoading={{@isLoading}}
            @isDisabled={{@isDisabled}}
            @hasAriaDisabled={{this.hasAriaDisabled}}
            @css={{@css}}
            {{on "click" this.toggle}}
            ...attributes
          >{{this.label}}</EuiButtonEmpty>
        </EuiToolTip>
      </:button>
      <:content>
        <EuiRefreshInterval
          @isPaused={{this.isPaused}}
          @refreshInterval={{this.refreshInterval}}
          @minInterval={{@minInterval}}
          @intervalUnits={{@intervalUnits}}
          @onRefreshChange={{@onRefreshChange}}
        />
      </:content>
    </EuiPopover>
  </template>
}
