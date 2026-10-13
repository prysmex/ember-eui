import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { concat } from '@ember/helper';
import { hash } from '@ember/helper';
import { action } from '@ember/object';

import { focusTrap } from 'ember-focus-trap';
import { focusTrapFactory } from '../-private/focus-trap-registry.ts';
import { modifier } from 'ember-modifier';
import onKey from 'ember-keyboard/modifiers/on-key';
import { not } from 'ember-truth-helpers';
import { tabbable } from 'tabbable';

import randomId from '../-private/random-id.ts';
import { argOrDefaultDecorator } from '../helpers/arg-or-default.ts';
import resizeObserver from '../modifiers/resize-observer.ts';
import { cascadingMenuKeys } from '../utils/accesibility/index.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiFormVariables,
  logicalCSS
} from '../utils/eui/styles.generated.ts';
import EuiPopover from './eui-popover.gts';

import type { EuiPopoverArgs } from './eui-popover';

/**
 * Upstream `closeOnScroll`: after a 500ms grace period (scroll events fire
 * when the panel is appended), closes on a page scroll of an element that
 * contains the input, ignoring scrolls inside the input or the panel.
 */
const closeOnScrollModifier = modifier(
  (
    _element: HTMLElement,
    [enabled, panel, input, close]: [
      boolean | undefined,
      HTMLElement | null,
      HTMLElement | null,
      (() => void) | undefined
    ]
  ) => {
    if (!enabled || !panel) return;

    const onScroll = (event: Event) => {
      const target = event.target as Node | null;

      if (!input || !target) return;
      if (panel.contains(target) || input.contains(target)) return;
      if (!target.contains(input)) return;

      close?.();
    };
    const timeoutId = setTimeout(() => {
      window.addEventListener('scroll', onScroll, {
        passive: true,
        capture: true
      });
    }, 500);

    return () => {
      window.removeEventListener('scroll', onScroll, { capture: true });
      clearTimeout(timeoutId);
    };
  }
);

export interface EuiInputPopoverArgs
  extends Omit<EuiPopoverArgs, 'button' | 'buttonRef'> {
  /**
   * Lets focus leave the popover; Tab then closes it. Defaults to `false`
   * (Tab cycles through the popover, closing after its last element).
   */
  disableFocusTrap?: boolean;
  /**
   * Closes the popover when the page (or an element containing the input)
   * scrolls. Defaults to `false`.
   */
  closeOnScroll?: boolean;
  /**
   * Stretches the input (and popover) to its container's width. Otherwise
   * the popover is at most the form max width (upstream). Defaults to
   * `false`.
   */
  fullWidth?: boolean;
  /**
   * Minimum width of the panel, when the input is narrower. Defaults to `0`.
   */
  panelMinWidth?: number;
  /** @deprecated Has no effect, use the `<:input>` block. */
  input?: EuiPopoverArgs['button'];
  /** @deprecated Has no effect. */
  inputRef?: EuiPopoverArgs['buttonRef'];
  /** Called with the popover's new width when the input resizes. */
  onPanelResize?: (width?: number) => void;
}

/**
 * A popover attached below an input and as wide as it, e.g. for a custom
 * picker. Takes EuiPopover's args (`@isOpen`, `@closePopover`, …).
 */
export interface EuiInputPopoverSignature {
  Element: HTMLElement;
  Args: EuiInputPopoverArgs;
  Blocks: {
    /** Unused, use `<:input>` and `<:content>`. */
    default: [
      {
        closePopover: () => void;
        isOpen: boolean;
      },
      {
        input: HTMLElement;
        content: HTMLElement;
      }
    ];
    /** The input the popover attaches to; open it on focus or typing. */
    input: [];
    /** The popover's content, as wide as the input. */
    content: [];
  };
}

export default class EuiInputPopoverComponent extends Component<EuiInputPopoverSignature> {
  // Defaults
  @argOrDefaultDecorator('downLeft') anchorPosition!: EuiPopoverArgs['anchorPosition'];
  @argOrDefaultDecorator(true) attachToAnchor!: boolean;
  @argOrDefaultDecorator('block') display!: EuiPopoverArgs['display'];
  @argOrDefaultDecorator('s') panelPaddingSize!: EuiPopoverArgs['panelPaddingSize'];
  @argOrDefaultDecorator(false) fullWidth!: boolean;
  @argOrDefaultDecorator(false) disableFocusTrap!: boolean;
  @argOrDefaultDecorator(2) offset!: number;
  @argOrDefaultDecorator(false) repositionToCrossAxis!: boolean;

  /** Upstream: `max-width` of the form controls unless `@fullWidth`. */
  @cached
  get rootCss(): string | undefined {
    if (this.fullWidth) return undefined;

    const context = getEuiThemeContext(this);
    const { maxWidth } = useEuiBorealisStyles(context, euiFormVariables);

    return `${logicalCSS('max-width', maxWidth)};label:EuiInputPopover;`;
  }

  //State
  @tracked panel: HTMLElement | null = null;
  @tracked input: HTMLElement | null = null;
  @tracked inputWidth!: number;
  ///

  @action
  didInsertPanel(panel: HTMLElement | null): void {
    this.panel = panel;
    this.setPanelWidth();
  }

  @action
  didInsertInput(input: HTMLElement): void {
    this.input = input;
    this.onResize();
  }

  @action
  setPanelWidth(width?: number): void {
    const { panel, inputWidth } = this;
    const inputOrWidth = width || inputWidth;
    const minWidth = this.args.panelMinWidth ?? 0;
    // upstream: the input's width, at least `@panelMinWidth`
    const newWidth =
      inputOrWidth && inputOrWidth < minWidth ? minWidth : inputOrWidth;

    if (panel && !!newWidth) {
      panel.style.inlineSize = `${newWidth}px`;
      this.args.onPanelResize?.(newWidth);
    }
  }

  @action
  onResize(): void {
    const { input } = this;

    if (input) {
      const width = input.getBoundingClientRect().width;

      this.inputWidth = width;
      this.setPanelWidth(width);
    }
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    const { panel } = this;

    if (panel && event.key === cascadingMenuKeys.TAB) {
      const tabbableItems = tabbable(panel).filter(
        (el: HTMLElement | SVGElement) => {
          return (
            Array.from(el.attributes)
              .map((el) => el.name)
              .indexOf('data-focus-guard') < 0
          );
        }
      );

      if (
        this.args.disableFocusTrap ||
        (tabbableItems.length &&
          tabbableItems[tabbableItems.length - 1] === document.activeElement)
      ) {
        this.args.closePopover?.();
      }
    }
  }

  willDestroy(): void {
    super.willDestroy();

    this.panel = null;
    this.input = null;
  }

  <template>
    {{#let (randomId) as |id|}}
      <EuiPopover
        class="euiInputPopover"
        @rootCss={{this.rootCss}}
        @css={{@css}}
        @panelCss={{@panelCss}}
        @offset={{this.offset}}
        @repositionToCrossAxis={{this.repositionToCrossAxis}}
        @ownFocus={{false}}
        @initialFocus={{@initialFocus}}
        @buttonRef={{this.didInsertInput}}
        @panelRef={{this.didInsertPanel}}
        @anchorPosition={{this.anchorPosition}}
        @panelPaddingSize={{this.panelPaddingSize}}
        @attachToAnchor={{this.attachToAnchor}}
        @display={{this.display}}
        @closePopover={{@closePopover}}
        @isOpen={{@isOpen}}
        @repositionOnScroll={{@repositionOnScroll}}
        @panelClassName={{@panelClassName}}
        @panelStyle={{@panelStyle}}
        @anchorClassName={{@anchorClassName}}
        @zIndex={{@zIndex}}
        @container={{@container}}
        @buffer={{@buffer}}
        @insert={{@insert}}
        @hasArrow={{@hasArrow}}
        @popoverScreenReaderText={{@popoverScreenReaderText}}
        @ariaLabel={{@ariaLabel}}
        @ariaLabelledBy={{@ariaLabelledBy}}
        @popoverRef={{@popoverRef}}
        @portalRef={{@portalRef}}
        @onTrapDeactivation={{@onTrapDeactivation}}
        @shouldAccountForOtherPopovers={{@shouldAccountForOtherPopovers}}
        ...attributes
      >
        <:button>
          <div {{resizeObserver onResize=this.onResize}}>
            {{yield to="input"}}
          </div>
        </:button>
        <:content>
          <div
            id={{id}}
            {{onKey "_all" this.onKeyDown}}
            {{closeOnScrollModifier
              @closeOnScroll
              this.panel
              this.input
              @closePopover
            }}
            {{focusTrap
          _createFocusTrap=focusTrapFactory
              isActive=(not this.disableFocusTrap)
              focusTrapOptions=(hash
                clickOutsideDeactivates=true
                returnFocusOnDeactivate=false
                fallbackFocus=(concat "#" id)
              )
            }}
          >
            {{yield to="content"}}
          </div>
        </:content>
      </EuiPopover>
    {{/let}}
  </template>
}
