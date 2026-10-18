import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { guidFor } from '@ember/object/internals';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';
import type Owner from '@ember/owner';

import { modifier } from 'ember-modifier';
import { and, eq, not } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiAccordionArrowStyles,
  euiAccordionButtonStyles,
  euiAccordionChildrenStyles,
  euiAccordionChildWrapperStyles,
  euiAccordionStyles
} from '../utils/eui/styles.generated.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiText from './eui-text.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { CommonArgs } from './common.ts';

export type EuiAccordionPaddingSize = 'none' | 'xs' | 's' | 'm' | 'l' | 'xl';
export type EuiAccordionBorders = 'none' | 'horizontal' | 'all';
type TriggerElement = 'div' | 'legend' | 'button';

/** Upstream's flex row holding the arrow, trigger and extra action. */
const TRIGGER_WRAPPER = {
  display: 'flex',
  alignItems: 'center',
  label: 'EuiAccordionTrigger'
} as const;
const OPTIONAL_ACTION = { flexShrink: 0, label: 'optionalAction' } as const;

/**
 * Scoped equivalent of React's global button reset (the trigger is a native
 * `<button>`/`<legend>`); upstream's button styles come after it and win.
 */
const TRIGGER_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  border: 'none',
  background: 'none',
  color: 'inherit',
  font: 'inherit'
} as const;

/**
 * Measures the children's layout height (unaffected by CSS transforms) and
 * reports it after layout, like upstream's `EuiResizeObserver` (rounded).
 *
 * One ResizeObserver serves every accordion on the page, not one each. Each
 * observer's callback runs on its own, and the tracked height it sets
 * schedules a render of its own: a form with a hundred section rows
 * re-rendered a hundred times as it mounted. One observer reports every
 * accordion in a single callback, so the heights land in one render.
 */
const heightCallbacks = new WeakMap<Element, () => void>();
let heightObserver: ResizeObserver | undefined;

const observeHeight = modifier(
  (element: HTMLElement, [onResize]: [(height: number) => void]) => {
    if (typeof ResizeObserver === 'undefined') {
      onResize(element.offsetHeight);
      return;
    }
    heightObserver ??= new ResizeObserver((entries) => {
      for (const entry of entries) heightCallbacks.get(entry.target)?.();
    });
    heightCallbacks.set(element, () =>
      onResize(Math.round(element.offsetHeight))
    );
    heightObserver.observe(element);
    return () => {
      heightCallbacks.delete(element);
      heightObserver?.unobserve(element);
    };
  }
);

/** Upstream's one-way `hasTransition` state (an untracked flag). */
function enableTransition(state: { enabled: boolean }): void {
  state.enabled = true;
}

type AccordionArgs = {
  /**
   * Id of the collapsible content region; the trigger's `aria-controls`
   * points to it. Defaults to a generated id.
   */
  id?: string;
  /**
   * Element wrapping the accordion. With `'fieldset'` the trigger renders as
   * a `<legend>`, for accordions that group form controls.
   * Defaults to `'div'`.
   */
  element?: 'div' | 'fieldset';
  /**
   * ARIA role of the content region. Defaults to `'group'` (upstream);
   * pass `'region'` for landmark-worthy sections.
   */
  role?: string;
  /** Class that will apply to the trigger for the accordion. */
  buttonClassName?: string;
  /**
   * Extra props for the trigger: `id` (defaults to a generated id),
   * `className`, `data-test-subj`, `paddingSize` (`'s'`, `'m'` or `'l'`)
   * to pad the trigger (not on the arrow's side), and `css`: extra styles
   * composed last into the trigger's class (upstream `buttonProps.css`).
   */
  buttonProps?: CommonArgs & { paddingSize?: 's' | 'm' | 'l'; css?: EuiCss };
  /**
   * Element of the trigger: `'button'` (default) or `'div'`, e.g. when the
   * trigger content holds interactive elements. A non-button trigger makes
   * the arrow the focusable control. Always `'legend'` when
   * `@element="fieldset"`.
   */
  buttonElement?: TriggerElement;
  /** Extra props for the arrow's EuiButtonIcon: `className` and `css`. */
  arrowProps?: {
    className?: string;
    css?: EuiCss;
  };
  /** Class that will apply to the trigger content for the accordion. */
  buttonContentClassName?: string;
  /**
   * Text content of the trigger. Use the `<:buttonContent>` block for
   * markup; the block wins when both are given.
   */
  buttonContent?: string;
  /**
   * Set to `true` to render the `<:extraAction>` block, right aligned next
   * to the trigger (e.g. a delete button). The block is ignored without it.
   */
  extraAction?: boolean;
  /** The accordion will start in the open state. Defaults to `false`. */
  initialIsOpen?: boolean;
  /**
   * Called with the new open state (`true` = open) when the trigger or arrow
   * is clicked. With `@forceState`, use it to update the state you control.
   */
  onToggle?: (isOpen: boolean) => void;
  /**
   * Padding around the content: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or
   * `'xl'`. Defaults to `'none'`.
   */
  paddingSize?: EuiAccordionPaddingSize;
  /**
   * Borders around the accordion: `'none'`, `'horizontal'` (top and bottom)
   * or `'all'`. Adjacent bordered accordions share one border.
   * Defaults to `'none'`.
   */
  borders?: EuiAccordionBorders;
  /**
   * Placement of the arrow indicator, or `'none'` to hide it (only possible
   * when the trigger is a button). Defaults to `'left'`.
   */
  arrowDisplay?: 'left' | 'right' | 'none';
  /**
   * Controls the open state from outside: `'open'` or `'closed'`. Clicking
   * the trigger then only calls `@onToggle`; update `@forceState` there.
   */
  forceState?: 'closed' | 'open';
  /**
   * Shows a loading spinner in place of the `<:extraAction>` block.
   * Defaults to `false`.
   */
  isLoading?: boolean;
  /**
   * While `@isLoading`, replace the content with a spinner and a message:
   * `true` for "Loading" (i18n token `euiAccordionChildrenLoading.message`),
   * or a string for your own message. Defaults to `false` (the content
   * stays visible).
   */
  isLoadingMessage?: boolean | string;
  /**
   * Disables the trigger and the arrow (greyed out, not clickable).
   * Defaults to `false`.
   */
  isDisabled?: boolean;
  /** @deprecated Has no effect, use `@initialIsOpen` or `@forceState`. */
  isOpen?: boolean;
  /** Class for the element wrapping the content (`.euiAccordion__children`). */
  childClassName?: string;
  /** Class for the row holding the arrow, trigger and extra action. */
  triggerClassName?: string;
  /** @deprecated Has no effect, use `@childClassName`. */
  childContentClassName?: string;
  /**
   * Extra styles composed last into this component's class (like upstream's
   * `css` prop). Prefer this to an extra class when styling it from a parent.
   */
  css?: EuiCss;
};

export interface EuiAccordionSignature {
  Element: any;
  Args: AccordionArgs;
  Blocks: {
    /** The trigger's content (usually a title); yields whether it is open. */
    buttonContent: [boolean | undefined];
    /** The collapsible content. */
    content: [];
    /**
     * Rendered next to the trigger when `@extraAction={{true}}`; yields
     * whether it is open.
     */
    extraAction: [boolean | undefined];
  };
}

/** Native Ember accordion on the upstream EUI 123 / Borealis factories. */
export default class EuiAccordionComponent extends Component<EuiAccordionSignature> {
  @service declare euiI18n: EuiI18n;

  observeHeight = observeHeight;

  @tracked _opened: boolean;
  @tracked contentHeight = 0;

  /** Set once an initially open accordion closes; enables transitions. */
  transition = { enabled: false };

  generatedRegionId = `euiAccordion-${guidFor(this)}`;
  generatedButtonId = `euiAccordionButton-${guidFor(this)}`;

  constructor(owner: Owner, args: AccordionArgs) {
    super(owner, args);
    this._opened = args.forceState
      ? args.forceState === 'open'
      : Boolean(args.initialIsOpen);
  }

  get context() {
    return getEuiThemeContext(this);
  }

  get tagName(): 'div' | 'fieldset' {
    return this.args.element === 'fieldset' ? 'fieldset' : 'div';
  }

  get buttonElement(): TriggerElement {
    if (this.tagName === 'fieldset') return 'legend';
    const element = this.args.buttonElement;
    return element === 'div' || element === 'legend' ? element : 'button';
  }

  get buttonIsInteractive(): boolean {
    return this.buttonElement === 'button';
  }

  /** Upstream forces the arrow when the trigger is not focusable. */
  get arrowDisplay(): 'left' | 'right' | 'none' {
    const display = this.args.arrowDisplay ?? 'left';
    return display === 'none' && !this.buttonIsInteractive ? 'left' : display;
  }

  get isOpen(): boolean {
    return this.args.forceState
      ? this.args.forceState === 'open'
      : this._opened;
  }

  get isDisabled(): boolean {
    return Boolean(this.args.isDisabled);
  }

  get isLoading(): boolean {
    return Boolean(this.args.isLoading);
  }

  get showLoadingMessage(): boolean {
    return this.isLoading && Boolean(this.args.isLoadingMessage);
  }

  get loadingMessage(): string {
    const message = this.args.isLoadingMessage;
    return typeof message === 'string' && message
      ? message
      : this.euiI18n.lookupToken(
          'euiAccordionChildrenLoading.message',
          'Loading'
        );
  }

  get regionId(): string {
    return this.args.id ?? this.generatedRegionId;
  }

  get buttonId(): string {
    return this.args.buttonProps?.id ?? this.generatedButtonId;
  }

  get borders(): EuiAccordionBorders {
    const borders = this.args.borders;
    return borders === 'horizontal' || borders === 'all' ? borders : 'none';
  }

  get paddingSize(): EuiAccordionPaddingSize {
    return this.args.paddingSize ?? 'none';
  }

  get role(): string {
    return this.args.role ?? 'group';
  }

  @cached
  get rootClass(): string {
    const styles = useEuiBorealisStyles(this.context, euiAccordionStyles);
    const borders = this.borders;
    return euiClass(
      this.context,
      styles.euiAccordion,
      borders !== 'none' && styles.borders.borders,
      borders !== 'none' && styles.borders[borders],
      this.args.css
    );
  }

  @cached
  get triggerWrapperClass(): string {
    return euiClass(this.context, TRIGGER_WRAPPER);
  }

  @cached
  get optionalActionClass(): string {
    return euiClass(this.context, OPTIONAL_ACTION);
  }

  @cached
  get buttonClass(): string {
    const styles = useEuiBorealisStyles(this.context, euiAccordionButtonStyles);
    const padding = this.args.buttonProps?.paddingSize;
    const arrow = this.arrowDisplay;
    return euiClass(
      this.context,
      TRIGGER_RESET,
      styles.euiAccordion__button,
      this.isDisabled && styles.disabled,
      padding && styles[padding],
      padding && arrow === 'left' && styles.arrowLeft,
      padding && arrow === 'right' && styles.arrowRight,
      this.args.buttonProps?.css
    );
  }

  /** Arrow styles composed into the EuiButtonIcon's own class (`@css`). */
  @cached
  get arrowCss() {
    const styles = useEuiBorealisStyles(this.context, euiAccordionArrowStyles);
    const side = this.arrowDisplay === 'right' ? 'right' : 'left';
    return [
      styles.euiAccordion__arrow,
      styles[side],
      this.isOpen ? styles.isOpen : styles.isClosed,
      this.args.arrowProps?.css
    ];
  }

  get arrowClasses(): string {
    return ['euiAccordion__arrow', this.args.arrowProps?.className]
      .filter(Boolean)
      .join(' ');
  }

  get noTransition(): boolean {
    const initialIsOpen = Boolean(this.args.initialIsOpen);
    // Upstream: the first close of an initially open accordion turns
    // transitions on for good (untracked flag, read with `isOpen`).
    if (initialIsOpen && !this.isOpen) enableTransition(this.transition);
    return initialIsOpen && !this.transition.enabled && this.isOpen;
  }

  @cached
  get childWrapperClass(): string {
    const styles = useEuiBorealisStyles(
      this.context,
      euiAccordionChildWrapperStyles
    );
    return euiClass(
      this.context,
      styles.euiAccordion__childWrapper,
      this.isOpen ? styles.isOpen : styles.isClosed,
      this.noTransition && styles.noTransition
    );
  }

  @cached
  get childrenClass(): string {
    const styles = useEuiBorealisStyles(
      this.context,
      euiAccordionChildrenStyles
    );
    const padding = this.paddingSize;
    return euiClass(
      this.context,
      styles.euiAccordion__children,
      this.isLoading && styles.isLoading,
      padding !== 'none' && styles[padding]
    );
  }

  /** Upstream's `css` on the loading message's spinner. */
  @cached
  get spinnerCss(): EuiCss {
    return { marginInlineEnd: this.context.upstream.euiTheme.size.xs };
  }

  /** Upstream's inline `blockSize`: the measured content height when open. */
  get childWrapperStyle() {
    return htmlSafe(`block-size: ${this.isOpen ? this.contentHeight : 0}px`);
  }

  get buttonClasses(): string {
    return [
      'euiAccordion__button',
      this.args.buttonClassName,
      this.args.buttonProps?.className,
      this.buttonClass
    ]
      .filter(Boolean)
      .join(' ');
  }

  get buttonContentClasses(): string {
    return ['euiAccordion__buttonContent', this.args.buttonContentClassName]
      .filter(Boolean)
      .join(' ');
  }

  get childrenClasses(): string {
    return [
      'euiAccordion__children',
      this.isLoading && 'euiAccordion__children-isLoading',
      this.args.childClassName,
      this.childrenClass
    ]
      .filter(Boolean)
      .join(' ');
  }

  onResize = (height: number): void => {
    if (height !== this.contentHeight) this.contentHeight = height;
  };

  onToggle = (): void => {
    if (this.isDisabled) return;
    if (this.args.forceState) {
      this.args.onToggle?.(!this.isOpen);
    } else {
      this._opened = !this._opened;
      this.args.onToggle?.(this._opened);
    }
  };

  <template>
    {{#let
      (element this.tagName) (element this.buttonElement)
      as |Accordion ButtonElement|
    }}
      <Accordion
        class="euiAccordion {{if this.isOpen 'euiAccordion-isOpen'}} {{this.rootClass}}"
        ...attributes
      >
        <div
          class="euiAccordion__triggerWrapper {{this.triggerWrapperClass}} {{@triggerClassName}}"
        >
          {{#if (eq this.arrowDisplay "left")}}
            <EuiButtonIcon
              class={{this.arrowClasses}}
              @color="text"
              @iconType="chevronSingleRight"
              @isDisabled={{this.isDisabled}}
              @css={{this.arrowCss}}
              aria-controls={{this.regionId}}
              aria-expanded={{if this.isOpen "true" "false"}}
              aria-labelledby={{this.buttonId}}
              aria-hidden={{if this.buttonIsInteractive "true" "false"}}
              tabindex={{if this.buttonIsInteractive "-1" "0"}}
              {{on "click" this.onToggle}}
            />
          {{/if}}
          <ButtonElement
            type={{if this.buttonIsInteractive "button"}}
            disabled={{if this.buttonIsInteractive this.isDisabled}}
            id={{this.buttonId}}
            class={{this.buttonClasses}}
            aria-controls={{this.regionId}}
            aria-expanded={{if
              this.buttonIsInteractive
              (if this.isOpen "true" "false")
            }}
            data-test-subj={{@buttonProps.data-test-subj}}
            {{on "click" this.onToggle}}
          >
            <span class={{this.buttonContentClasses}}>
              {{#if (has-block "buttonContent")}}
                {{yield this.isOpen to="buttonContent"}}
              {{else}}
                {{@buttonContent}}
              {{/if}}
            </span>
          </ButtonElement>
          {{#if this.isLoading}}
            <div
              class="euiAccordion__optionalAction {{this.optionalActionClass}}"
            >
              <EuiLoadingSpinner />
            </div>
          {{else if (and @extraAction (has-block "extraAction"))}}
            <div
              class="euiAccordion__optionalAction {{this.optionalActionClass}}"
            >
              {{yield this.isOpen to="extraAction"}}
            </div>
          {{/if}}
          {{#if (eq this.arrowDisplay "right")}}
            <EuiButtonIcon
              class={{this.arrowClasses}}
              @color="text"
              @iconType="chevronSingleRight"
              @isDisabled={{this.isDisabled}}
              @css={{this.arrowCss}}
              aria-controls={{this.regionId}}
              aria-expanded={{if this.isOpen "true" "false"}}
              aria-labelledby={{this.buttonId}}
              aria-hidden={{if this.buttonIsInteractive "true" "false"}}
              tabindex={{if this.buttonIsInteractive "-1" "0"}}
              {{on "click" this.onToggle}}
            />
          {{/if}}
        </div>
        <div
          class="euiAccordion__childWrapper {{this.childWrapperClass}}"
          style={{this.childWrapperStyle}}
          role={{this.role}}
          id={{this.regionId}}
          aria-labelledby={{this.buttonId}}
          inert={{not this.isOpen}}
        >
          <div
            class={{this.childrenClasses}}
            {{this.observeHeight this.onResize}}
          >
            {{#if this.showLoadingMessage}}
              <EuiLoadingSpinner
                class="euiAccordion__spinner"
                @css={{this.spinnerCss}}
              />
              <EuiText @size="s"><p>{{this.loadingMessage}}</p></EuiText>
            {{else}}
              {{yield to="content"}}
            {{/if}}
          </div>
        </div>
      </Accordion>
    {{/let}}
  </template>
}
