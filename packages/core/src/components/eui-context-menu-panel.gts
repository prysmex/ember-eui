import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { schedule } from '@ember/runloop';

import { modifier } from 'ember-modifier';
import { and } from 'ember-truth-helpers';
import { tabbable } from 'tabbable';

import type Owner from '@ember/owner';

import { randomId } from '../-private/random-id.ts';
import resizeObserver from '../modifiers/resize-observer.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiContextMenuPanelStyles,
  euiContextMenuPanelTitleStyles
} from '../utils/eui/styles.generated.ts';
import EuiButtonIcon from './eui-button-icon.gts';

import type EuiI18n from '../services/eui-i18n.ts';

type TransitionType = 'in' | 'out';
type TransitionDirection = 'next' | 'previous';

const HEADING_RESET = {
  margin: 0,
  fontSize: 'inherit',
  fontWeight: 'inherit',
  lineHeight: 'inherit'
} as const;

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
    /** @deprecated Has no effect: latest EUI has a single title size. */
    size?: 's' | 'm';
    /**
     * @private Set by `EuiContextMenu` for panels of `items`: the list gets
     * `role="menu"` (labelled by the title), as upstream.
     */
    isMenu?: boolean;
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
  @service declare euiI18n: EuiI18n;

  @tracked focusedItemIndex?: number;

  titleId = randomId();

  constructor(owner: Owner, args: EuiContextMenuPanelSignature['Args']) {
    super(owner, args);
    // only the starting point: moving with the keyboard changes it
    this.focusedItemIndex = args.initialFocusedItemIndex;
  }

  panel?: HTMLElement;
  content?: HTMLElement;
  backButton?: HTMLElement;

  /** Upstream panel styles plus the slide animation (none under reduced motion). */
  @cached
  get classes(): string {
    const { transitionType, transitionDirection } = this.args;
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiContextMenuPanelStyles);

    return `euiContextMenuPanel ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiContextMenuPanel,
      transitionType &&
        transitionDirection &&
        styles[transitionDirection][transitionType]
    )}`;
  }

  @cached
  get titleParts(): { title: string; text: string } {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiContextMenuPanelTitleStyles);

    return {
      title: `euiContextMenuPanelTitle euiContextMenuPanel__title ${euiClass(
        context,
        styles.euiContextMenuPanelTitle
      )}`,
      // the heading inherits the title type (React's global reset)
      text: `euiContextMenuPanelTitle__text ${euiClass(context, HEADING_RESET, styles.text)}`
    };
  }

  get backButtonLabel(): string {
    return this.euiI18n.lookupToken(
      'euiContextMenuPanelTitle.ariaLabel',
      'Close current panel:'
    );
  }

  get backButtonId(): string {
    return `${this.titleId}-closeButton`;
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

        // without an animation (no CSS, or reduced motion: 0s), the
        // transition ends at once
        if (transitionType) {
          const { animationName, animationDuration } = getComputedStyle(panel);

          if (
            animationName === 'none' ||
            animationDuration.split(',').every((d) => parseFloat(d) === 0)
          ) {
            this.args.onTransitionComplete?.();
          }
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
        <div class={{this.titleParts.title}} data-test-subj="contextMenuPanelTitle">
          {{#if @onClose}}
            <EuiButtonIcon
              id={{this.backButtonId}}
              @iconType="chevronSingleLeft"
              @color="text"
              aria-label={{this.backButtonLabel}}
              aria-labelledby="{{this.backButtonId}} {{this.titleId}}"
              data-test-subj="contextMenuPanelTitleButton"
              {{on "click" @onClose}}
              {{this.registerBackButton}}
            />
          {{/if}}
          <h2 class={{this.titleParts.text}} id={{this.titleId}}>{{@title}}</h2>
        </div>
      {{/if}}
      <div
        class="euiContextMenuPanel__list"
        role={{if @isMenu "menu"}}
        aria-labelledby={{if (and @isMenu @title) this.titleId}}
        {{this.registerContent}}
      >
        <div {{resizeObserver onResize=this.onResize}}>
          {{yield}}
        </div>
      </div>
    </div>
  </template>
}
