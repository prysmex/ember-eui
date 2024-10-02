import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { get } from '@ember/helper';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { inject as service } from '@ember/service';

import optional from 'ember-composable-helpers/helpers/optional';
import queue from 'ember-composable-helpers/helpers/queue';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import Timer from '../utils/timer.ts';
import EuiToast from './eui-toast.gts';

import type EuiToasterService from '../services/eui-toaster';
import type {
  EuiToastProps,
  EuiToastPropsWithId
} from '../services/eui-toaster';
import type { sideMapping } from '../utils/css-mappings/eui-global-toast-list.ts';

type EuiToastSide = keyof typeof sideMapping;

type GlobalToastListArgs = {
  dismissToast?: (this: EuiGlobalToastList, toast: EuiToastProps) => void;
  toastLifeTimeMs: number;

  /*
    Determines which side of the browser window the toasts should appear
    Default: 'right'

  */
  side?: EuiToastSide;
};

const TOAST_FADE_OUT_MS = 250;

export interface EuiGlobalToastListItemSignature {
  Element: HTMLDivElement;
  Args: GlobalToastListArgs;
}

export default class EuiGlobalToastList extends Component<EuiGlobalToastListItemSignature> {
  @service declare euiToaster: EuiToasterService;

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

  startScrollingToBottom(): void {
    this.isScrollingToBottom = true;

    const scrollToBottom = () => {
      // Although we cancel the requestAnimationFrame in componentWillUnmount,
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
    this.scheduleToastForDismissal(toast);

    if (!this.isUserInteracting) {
      // If the user has scrolled up the toast list then we don't want to annoy them by scrolling
      // all the way back to the bottom.
      if (this.isScrolledToBottom) {
        this.startScrollingToBottom();
      }
    }
  }

  @action
  onMouseEnter(): void {
    // Stop scrolling to bottom if we're in mid-scroll, because the user wants to interact with
    // the list.
    this.isScrollingToBottom = false;
    this.isUserInteracting = true;

    // Don't let toasts dismiss themselves while the user is interacting with them.
    for (const toastId in this.toastIdToTimerMap) {
      if (this.toastIdToTimerMap.hasOwnProperty(toastId)) {
        const timer = this.toastIdToTimerMap[toastId];

        timer?.pause();
      }
    }
  }

  @action
  onMouseLeave(): void {
    this.isUserInteracting = false;

    for (const toastId in this.toastIdToTimerMap) {
      if (this.toastIdToTimerMap.hasOwnProperty(toastId)) {
        const timer = this.toastIdToTimerMap[toastId];

        timer?.resume();
      }
    }
  }

  @action
  onScroll(): void {
    if (this.listElement) {
      this.isScrolledToBottom =
        this.listElement.scrollHeight - this.listElement.scrollTop ===
        this.listElement.clientHeight;
    }
  }

  scheduleAllToastsForDismissal(): void {
    this.euiToaster.toasts.forEach((toast) => {
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
      toast.toastLifeTimeMs != null
        ? toast.toastLifeTimeMs
        : this.args.toastLifeTimeMs
    );
  }

  @action
  dismissToast(toast: EuiToastPropsWithId): void {
    // Remove the toast after it's done fading out.
    this.dismissTimeoutIds.push(
      window.setTimeout(() => {
        // Because this is wrapped in a setTimeout, and because React does not guarantee when
        // state updates happen, it is possible to double-dismiss a toast
        // including by double-clicking the "x" button on the toast
        // so, first check to make sure we haven't already dismissed this toast
        if (this.toastIdToTimerMap.hasOwnProperty(toast.id)) {
          if (this.args.dismissToast) {
            this.args.dismissToast.apply(this, [toast]);
          }

          this.toastIdToTimerMap[toast.id]!.clear();
          delete this.toastIdToTimerMap[toast.id];

          delete this.toastIdToDismissedMap[toast.id];
          this.toastIdToDismissedMap = {
            ...this.toastIdToDismissedMap
          };
          this.euiToaster.remove(toast);
        }
      }, TOAST_FADE_OUT_MS)
    );

    this.toastIdToDismissedMap = {
      ...this.toastIdToDismissedMap,
      [toast.id]: true
    };
  }

  constructor(owner: unknown, args: GlobalToastListArgs) {
    super(owner, args);
    this.scheduleAllToastsForDismissal();
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
      if (this.toastIdToTimerMap.hasOwnProperty(toastId)) {
        const timer = this.toastIdToTimerMap[toastId];

        timer?.clear();
      }
    }
  }

  <template>
    <div
      aria-live="polite"
      role="region"
      class={{classNames
        componentName="EuiGlobalToastList"
        side=(argOrDefault @side "right")
      }}
      style={{unless this.euiToaster.toasts.length "padding:0px;"}}
      {{didInsert this.didInsert}}
      {{on "scroll" this.onScroll}}
      {{on "mouseenter" this.onMouseEnter}}
      {{on "mouseleave" this.onMouseLeave}}
      ...attributes
    >
      {{#each this.euiToaster.toasts as |toast|}}
        <EuiToast
          class={{classNames
            "euiGlobalToastListItem"
            (if
              (get this.toastIdToDismissedMap toast.id)
              "euiGlobalToastListItem-isDismissed"
            )
          }}
          @title={{toast.title}}
          @useMarkdownFormat={{toast.useMarkdownFormat}}
          @body={{toast.body}}
          @color={{toast.color}}
          @iconType={{toast.iconType}}
          @onClose={{queue
            (fn this.dismissToast toast)
            (optional toast.onClose)
          }}
          {{didInsert (fn this.didInsertToast toast)}}
          {{on "focus" this.onMouseEnter}}
          {{on "blur" this.onMouseLeave}}
        />
      {{/each}}
    </div>
  </template>
}
