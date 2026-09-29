import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { schedule } from '@ember/runloop';

import { modifier } from 'ember-modifier';
import { tabbable } from 'tabbable';

import type Owner from '@ember/owner';

import resizeObserver from '../modifiers/resize-observer.ts';
import EuiIcon from './eui-icon.gts';

type TransitionType = 'in' | 'out';
type TransitionDirection = 'next' | 'previous';

const TRANSITIONS: Record<TransitionDirection, Record<TransitionType, string>> = {
  next: { in: 'euiContextMenuPanel-txInLeft', out: 'euiContextMenuPanel-txOutLeft' },
  previous: { in: 'euiContextMenuPanel-txInRight', out: 'euiContextMenuPanel-txOutRight' }
};

/**
 * A list of `EuiContextMenuItem`s, usually as a popover's content, with
 * an optional title. Arrow keys move between the items. For menus with
 * several panels (items opening sub-menus), use `EuiContextMenu`, which
 * renders these panels for you.
 */
export interface EuiContextMenuPanelSignature {
  Element: HTMLDivElement;
  Args: {
    /** Title above the items. */
    title?: string;
    /**
     * Makes the title a "back" button calling this function, e.g. to
     * return to the previous panel.
     */
    onClose?: () => void;
    /** `'s'` for a smaller title. Defaults to `'m'`. */
    size?: 's' | 'm';
    /**
     * Moves focus into the panel once rendered: to the item at
     * `@initialFocusedItemIndex`, else to its first focusable element when
     * it has no items, else to the panel itself.
     */
    hasFocus?: boolean;
    /** Index of the item to focus with `@hasFocus`; `-1` focuses the panel. */
    initialFocusedItemIndex?: number;
    /** @private Slide animation, set by `EuiContextMenu`. */
    transitionType?: TransitionType;
    /** @private Slide direction, set by `EuiContextMenu`. */
    transitionDirection?: TransitionDirection;
    /** @private Called when the slide animation ends. */
    onTransitionComplete?: () => void;
    /** @private Called with the panel's height when it changes. */
    onHeightChange?: (height: number) => void;
    /** @private Arrow right on an item: opens its panel. */
    showNextPanel?: (itemIndex?: number) => void;
    /** @private Arrow left: back to the previous panel. */
    showPreviousPanel?: () => void;
    /** @private Called once the keyboard is used to move around. */
    onUseKeyboardToNavigate?: () => void;
  };
  Blocks: {
    /** The `EuiContextMenuItem`s (and e.g. `EuiHorizontalRule`s), or any content. */
    default: [];
  };
}

export default class EuiContextMenuPanel extends Component<EuiContextMenuPanelSignature> {
  @tracked focusedItemIndex?: number;

  constructor(owner: Owner, args: EuiContextMenuPanelSignature['Args']) {
    super(owner, args);
    // only the starting point: moving with the keyboard changes it
    this.focusedItemIndex = args.initialFocusedItemIndex;
  }

  panel?: HTMLElement;
  content?: HTMLElement;
  backButton?: HTMLElement;

  get classes(): string {
    const { transitionType, transitionDirection } = this.args;
    const transition =
      transitionType && transitionDirection
        ? TRANSITIONS[transitionDirection][transitionType]
        : undefined;

    return ['euiContextMenuPanel', transition].filter(Boolean).join(' ');
  }

  get titleClasses(): string {
    return this.args.size === 's'
      ? 'euiContextMenuPanelTitle euiContextMenuPanelTitle--small'
      : 'euiContextMenuPanelTitle';
  }

  /** The panel's own menu items (not those of a nested panel). */
  get menuItems(): HTMLElement[] {
    if (!this.content) return [];

    return Array.from(
      this.content.querySelectorAll<HTMLElement>('.euiContextMenuItem')
    ).filter((item) => item.closest('.euiContextMenuPanel') === this.panel);
  }

  focusItem(index: number): void {
    this.focusedItemIndex = index;
    this.menuItems[index]?.focus();
  }

  moveFocus(amount: number): void {
    const items = this.menuItems;
    const count = items.length;
    // start from the focused item (e.g. focused by the popover on open)
    const focused = items.indexOf(document.activeElement as HTMLElement);
    const current = focused !== -1 ? focused : this.focusedItemIndex;

    // starting to use the keyboard: the first or the last item
    const next =
      current === undefined || current < 0
        ? amount < 0
          ? count - 1
          : 0
        : (current + amount + count) % count;

    this.focusItem(next);
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    const items = this.menuItems;
    const active = document.activeElement;

    // with items, arrow left always goes back; otherwise only from the
    // title or the panel, as the content (e.g. a text field) may need it
    if (items.length || active === this.backButton || active === this.panel) {
      if (event.key === 'ArrowLeft' && this.args.showPreviousPanel) {
        event.preventDefault();
        event.stopPropagation();
        this.args.showPreviousPanel();
        this.args.onUseKeyboardToNavigate?.();

        return;
      }
    }

    if (!items.length) return;

    switch (event.key) {
      case 'Tab': {
        const index = items.indexOf(active as HTMLElement);

        this.focusedItemIndex = index >= 0 ? index : undefined;
        break;
      }
      case 'ArrowUp':
        event.preventDefault();
        this.moveFocus(-1);
        this.args.onUseKeyboardToNavigate?.();
        break;
      case 'ArrowDown':
        event.preventDefault();
        this.moveFocus(1);
        this.args.onUseKeyboardToNavigate?.();
        break;
      case 'ArrowRight':
        if (this.args.showNextPanel) {
          event.preventDefault();
          this.args.showNextPanel(this.focusedItemIndex);
          this.args.onUseKeyboardToNavigate?.();
        }
        break;
    }
  }

  @action
  onAnimationEnd(event: AnimationEvent): void {
    if (event.target === this.panel) this.args.onTransitionComplete?.();
  }

  @action
  onResize({ height }: { height: number }): void {
    this.reportHeight(height);
  }

  // the menu sizes itself from this, so report it after rendering
  reportHeight(height: number): void {
    schedule('afterRender', () => this.args.onHeightChange?.(height));
  }

  /** Registers the elements, and handles focus and transitions once rendered. */
  setup = modifier(
    (
      panel: HTMLElement,
      [hasFocus, transitionType]: [boolean | undefined, TransitionType | undefined]
    ) => {
      this.panel = panel;
      this.reportHeight(panel.clientHeight);

      schedule('afterRender', () => {
        if (!panel.isConnected) return;

        // without an animation (e.g. no CSS), the transition ends at once
        if (transitionType && getComputedStyle(panel).animationName === 'none') {
          this.args.onTransitionComplete?.();
        }

        if (!hasFocus) {
          if (panel.contains(document.activeElement)) {
            (document.activeElement as HTMLElement).blur();
          }

          return;
        }

        // focusing while sliding makes the animation glitch
        if (transitionType) return;

        this.updateFocus(panel);
      });
    }
  );

  updateFocus(panel: HTMLElement): void {
    const items = this.menuItems;

    if (this.focusedItemIndex === -1) {
      panel.focus();

      return;
    }

    if (!items.length) {
      if (panel.contains(document.activeElement)) return;

      const [first] = this.content ? tabbable(this.content) : [];

      if (first) first.focus();
      else panel.focus();

      return;
    }

    if (this.focusedItemIndex !== undefined && items[this.focusedItemIndex]) {
      items[this.focusedItemIndex]!.focus();

      return;
    }

    if (!panel.contains(document.activeElement)) panel.focus();
  }

  registerContent = modifier((element: HTMLElement) => {
    this.content = element;
  });

  registerBackButton = modifier((element: HTMLElement) => {
    this.backButton = element;
  });

  <template>
    <div
      class={{this.classes}}
      tabindex="-1"
      {{this.setup @hasFocus @transitionType}}
      {{on "keydown" this.onKeyDown}}
      {{on "animationend" this.onAnimationEnd}}
      ...attributes
    >
      {{#if @title}}
        {{#if @onClose}}
          <button
            class={{this.titleClasses}}
            type="button"
            data-test-subj="contextMenuPanelTitleButton"
            {{on "click" @onClose}}
            {{this.registerBackButton}}
          >
            <span class="euiContextMenu__itemLayout">
              <EuiIcon
                @type="arrowLeft"
                @size="m"
                class="euiContextMenu__icon"
              />
              <span class="euiContextMenu__text">{{@title}}</span>
            </span>
          </button>
        {{else}}
          <div class={{this.titleClasses}}>
            <span class="euiContextMenu__itemLayout">{{@title}}</span>
          </div>
        {{/if}}
      {{/if}}
      <div {{this.registerContent}}>
        <div {{resizeObserver onResize=this.onResize}}>
          {{yield}}
        </div>
      </div>
    </div>
  </template>
}
