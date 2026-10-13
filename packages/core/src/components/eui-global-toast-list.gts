import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { service } from '@ember/service';
import type Owner from '@ember/owner';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiGlobalToastListItemStyles,
  euiGlobalToastListStyles
} from '../utils/eui/styles.generated.ts';
import Timer from '../utils/timer.ts';
import EuiButton from './eui-button.gts';
import EuiNotificationBadge from './eui-notification-badge.gts';
import EuiToast from './eui-toast.gts';

import type EuiI18n from '../services/eui-i18n';
import type EuiToasterService from '../services/eui-toaster';
import type {
  EuiToastProps,
  EuiToastPropsWithId
} from '../services/eui-toaster';
import type { EuiCss } from '../utils/eui/styles.ts';

export type EuiToastSide = 'left' | 'right';

/** One entry of `@toasts` (upstream `Toast`): EuiToast's args plus an id. */
export interface EuiGlobalToast extends EuiToastProps {
  /** Unique id of the toast. */
  id: string;
}

type GlobalToastListArgs = {
  /**
   * The toasts to show, as data (upstream's `toasts`). Without it, the list
   * shows the toasts of the `euiToaster` service. The list never changes
   * this array: remove a toast from it in `@dismissToast`.
   */
  toasts?: EuiGlobalToast[];
  /**
   * Called when a toast is dismissed (its close button or its time ran
   * out, after the fade out). With `@toasts`, remove the toast from the
   * array here; without it, the toast is then removed from the `euiToaster`
   * service. "Clear all" calls it for every toast.
   */
  dismissToast?: (this: EuiGlobalToastList, toast: EuiToastProps) => void;
  /**
   * How long toasts stay, in ms, unless a toast sets its own
   * `toastLifeTimeMs`. Hovering or focusing the list pauses the timers.
   * Each toast's highlight bar counts this time down.
   */
  toastLifeTimeMs: number;
  /**
   * Which side of the browser window the toasts appear on: `'right'` or
   * `'left'`. Below the `m` breakpoint the list spans the window.
   * Defaults to `'right'`.
   */
  side?: EuiToastSide;
  /**
   * Shows a "Clear all" button once there are at least this many toasts;
   * `0` (or `false`) hides it. Defaults to `3`.
   */
  showClearAllButtonAt?: number | false;
  /** Called after "Clear all" dismissed every toast. */
  onClearAllToasts?: () => void;
  /** Shows a badge with the number of toasts. Defaults to `false`. */
  showNotificationBadge?: boolean;
};

/** Upstream `TOAST_FADE_OUT_MS`. */
export const TOAST_FADE_OUT_MS = 250;
/** Upstream `CLEAR_ALL_TOASTS_THRESHOLD_DEFAULT`. */
export const CLEAR_ALL_TOASTS_THRESHOLD_DEFAULT = 3;

/**
 * Renders the toasts of the `euiToaster` service. Place it once in the
 * application template, then show toasts from anywhere:
 * `this.euiToaster.show({ title: 'Saved', color: 'success' })`.
 */
export interface EuiGlobalToastListItemSignature {
  Element: HTMLDivElement;
  Args: GlobalToastListArgs;
}

/** Native Ember toast list on the upstream EUI 123 / Borealis factories. */
export default class EuiGlobalToastList extends Component<EuiGlobalToastListItemSignature> {
  @service declare euiToaster: EuiToasterService;
  @service declare euiI18n: EuiI18n;

  dismissTimeoutIds: number[] = [];
  toastIdToTimerMap: { [toastId: string]: Timer } = {};

  isScrollingToBottom = false;
  isScrolledToBottom = true;
  isUserInteracting = false;

  // See [Return Value](https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame#Return_value)
  // for information on initial value of 0
  isScrollingAnimationFrame = 0;
  startScrollingAnimationFrame = 0;

  listElement: Element | null = null;
  @tracked toastIdToDismissedMap: {
    [toastId: string]: boolean;
  } = {};

  constructor(owner: Owner, args: GlobalToastListArgs) {
    super(owner, args);
    this.scheduleAllToastsForDismissal();
  }

  get context() {
    return getEuiThemeContext(this);
  }

  get side(): EuiToastSide {
    return this.args.side === 'left' ? 'left' : 'right';
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiGlobalToastListStyles);
  }

  @cached
  get itemStyles() {
    return useEuiBorealisStyles(this.context, euiGlobalToastListItemStyles);
  }

  @cached
  get classes(): string {
    return euiClass(
      this.context,
      { boxSizing: 'border-box' },
      this.styles.euiGlobalToastList,
      this.styles[this.side]
    );
  }

  @cached
  get contentClass(): string {
    return euiClass(this.context, this.styles.content);
  }

  /** List item styles composed into each EuiToast's own class (`@css`). */
  @cached
  get itemCss(): EuiCss {
    return this.itemStyles.euiGlobalToastListItem;
  }

  @cached
  get dismissedItemCss(): EuiCss {
    return [this.itemStyles.euiGlobalToastListItem, this.itemStyles.dismissed];
  }

  /** Upstream: the list item styles plus the dismiss button's, on EuiButton. */
  @cached
  get clearAllCss(): EuiCss {
    return [
      this.itemStyles.euiGlobalToastListItem,
      this.styles.euiGlobalToastListDismissButton
    ];
  }

  /** Upstream's `css` on the count EuiNotificationBadge. */
  @cached
  get badgeCss(): EuiCss {
    const badge = this.styles.notificationBadge;
    const toasts = this.toasts;
    const dismissed = this.toastIdToDismissedMap;
    const firstDismissed = toasts[0] ? dismissed[toasts[0].id] : false;
    const allDismissed = toasts.every((toast) => dismissed[toast.id]);
    return [
      badge.notificationBadge,
      (firstDismissed || allDismissed) && badge.hasFadeOut
    ];
  }

  itemCssFor = (id: string): EuiCss =>
    this.toastIdToDismissedMap[id] ? this.dismissedItemCss : this.itemCss;

  lifeTimeFor = (toast: EuiToastPropsWithId): number | undefined =>
    toast.toastLifeTimeMs ?? this.args.toastLifeTimeMs;

  /** `@toasts` when given, else the `euiToaster` service's toasts. */
  get toasts(): EuiToastPropsWithId[] {
    return this.args.toasts ?? this.euiToaster.toasts;
  }

  /** Removes a dismissed toast from the service (`@toasts` belong to the caller). */
  removeToast(toast: EuiToastPropsWithId): void {
    if (!this.args.toasts) this.euiToaster.remove(toast);
  }

  get showClearAll(): boolean {
    const threshold =
      this.args.showClearAllButtonAt ?? CLEAR_ALL_TOASTS_THRESHOLD_DEFAULT;
    const count = this.toasts.length;
    return Boolean(count && threshold && count >= threshold);
  }

  get showBadge(): boolean {
    return Boolean(this.args.showNotificationBadge && this.toasts.length);
  }

  get hasContent(): boolean {
    return this.toasts.length > 0;
  }

  get clearAllLabel(): string {
    return this.euiI18n.lookupToken(
      'euiGlobalToastList.clearAllToastsButtonAriaLabel',
      'Clear all toast notifications'
    );
  }

  get clearAllText(): string {
    return this.euiI18n.lookupToken(
      'euiGlobalToastList.clearAllToastsButtonDisplayText',
      'Clear all'
    );
  }

  startScrollingToBottom(): void {
    this.isScrollingToBottom = true;

    const scrollToBottom = () => {
      // Although we cancel the requestAnimationFrame in willDestroy,
      // it's possible for this.listElement to become null in the meantime
      if (!this.listElement) {
        return;
      }

      const position = this.listElement.scrollTop;
      const destination =
        this.listElement.scrollHeight - this.listElement.clientHeight;
      const distanceToDestination = destination - position;

      if (distanceToDestination < 5) {
        this.listElement.scrollTop = destination;
        this.isScrollingToBottom = false;
        this.isScrolledToBottom = true;

        return;
      }

      this.listElement.scrollTop = position + distanceToDestination * 0.25;

      if (this.isScrollingToBottom) {
        this.isScrollingAnimationFrame =
          window.requestAnimationFrame(scrollToBottom);
      }
    };

    this.startScrollingAnimationFrame =
      window.requestAnimationFrame(scrollToBottom);
  }

  @action
  didInsertToast(toast: EuiToastPropsWithId): void {
    // Toasts present at construction are already scheduled.
    if (!this.toastIdToTimerMap[toast.id]) {
      this.scheduleToastForDismissal(toast);
    }

    // If the user has scrolled up the toast list then we don't want to annoy
    // them by scrolling all the way back to the bottom.
    if (!this.isUserInteracting && this.isScrolledToBottom) {
      this.startScrollingToBottom();
    }
  }

  isHovered = false;
  isFocused = false;

  @action
  onMouseEnter(): void {
    this.isHovered = true;
    this.pauseTimers();
  }

  @action
  onMouseLeave(): void {
    this.isHovered = false;
    this.resumeTimers();
  }

  @action
  onFocusIn(): void {
    this.isFocused = true;
    this.pauseTimers();
  }

  @action
  onFocusOut(): void {
    this.isFocused = false;
    this.resumeTimers();
  }

  /**
   * Upstream pauses on mouse enter and on focus inside a toast. Hover and
   * focus are tracked separately so that leaving one (e.g. a focused toast
   * being removed) does not resume the timers while the other still holds.
   */
  pauseTimers(): void {
    // Stop scrolling to bottom if we're in mid-scroll, because the user wants to interact with
    // the list.
    this.isScrollingToBottom = false;
    this.isUserInteracting = true;

    // Don't let toasts dismiss themselves while the user is interacting with them.
    for (const toastId in this.toastIdToTimerMap) {
      if (Object.prototype.hasOwnProperty.call(this.toastIdToTimerMap, toastId)) {
        const timer = this.toastIdToTimerMap[toastId];
        // only running timers (pausing twice would lose time)
        if (timer?.id !== undefined) timer.pause();
      }
    }
  }

  resumeTimers(): void {
    if (this.isHovered || this.isFocused || !this.isUserInteracting) return;
    this.isUserInteracting = false;

    for (const toastId in this.toastIdToTimerMap) {
      if (Object.prototype.hasOwnProperty.call(this.toastIdToTimerMap, toastId)) {
        const timer = this.toastIdToTimerMap[toastId];
        // only paused timers (resuming twice would schedule twice)
        if (timer && timer.id === undefined && timer.timeRemaining !== undefined)
          timer.resume();
      }
    }
  }

  @action
  onScroll(): void {
    // Upstream: only the user's own scrolling decides whether the list stays
    // pinned to the bottom (the list scrolls itself when toasts are added).
    if (this.listElement && this.isUserInteracting) {
      this.isScrolledToBottom =
        this.listElement.scrollHeight - this.listElement.scrollTop ===
        this.listElement.clientHeight;
    }
  }

  scheduleAllToastsForDismissal(): void {
    this.toasts.forEach((toast) => {
      if (!this.toastIdToTimerMap[toast.id]) {
        this.scheduleToastForDismissal(toast);
      }
    });
  }

  @action
  scheduleToastForDismissal(toast: EuiToastPropsWithId): void {
    // Start fading the toast out once its lifetime elapses.
    this.toastIdToTimerMap[toast.id] = new Timer(
      this.dismissToast.bind(this, toast),
      this.lifeTimeFor(toast) as number
    );
  }

  @action
  dismissToast(toast: EuiToastPropsWithId): void {
    // Remove the toast after it's done fading out.
    this.dismissTimeoutIds.push(
      window.setTimeout(() => {
        // It is possible to double-dismiss a toast (e.g. by double-clicking
        // its "x" button): only the first dismissal counts.
        if (Object.prototype.hasOwnProperty.call(this.toastIdToTimerMap, toast.id)) {
          if (this.args.dismissToast) {
            this.args.dismissToast.apply(this, [toast]);
          }

          this.toastIdToTimerMap[toast.id]!.clear();
          delete this.toastIdToTimerMap[toast.id];

          const dismissed = { ...this.toastIdToDismissedMap };
          delete dismissed[toast.id];
          this.toastIdToDismissedMap = dismissed;
          this.removeToast(toast);
        }
      }, TOAST_FADE_OUT_MS)
    );

    this.toastIdToDismissedMap = {
      ...this.toastIdToDismissedMap,
      [toast.id]: true
    };
  }

  /** Upstream "Clear all": dismisses every toast at once (no fade out). */
  @action
  clearAll(): void {
    for (const toast of [...this.toasts]) {
      this.args.dismissToast?.apply(this, [toast]);
      this.toastIdToTimerMap[toast.id]?.clear();
      delete this.toastIdToTimerMap[toast.id];
      this.removeToast(toast);
    }
    this.toastIdToDismissedMap = {};
    this.args.onClearAllToasts?.();
  }

  @action
  closeToast(toast: EuiToastPropsWithId): void {
    this.dismissToast(toast);
    toast.onClose?.();
  }

  @action
  didInsert(element: Element): void {
    this.listElement = element;
  }

  willDestroy(): void {
    super.willDestroy();

    if (this.isScrollingAnimationFrame !== 0) {
      window.cancelAnimationFrame(this.isScrollingAnimationFrame);
    }

    if (this.startScrollingAnimationFrame !== 0) {
      window.cancelAnimationFrame(this.startScrollingAnimationFrame);
    }

    this.dismissTimeoutIds.forEach(clearTimeout);

    for (const toastId in this.toastIdToTimerMap) {
      if (Object.prototype.hasOwnProperty.call(this.toastIdToTimerMap, toastId)) {
        this.toastIdToTimerMap[toastId]?.clear();
      }
    }

    this.listElement = null;
  }

  // No whitespace inside the list: without toasts it must match `:empty`
  // (upstream's padding rules).
  <template>
    <div
      aria-live="polite"
      role="log"
      class="euiGlobalToastList {{this.classes}}"
      {{didInsert this.didInsert}}
      {{on "scroll" this.onScroll}}
      {{on "mouseenter" this.onMouseEnter}}
      {{on "mouseleave" this.onMouseLeave}}
      ...attributes
    >{{#if this.hasContent~}}
        <div class={{this.contentClass}}>
          {{#if this.showBadge}}
            <EuiNotificationBadge
              class="euiGlobalToastList__countBadge"
              data-test-subj="euiGlobalToastListNotificationBadge"
              @size="m"
              @color="subdued"
              @css={{this.badgeCss}}
            >{{this.toasts.length}}</EuiNotificationBadge>
          {{/if}}
          {{#each this.toasts key="id" as |toast|}}
            <EuiToast
              class="euiGlobalToastListItem"
              @css={{this.itemCssFor toast.id}}
              @animationMs={{this.lifeTimeFor toast}}
              @title={{toast.title}}
              @useMarkdownFormat={{toast.useMarkdownFormat}}
              @body={{toast.body}}
              @text={{toast.text}}
              @color={{toast.color}}
              @iconType={{toast.iconType}}
              @actionProps={{toast.actionProps}}
              @onClose={{fn this.closeToast toast}}
              {{didInsert (fn this.didInsertToast toast)}}
              {{on "focusin" this.onFocusIn}}
              {{on "focusout" this.onFocusOut}}
            />
          {{/each}}
          {{#if this.showClearAll}}
            <EuiButton
              class="euiGlobalToastListItem"
              @fullWidth={{true}}
              @size="s"
              @color="text"
              @css={{this.clearAllCss}}
              aria-label={{this.clearAllLabel}}
              data-test-subj="euiClearAllToastsButton"
              {{on "click" this.clearAll}}
            >{{this.clearAllText}}</EuiButton>
          {{/if}}
        </div>
      {{~/if}}</div>
  </template>
}
