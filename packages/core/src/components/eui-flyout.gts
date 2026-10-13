import Component from '@glimmer/component';
import type Owner from '@ember/owner';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { registerDestructor } from '@ember/destroyable';
import { guidFor } from '@ember/object/internals';
import { next, schedule } from '@ember/runloop';
import { service } from '@ember/service';

import { focusTrap } from 'ember-focus-trap';
import { focusTrapFactory } from '../-private/focus-trap-registry.ts';
import { modifier as functionModifier } from 'ember-modifier';
import { provide } from 'ember-provide-consume-context';
import style from 'ember-style-modifier/modifiers/style';

import {
  EUI_FLYOUT_CONTEXT,
  euiFlyoutContext,
  euiFlyoutManager
} from '../-private/eui-flyout-context.ts';
import { nextFrame } from '../-private/next-frame.ts';
import { valueModifier } from '../-private/value-modifier.ts';
import setBodyClass from '../-private/set-body-class.ts';
import outsideClickDetectorModifier from '../modifiers/outside-click-detector.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  dialogDescription,
  flyoutZIndex,
  observeWidth,
  pushFlyoutPadding,
  reactInlineStyle
} from '../utils/eui/modal-flyout.ts';
import {
  getFlyoutActivity,
  getNextStage,
  getStageTransition
} from '../utils/eui/flyout-manager/activity-stage.ts';
import {
  DEFAULT_MENU_DISPLAY_MODE,
  LAYOUT_MODE_SIDE_BY_SIDE,
  LAYOUT_MODE_STACKED,
  LEVEL_CHILD,
  LEVEL_MAIN,
  MENU_DISPLAY_ALWAYS,
  MIN_HISTORY_ITEMS,
  PROPERTY_LEVEL,
  SESSION_INHERIT,
  SESSION_NEVER,
  SESSION_START
} from '../utils/eui/flyout-manager/const.ts';
import {
  getCurrentSession,
  getFlyout,
  getFlyoutPagination,
  hasChildFlyout,
  isFlyoutRegistered
} from '../utils/eui/flyout-manager/selectors.ts';
import {
  createValidationErrorMessage,
  isNamedSize,
  validateManagedFlyoutSize,
  validateSizeCombination
} from '../utils/eui/flyout-manager/validation.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  composeFlyoutInlineStyles,
  euiFlyoutCloseButtonStyles,
  euiFlyoutStyles,
  euiMainFlyoutStyles,
  euiManagedFlyoutStyles,
  FLYOUT_SIZES,
  isEuiFlyoutSizeNamed
} from '../utils/eui/styles.generated.ts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiFlyoutMenu from './eui-flyout-menu.gts';
import EuiFlyoutResizeButton from './eui-flyout-resize-button.gts';
import EuiOverlayMask from './eui-overlay-mask.gts';
import EuiPortal from './eui-portal.gts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';

import type { EuiFlyoutContext } from '../-private/eui-flyout-context.ts';
import type EuiFlyoutManagerService from '../services/eui-flyout-manager.ts';
import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiBreakpointSize } from '../utils/breakpoint.ts';
import type { TOC } from '@ember/component/template-only';
import type { EuiFlyoutMenuDisplayMode } from '../utils/eui/flyout-manager/const.ts';
import type {
  EuiFlyoutActivityStage,
  EuiFlyoutCloseMeta,
  EuiFlyoutCloseReason,
  EuiFlyoutLayoutMode,
  EuiFlyoutLevel,
  FlyoutSession,
  IconType
} from '../utils/eui/flyout-manager/types.ts';
import type {
  EuiFlyoutHistoryItem,
  EuiFlyoutMenuAction,
  EuiFlyoutMenuBackButtonProps,
  EuiFlyoutMenuCustomAction,
  EuiFlyoutMenuPagination
} from './eui-flyout-menu.gts';

export type {
  EuiFlyoutCloseMeta,
  EuiFlyoutCloseReason
} from '../utils/eui/flyout-manager/types.ts';

/**
 * Props of the menu bar `@flyoutMenuProps` renders at the top of the flyout
 * (upstream `EuiFlyoutMenuProps`, the arguments of `EuiFlyoutMenu`).
 */
export interface EuiFlyoutMenuProps {
  /**
   * Title of the menu. In a managed flyout it also names the session in
   * the history. Hidden from view by default (see `hideTitle`).
   */
  title?: string;
  /** Id of the title element; the flyout is labelled by it. */
  titleId?: string;
  /** An icon next to the session title in the history popover. */
  iconType?: IconType;
  /**
   * Hides the title visually. Defaults to `true`.
   * @deprecated Use `EuiFlyoutHeader` for visible titles.
   */
  hideTitle?: boolean;
  /** Hides the menu's close button. */
  hideCloseButton?: boolean;
  /** Shows a back button (managed main flyouts set it from the history). */
  showBackButton?: boolean;
  /** Options of the back button, such as `onClick`. */
  backButtonProps?: EuiFlyoutMenuBackButtonProps;
  /** Entries of the history popover, most recent first (shown from two). */
  historyItems?: EuiFlyoutHistoryItem[];
  /** Actions at the inline start of the bar. */
  leadingActions?: EuiFlyoutMenuAction[];
  /** Actions at the inline end of the bar. */
  trailingActions?: EuiFlyoutMenuAction[];
  /** @deprecated Use `trailingActions`. */
  customActions?: EuiFlyoutMenuCustomAction[];
  /** Previous/next controls; they replace the back button and history. */
  pagination?: EuiFlyoutMenuPagination;
}

/** A flyout container: an element, a getter or a CSS selector. */
export type EuiFlyoutContainer =
  | HTMLElement
  | null
  | (() => HTMLElement | null)
  | string;

/** Upstream `focusTrapProps` (`EuiFocusTrap` props). */
export interface EuiFlyoutFocusTrapProps {
  /**
   * Whether closing returns focus to the element focused before opening:
   * `false` opts out (return it yourself), a function receives that
   * element and returns `false` to skip it. Defaults to `true`.
   */
  returnFocus?:
    | boolean
    | FocusOptions
    | ((returnTo: Element) => boolean | FocusOptions);
  /** Extra elements that count as part of the flyout for the focus trap. */
  shards?: HTMLElement[];
}

export type EuiFlyoutArgs = {
  /** Same as `@closeButtonAriaLabel`. */
  closeAriaLabel?: string;
  /** @deprecated Has no effect: render the flyout only while it is open. */
  isOpen?: boolean;
  /** @deprecated Has no effect, see EuiCollapsibleNav; use `@type="push"`. */
  isDocked?: boolean;
  /** @deprecated Has no effect; use `@pushMinBreakpoint`. */
  dockedBreakpoint?: EuiBreakpointSize | number;
  /** @deprecated Has no effect. */
  showButtonIfDocked?: boolean;

  /** Traps keyboard focus inside the flyout. Defaults to `true`. */
  isFocusTrapActive?: boolean;

  /** Tag of the flyout, e.g. `'nav'` or `'aside'`. Defaults to `'div'`. */
  as?: string;

  /**
   * Width: `'s'`, `'m'`, `'l'` or `'fill'` (90%), a number in px or any
   * CSS width. Defaults to `'m'`.
   */
  size?: number | string;

  /**
   * Side of the window it slides in from (logical: `'right'` is the
   * inline end, so it mirrors in RTL). Defaults to `'right'`.
   */
  side?: 'left' | 'right';

  /**
   * `role` of the flyout. Defaults to `'dialog'` (with `aria-modal`); a
   * pushed flyout has no role unless you pass one. `null` for none.
   */
  role?: null | string;

  /**
   * Renders a mask over the page behind the flyout, which closes it when
   * clicked. Without it, the page stays usable. Defaults to `true`.
   */
  ownFocus?: boolean;

  /**
   * Without the mask (`@ownFocus={{false}}`), `true` closes the flyout on
   * clicks outside it. With the mask, `false` stops mask clicks from
   * closing it. Defaults to closing on mask clicks only.
   */
  outsideClickCloses?: boolean;

  /**
   * Close button `'inside'` the flyout's corner or `'outside'` next to it.
   * Defaults to `'inside'`.
   */
  closeButtonPosition?: 'outside' | 'inside';

  /**
   * Padding of `EuiFlyoutHeader`, `EuiFlyoutBody` and `EuiFlyoutFooter`:
   * `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'l'`.
   */
  paddingSize?: 'none' | 's' | 'm' | 'l' | string;

  /** Hides the close button (e.g. when the flyout has its own). */
  hideCloseButton?: boolean;

  /** Props for the close button: `{ className, onClick }`. */
  closeButtonProps?: {
    className?: string;
    onClick?: (e: MouseEvent) => void;
    classes?: string;
  };

  /** Accessible label of the close button. Defaults to "Close this dialog". */
  closeButtonAriaLabel?: string;

  /**
   * Called by the close button, Escape, the mask and outside clicks with
   * the event and `{ reason }` (`'close-button'`, `'escape'`,
   * `'outside-click'`; managed flyouts also `'navigation-back'` and
   * `'navigation-cascade'`). Stop rendering the flyout here. Without it
   * there is no close button.
   */
  onClose?: (event?: Event, meta?: EuiFlyoutCloseMeta) => void;

  /**
   * Caps the width: `true` for the size's max width, `false` for none, or
   * a number in px or any CSS width. Defaults to `false`.
   */
  maxWidth?: boolean | number | string;

  /**
   * Options for the mask: `{ headerZindexLocation: 'above' }` puts the
   * flyout and its mask above a fixed `EuiHeader`. Defaults to `'below'`.
   */
  maskProps?: { headerZindexLocation?: 'above' | 'below' };

  /**
   * `'overlay'` covers the page; `'push'` pads the page so the flyout sits
   * beside it (on windows at least `@pushMinBreakpoint` wide).
   * Defaults to `'overlay'`.
   */
  type?: 'overlay' | 'push' | string;

  /**
   * Minimum window width for `@type="push"`: a theme breakpoint name
   * (`'xs'` to `'xl'`) or px. Smaller windows get an overlay. Defaults
   * to `'l'`.
   */
  pushMinBreakpoint?: number | EuiBreakpointSize;

  /**
   * Slides the flyout in (only when the user allows motion). Defaults to
   * `true` for overlays and `false` for push flyouts.
   */
  hasAnimation?: boolean;

  /** Focuses the flyout itself when it opens. Defaults to `true`. */
  shouldSelfFocus?: boolean;

  /**
   * Options for the focus trap (focus-trap library), e.g.
   * `{ initialFocus: '#name' }`. Defaults to allowing outside clicks.
   */
  focusTrapOptions?: {
    allowOutsideClick?: boolean;
    clickOutsideDeactivates?: boolean;
    initialFocus?: string | HTMLElement | (() => HTMLElement);
    fallbackFocus?: string | HTMLElement | (() => HTMLElement);
    escapeDeactivates?: boolean;
    returnFocusOnDeactivate?: boolean;
    preventScroll?: boolean;
  };
  /**
   * Adds a resize handle at the flyout's inner edge, dragged or moved with
   * the arrow keys (10px a step). The width is kept as a share of the window
   * and clamped between `@minWidth` and `@maxWidth` (a number in px) and 90%
   * of the window. `EuiFlyoutResizable` is this set to `true`. Defaults to
   * `false`.
   */
  resizable?: boolean;
  /** Smallest width in px while `@resizable`. Defaults to `0`. */
  minWidth?: number;
  /**
   * Called with the new width in px after the user resizes (when a drag ends,
   * and on each keyboard step), while `@resizable`.
   */
  onResize?: (width: number) => void;
  /**
   * Extra styles composed last into this component's class (like upstream's
   * `css` prop). Prefer this to an extra class when styling it from a parent.
   */
  css?: EuiCss;
  /**
   * Session management (Beta): `'start'` opens a new flyout session with
   * this flyout as its main flyout; `'inherit'` joins the active session as
   * its child flyout (a standard flyout without one); `'never'` opts out.
   * Unset, a flyout nested in another flyout's block joins the active
   * session as a child, any other flyout is a standard one.
   */
  session?: 'start' | 'inherit' | 'never';
  /**
   * Scopes the history (Back button and history popover) of
   * `@session="start"` flyouts: only flyouts given the same Symbol share
   * it. Defaults to a history of its own per session.
   */
  historyKey?: symbol;
  /** Called when a managed flyout becomes active again, e.g. through history. */
  onActive?: () => void;
  /**
   * Renders a menu bar at the top of the flyout (title, back button,
   * history, actions, pagination) in place of the close button; its close
   * button closes the flyout. In managed flyouts `title` names the session
   * and the manager adds the back button and history.
   */
  flyoutMenuProps?: EuiFlyoutMenuProps;
  /**
   * `'auto'` renders the menu only when it has content (back button,
   * history, actions, pagination or a visible title); `'always'` whenever
   * `@flyoutMenuProps` is set. Defaults to `'auto'`.
   */
  flyoutMenuDisplayMode?: EuiFlyoutMenuDisplayMode;
  /** A managed child flyout gets the subdued background. Defaults to `false`. */
  hasChildBackground?: boolean;
  /**
   * Keeps the flyout (and its mask) within an element's bounds, e.g. an
   * app area next to a side navigation: an element, a getter or a CSS
   * selector. Push flyouts pad it instead of `<body>`, and its width
   * replaces the window's for push breakpoints and resizing. Nested
   * flyouts inherit it. `null` forces the viewport and puts the flyout above
   * fixed headers.
   */
  container?: EuiFlyoutContainer;
  /** Focus trap options (upstream `focusTrapProps`): `returnFocus`, `shards`. */
  focusTrapProps?: EuiFlyoutFocusTrapProps;
};

export const SIZES = FLYOUT_SIZES as unknown as readonly [
  's',
  'm',
  'l',
  'fill'
];
export type EuiFlyoutSize = (typeof SIZES)[number];

/** Upstream `EuiWindowEvent` keydown: Escape closes a flyout that is not pushed. */
const windowKeydown = functionModifier(
  (_element: Element, [handler]: [(event: KeyboardEvent) => void]) => {
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }
);

const windowResize = functionModifier(
  (_element: Element, [handler, enabled]: [() => void, boolean]) => {
    if (!enabled) return;
    window.addEventListener('resize', handler);
    return () => window.removeEventListener('resize', handler);
  }
);

/**
 * A panel sliding in from the side of the window, for details or forms
 * that keep the page context. Render it only while open:
 * `{{#if this.isOpen}}<EuiFlyout @onClose={{…}}>…</EuiFlyout>{{/if}}`.
 */
export interface EuiFlyoutSignature {
  Element: any;
  Args: EuiFlyoutArgs;
  Blocks: {
    /** Usually `EuiFlyoutHeader`, `EuiFlyoutBody` and `EuiFlyoutFooter`. */
    default: [];
  };
}

/** Runs after the current render, so manager updates never change state a render already read. */
function afterRender(callback: () => void) {
  schedule('afterRender', callback);
}

/** Upstream `resolveContainer`: an element, a getter or a CSS selector. */
function resolveContainer(raw: EuiFlyoutContainer | undefined): HTMLElement | null {
  if (raw == null) return null;
  if (typeof raw === 'string') {
    if (typeof document === 'undefined') return null;
    const element = document.querySelector(raw);
    return element instanceof HTMLElement ? element : null;
  }
  if (typeof raw === 'function') return raw();
  if (typeof HTMLElement === 'undefined') return null;
  return raw instanceof HTMLElement ? raw : null;
}

/** The generated `stage` reads its optional arguments through `arguments`. */
type StageStyles = (stage: string, side: string, level: string) => EuiCss;

/** Upstream suppresses the opening animation of non-initial managed flyouts. */
const NO_OPENING_ANIMATION = { animationDuration: '0s !important' };

/** Named sizes as a share of the container (upstream `sizePercentMap`). */
const SIZE_PERCENT: Record<string, number> = { s: 0.25, m: 0.5, l: 0.75, fill: 0.9 };

/**
 * Prepends the menu title id to the caller's `aria-labelledby` (upstream
 * joins them; Ember cannot read `...attributes`).
 */
const labelledBy = valueModifier(
  (element: Element, [id]: [string | undefined]) => {
    if (!id) return;
    const caller = (element.getAttribute('aria-labelledby') ?? '')
      .split(/\s+/)
      .filter((value) => value && value !== id);
    element.setAttribute('aria-labelledby', [id, ...caller].join(' '));
    return () => {
      if (caller.length) element.setAttribute('aria-labelledby', caller.join(' '));
      else element.removeAttribute('aria-labelledby');
    };
  }
);

/** Upstream `EuiFlyoutOverlay` clips the mask to the container's rect. */
const maskContainerRect = valueModifier(
  (element: Element, [rect]: [DOMRect | null]) => {
    const node = element as HTMLElement;
    const properties = [
      'inset-block-start',
      'inset-inline-start',
      'inline-size',
      'block-size',
      'inset-inline-end',
      'inset-block-end'
    ];
    if (rect) {
      node.style.setProperty('inset-block-start', `${rect.top}px`);
      node.style.setProperty('inset-inline-start', `${rect.left}px`);
      node.style.setProperty('inline-size', `${rect.width}px`);
      node.style.setProperty('block-size', `${rect.height}px`);
      node.style.setProperty('inset-inline-end', 'auto');
      node.style.setProperty('inset-block-end', 'auto');
    } else {
      properties.forEach((property) => node.style.removeProperty(property));
    }
  }
);

export default class EuiFlyoutComponent
  extends Component<EuiFlyoutSignature>
  implements EuiFlyoutContext
{
  @service declare euiI18n: EuiI18n;

  @tracked windowWidth =
    typeof window === 'undefined' ? Infinity : window.innerWidth;

  /** Border-box width while pushed, for the body padding. */
  @tracked width?: number;

  /** The user's width in px while `@resizable`; `0` until measured. */
  @tracked resizeWidth = 0;
  private callOnResize = false;
  private resizeSizeArg: unknown = UNSET;
  private resizeReferenceWidth = 0;
  private dragStartX = 0;
  private dragStartWidth = 0;

  /** The `container`'s bounding rect and width, measured while it is set. */
  @tracked containerRect: DOMRect | null = null;
  @tracked containerWidth = 0;

  /** The flyout manager (upstream `getFlyoutManagerStore()`). */
  manager: EuiFlyoutManagerService;

  /**
   * The manager's z-index when this flyout opened (upstream's
   * `currentZIndexRef`), read without tracking.
   */
  private mountZIndex: number;

  /** Set while this managed flyout is registered (upstream `wasRegisteredRef`). */
  private wasRegistered = false;

  constructor(owner: Owner, args: EuiFlyoutArgs) {
    super(owner, args);
    this.manager = euiFlyoutManager(this);
    this.mountZIndex = this.manager.getState().currentZIndex;
    registerDestructor(this, this.stopDragging);
  }

  /** Content nested in this flyout sees it as its parent flyout. */
  @provide(EUI_FLYOUT_CONTEXT)
  get flyoutContext(): EuiFlyoutContext {
    return this;
  }

  id = guidFor(this);

  /** The flyout element, the focus trap's fallback. */
  element?: Element;

  registerElement = functionModifier((element: Element) => {
    this.element = element;
  });
  descriptionId = `${this.id}-description`;

  // Session routing (upstream `flyout.tsx`)

  /**
   * `'inherit'` for a flyout nested in another one while a session is
   * active and `@session` is unset; otherwise `@session`, default `'never'`.
   */
  get effectiveSession(): 'start' | 'inherit' | 'never' {
    const session = this.args.session;
    if (
      session === undefined &&
      euiFlyoutContext(this) &&
      this.manager.hasActiveSession
    ) {
      return SESSION_INHERIT;
    }
    return session ?? SESSION_NEVER;
  }

  /** `main`, `child`, or `null` for a standard (unmanaged) flyout. */
  @cached
  get level(): EuiFlyoutLevel | null {
    const session = this.effectiveSession;
    if (session === SESSION_START) return LEVEL_MAIN;
    if (session === SESSION_INHERIT && this.manager.hasActiveSession) {
      return LEVEL_CHILD;
    }
    return null;
  }

  /** A change of route renders a new flyout, like upstream's component switch. */
  @cached
  get routes(): string[] {
    return [this.level ?? 'standard'];
  }

  /** The id the manager knows this flyout by. */
  get flyoutId(): string {
    return this.id;
  }

  // Manager state (read only by managed flyouts)

  @cached
  get currentSession(): FlyoutSession | null {
    return this.level ? getCurrentSession(this.manager.state) : null;
  }

  /** The session this flyout is the main or current child of. */
  @cached
  get ownSession(): FlyoutSession | null {
    if (!this.level) return null;
    const id = this.flyoutId;
    return (
      this.manager.state.sessions.find(
        (session) => session.mainFlyoutId === id || session.childFlyoutId === id
      ) ?? null
    );
  }

  get isMainFlyout(): boolean {
    return this.ownSession?.mainFlyoutId === this.flyoutId;
  }

  get siblingFlyoutId(): string | null {
    const session = this.ownSession;
    if (!session) return null;
    return session.mainFlyoutId === this.flyoutId
      ? session.childFlyoutId
      : session.mainFlyoutId;
  }

  get siblingFlyout() {
    const id = this.siblingFlyoutId;
    return id ? getFlyout(this.manager.state, id) : null;
  }

  get layoutMode(): 'side-by-side' | 'stacked' {
    return this.level ? this.manager.layoutMode : LAYOUT_MODE_SIDE_BY_SIDE;
  }

  /** The sibling's width; `0` when stacked. */
  get siblingFlyoutWidth(): number | undefined {
    return this.layoutMode === LAYOUT_MODE_STACKED
      ? 0
      : this.siblingFlyout?.width;
  }

  /** Main or child of the latest session. */
  get isActiveManagedFlyout(): boolean {
    const session = this.currentSession;
    return (
      session?.mainFlyoutId === this.flyoutId ||
      session?.childFlyoutId === this.flyoutId
    );
  }

  get isChildFlyout(): boolean {
    const childId = this.currentSession?.childFlyoutId;
    return Boolean(this.level) && childId != null && childId === this.flyoutId;
  }

  get isSideBySideChild(): boolean {
    return this.isChildFlyout && this.layoutMode === LAYOUT_MODE_SIDE_BY_SIDE;
  }

  get isRegistered(): boolean {
    return this.level
      ? isFlyoutRegistered(this.manager.state, this.flyoutId)
      : false;
  }

  /** Inputs of the activity stage transitions (upstream `useFlyoutActivityStage`). */
  @cached
  get activity() {
    return this.level
      ? getFlyoutActivity(this.manager.state, this.flyoutId)
      : null;
  }

  /** The main flyout of the latest session (a child's main). */
  get currentMainFlyout() {
    return getFlyout(this.manager.state, this.currentSession?.mainFlyoutId);
  }

  /** A child flyout without a main flyout renders nothing (upstream logs an error). */
  get isOrphanChild(): boolean {
    if (this.level !== LEVEL_CHILD || this.currentMainFlyout) return false;
    console.error(
      'EuiFlyoutChild validation failed:',
      'EuiFlyoutChild must be used with an EuiFlyoutMain. This usually means the main flyout was not rendered before the child flyout.'
    );
    return true;
  }

  /** Upstream throws for invalid managed sizes. */
  get validManagedSize(): true {
    const level = this.level;
    if (!level) return true;

    const size = this.sizeArg;
    const sizeTypeError = validateManagedFlyoutSize(size, this.flyoutId, level);
    if (sizeTypeError) {
      throw new Error(createValidationErrorMessage(sizeTypeError));
    }

    if (level === LEVEL_CHILD) {
      const session = this.ownSession;
      const parentSize = session
        ? getFlyout(this.manager.state, session.mainFlyoutId)?.size
        : undefined;
      if (parentSize && isNamedSize(size) && isNamedSize(parentSize)) {
        const error = validateSizeCombination(parentSize, size);
        if (error) {
          error.flyoutId = this.flyoutId;
          error.parentFlyoutId = session?.mainFlyoutId;
          error.level = level;
          throw new Error(createValidationErrorMessage(error));
        }
      }
    }

    return true;
  }

  /**
   * Only the first main flyout (sole session) and the first child of a
   * session play the opening animation.
   */
  get shouldAnimateOpening(): boolean {
    if (this.level === LEVEL_MAIN) {
      return (
        this.manager.state.sessions.length <= 1 &&
        this.currentSession?.mainFlyoutId === this.flyoutId
      );
    }
    return (this.ownSession?.childHistory.length ?? 0) === 0;
  }

  // Container (upstream `container` prop)

  /**
   * `@container`; a flyout nested in another one without it inherits the
   * parent's container (`@container={{null}}` opts out).
   */
  @cached
  get containerElement(): HTMLElement | null {
    if (!('container' in this.args)) {
      return euiFlyoutContext(this)?.containerElement ?? null;
    }
    return resolveContainer(this.args.container);
  }

  /** The container's width; `undefined` without a container. */
  get containerReferenceWidth(): number | undefined {
    const container = this.containerElement;
    return container
      ? this.containerWidth || container.clientWidth
      : undefined;
  }

  /** The manager's and the container's reference width (upstream `effectiveReferenceWidth`). */
  get effectiveReferenceWidth(): number | undefined {
    const containerWidth = this.containerReferenceWidth;
    const managerWidth =
      this.level &&
      typeof this.manager.state.referenceWidth === 'number' &&
      this.manager.state.referenceWidth > 0
        ? this.manager.state.referenceWidth
        : undefined;

    if (containerWidth != null && containerWidth > 0) {
      return managerWidth != null
        ? Math.min(managerWidth, containerWidth)
        : containerWidth;
    }
    return managerWidth ?? containerWidth;
  }

  /** The width resizing and push breakpoints measure against. */
  get referenceWidth(): number {
    return this.effectiveReferenceWidth ?? this.windowWidth;
  }

  get as() {
    return this.args.as ?? 'div';
  }

  get closeButtonPosition() {
    return this.args.closeButtonPosition === 'outside' ? 'outside' : 'inside';
  }

  /** Child flyouts never own focus (upstream `EuiFlyoutChild`). */
  get ownFocus() {
    if (this.level === LEVEL_CHILD) return false;
    return this.args.ownFocus ?? true;
  }

  get side(): 'left' | 'right' {
    return this.args.side === 'left' ? 'left' : 'right';
  }

  get resizable() {
    return Boolean(this.args.resizable);
  }

  /** Pushed flyouts and resizable ones follow the window's width. */
  get tracksWindowWidth() {
    return this.type === 'push' || this.resizable;
  }

  /** `@size`; managed main flyouts default to `'m'`, children to `'s'`. */
  get sizeArg(): number | string {
    return this.args.size ?? (this.level === LEVEL_CHILD ? 's' : 'm');
  }

  /**
   * While resizable, the user's width as a percentage of the reference
   * width (upstream `useEuiFlyoutResizable`), which replaces the named size.
   */
  get size() {
    const reference = this.referenceWidth;
    if (
      this.resizable &&
      this.resizeWidth &&
      Number.isFinite(reference) &&
      reference > 0
    ) {
      return `${(this.resizeWidth / reference) * 100}%`;
    }

    return this.sizeArg;
  }

  get paddingSize(): 'none' | 's' | 'm' | 'l' {
    const size = this.args.paddingSize;
    return size === 'none' || size === 's' || size === 'm' ? size : 'l';
  }

  get maxWidth() {
    return this.args.maxWidth ?? false;
  }

  /** Child flyouts are always overlays. */
  get type() {
    if (this.level === LEVEL_CHILD) return 'overlay';
    return this.args.type === 'push' ? 'push' : 'overlay';
  }

  get hasAnimation() {
    return this.args.hasAnimation ?? this.type === 'overlay';
  }

  /** `@container={{null}}` puts the flyout above fixed headers by default. */
  get headerZindexLocation(): 'above' | 'below' {
    const location = this.args.maskProps?.headerZindexLocation;
    if (location) return location === 'above' ? 'above' : 'below';
    return 'container' in this.args && this.args.container === null
      ? 'above'
      : 'below';
  }

  get pushMinWidth(): number {
    const min = this.args.pushMinBreakpoint ?? 'l';
    if (typeof min === 'number') return min;
    const breakpoints = getEuiThemeContext(this).upstream.euiTheme
      .breakpoint as Record<string, number>;
    return breakpoints[min] ?? Infinity;
  }

  get isPushed() {
    if (this.type !== 'push') return false;
    const containerWidth = this.containerReferenceWidth;
    return (containerWidth ?? this.windowWidth) >= this.pushMinWidth;
  }

  get hasOverlayMask() {
    return this.ownFocus && !this.isPushed;
  }

  /** A side-by-side child defers the dialog role to its main flyout. */
  get role() {
    if (this.args.role !== undefined) return this.args.role ?? undefined;
    if (this.isSideBySideChild) return undefined;
    return this.isPushed ? undefined : 'dialog';
  }

  get ariaModal() {
    return !this.isPushed &&
      !this.isSideBySideChild &&
      (this.role === 'dialog' || this.role === 'alertdialog')
      ? 'true'
      : undefined;
  }

  get showCloseButton() {
    return Boolean(this.args.onClose) && !this.args.hideCloseButton;
  }

  get zIndex() {
    const session = this.currentSession;
    return flyoutZIndex(
      getEuiThemeContext(this).upstream,
      this.headerZindexLocation,
      this.isPushed,
      this.level && session ? session.zIndex : this.mountZIndex,
      this.isChildFlyout
    );
  }

  // Flyout menu (upstream `useEuiFlyoutMenu` and EuiManagedFlyout's menu props)

  /** `@flyoutMenuProps`, plus the manager's history, Back button and title. */
  @cached
  get menuProps(): EuiFlyoutMenuProps | undefined {
    const own = this.args.flyoutMenuProps;
    const level = this.level;
    if (!level) return own;

    const isMain = level === LEVEL_MAIN;
    const session = this.ownSession;
    const historyItems = isMain ? this.manager.historyItems : undefined;
    const pagination =
      getFlyoutPagination(this.manager.state, this.flyoutId) ?? own?.pagination;
    const showPaginationControls = pagination != null && pagination.total >= 1;
    const title =
      own?.title ||
      (isMain ? session?.title : session?.childTitle) ||
      undefined;

    return {
      ...own,
      historyItems: showPaginationControls ? [] : historyItems,
      showBackButton: showPaginationControls
        ? false
        : historyItems
          ? historyItems.length > 0
          : false,
      backButtonProps: isMain ? { onClick: this.manager.goBack } : undefined,
      title,
      pagination
    };
  }

  get menuTitleId(): string | undefined {
    if (!this.menuProps) return undefined;
    return this.menuProps.titleId || `${this.id}-menuTitle`;
  }

  get shouldRenderMenu(): boolean {
    const props = this.menuProps;
    if (!props) return false;
    if (
      (this.args.flyoutMenuDisplayMode ?? DEFAULT_MENU_DISPLAY_MODE) ===
      MENU_DISPLAY_ALWAYS
    ) {
      return true;
    }

    const trailingActions =
      props.trailingActions !== undefined
        ? props.trailingActions
        : props.customActions;

    return (
      !!props.showBackButton ||
      (props.historyItems?.length ?? 0) >= MIN_HISTORY_ITEMS ||
      (props.leadingActions?.length ?? 0) > 0 ||
      (trailingActions?.length ?? 0) > 0 ||
      // the menu hides its title by default
      !!(props.title && props.hideTitle === false) ||
      !!(props.pagination && props.pagination.total >= 1)
    );
  }

  get labelledById(): string | undefined {
    return this.shouldRenderMenu ? this.menuTitleId : undefined;
  }

  // Styles

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutStyles);
    const { size, side, isPushed } = this;
    const hasChildBackground =
      this.isChildFlyout && this.args.hasChildBackground;
    return `euiFlyout${
      hasChildBackground ? ' euiFlyout--hasChildBackground' : ''
    } ${euiClass(
      context,
      {
        boxSizing: 'border-box',
        // Upstream portals carry the provider's text color class.
        color: context.upstream.euiTheme.colors.textParagraph
      },
      styles.euiFlyout,
      styles.paddingSizes[this.paddingSize],
      isEuiFlyoutSizeNamed(size) ? styles[size as EuiFlyoutSize] : undefined,
      this.maxWidth === false ? styles.noMaxWidth : undefined,
      isPushed ? styles.push.push : styles.overlay.overlay,
      isPushed ? styles.push[side] : styles.overlay[side],
      this.hasAnimation ? undefined : styles.noAnimation,
      styles[side],
      this.managedCss,
      this.args.css
    )}`;
  }

  /**
   * EuiManagedFlyout's styles (3D context, the activity stage, no opening
   * animation after the first flyout) and EuiFlyoutMain's border while it
   * has a child.
   */
  @cached
  get managedCss(): EuiCss {
    const level = this.level;
    if (!level) return undefined;

    const context = getEuiThemeContext(this);
    const managed = useEuiBorealisStyles(context, euiManagedFlyoutStyles);
    const stage = this.activity?.stage ?? 'opening';
    const main =
      level === LEVEL_MAIN &&
      hasChildFlyout(this.manager.state, this.flyoutId) &&
      !this.isPushed
        ? useEuiBorealisStyles(context, euiMainFlyoutStyles).hasChildFlyout[
            this.side
          ]
        : undefined;

    return [
      managed.managedFlyout,
      (managed.stage as unknown as StageStyles)(stage, this.side, level),
      this.shouldAnimateOpening ? undefined : NO_OPENING_ANIMATION,
      main
    ];
  }

  @cached
  get contentClass() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutStyles);
    return `euiFlyout__content ${euiClass(context, styles.content)}`;
  }

  /**
   * Upstream EuiFlyoutChild's position beside (or z-index over) the main
   * flyout, the composed width/z-index, and the container's bounds.
   */
  @cached
  get inlineStyle() {
    const size = this.size;
    const { layoutMode, side, isChildFlyout } = this;
    const siblingFlyoutWidth = this.siblingFlyoutWidth;
    const zIndex = this.zIndex.flyout;

    let childStyle: Record<string, unknown> = {};
    if (this.level === LEVEL_CHILD) {
      const mainWidth = this.currentMainFlyout?.width;
      if (mainWidth && layoutMode === LAYOUT_MODE_SIDE_BY_SIDE) {
        childStyle = { [side]: `var(--euiFlyoutMainWidth, ${mainWidth}px)` };
      } else if (layoutMode === LAYOUT_MODE_STACKED) {
        childStyle = {
          zIndex:
            Number(getEuiThemeContext(this).upstream.euiTheme.levels.flyout) + 2
        };
      }
    }

    const composed = composeFlyoutInlineStyles(
      // React writes numeric widths as px
      typeof size === 'number' ? `${size}px` : size,
      layoutMode,
      this.siblingFlyoutId,
      siblingFlyoutWidth || null,
      this.maxWidth,
      zIndex
    );

    const rect = this.containerElement ? this.containerRect : null;
    const position: Record<string, unknown> = {};

    if (rect) {
      const containerMaxWidth = rect.width * 0.9;
      // clientWidth (no scrollbar) matches getBoundingClientRect and position: fixed
      const viewportWidth = document.documentElement.clientWidth;
      const containerRightOffset = viewportWidth - rect.right;

      let containerRelativeWidth: number | undefined;
      if (typeof size === 'string') {
        const named = SIZE_PERCENT[size];
        if (named !== undefined) {
          containerRelativeWidth = rect.width * named;
        } else if (size.endsWith('%')) {
          const percent = parseFloat(size);
          if (!isNaN(percent)) {
            containerRelativeWidth = rect.width * (percent / 100);
          }
        }
      } else if (typeof size === 'number') {
        containerRelativeWidth = size;
      }

      const breakpointM = Number(
        getEuiThemeContext(this).upstream.euiTheme.breakpoint.m
      );
      const containerMinWidths: Record<string, number> = {
        s: Math.round(breakpointM * 0.42),
        m: Math.round(breakpointM * 0.5)
      };
      const sizeMinWidth =
        typeof size === 'string' ? containerMinWidths[size] : undefined;

      position['top'] = rect.top;
      position['height'] = rect.height;
      position['minInlineSize'] =
        sizeMinWidth !== undefined
          ? Math.min(sizeMinWidth, containerMaxWidth)
          : 0;

      const fillDeduction =
        size === 'fill' &&
        layoutMode === LAYOUT_MODE_SIDE_BY_SIDE &&
        siblingFlyoutWidth
          ? siblingFlyoutWidth
          : 0;

      if (isChildFlyout) {
        // beside the main flyout (side-by-side) or over it (stacked)
        const siblingPx = siblingFlyoutWidth || 0;
        if (side === 'left') position['left'] = rect.left + siblingPx;
        else position['right'] = containerRightOffset + siblingPx;
      } else if (side === 'left') {
        position['left'] = rect.left;
      } else {
        position['right'] = containerRightOffset;
      }

      if (containerRelativeWidth !== undefined) {
        position['inlineSize'] = Math.min(
          Math.max(0, containerRelativeWidth - fillDeduction),
          containerMaxWidth
        );
      } else {
        position['maxInlineSize'] = containerMaxWidth;
      }
    }

    return reactInlineStyle({ ...childStyle, ...composed, ...position });
  }

  /** Upstream overrides the mask's z-index with an `!important` class. */
  @cached
  get maskClass() {
    return euiClass(getEuiThemeContext(this), {
      zIndex: `${this.zIndex.mask} !important`
    });
  }

  get closeButtonClass() {
    const extra =
      this.args.closeButtonProps?.className ??
      this.args.closeButtonProps?.classes;
    return ['euiFlyout__closeButton', extra].filter(Boolean).join(' ');
  }

  /**
   * Upstream's close button `css`: positioning (`euiFlyout__closeButton`,
   * `outsideSide`) plus the look (`inside`: transparent background;
   * `outside`: XL shadow, no animation), composed into EuiButtonIcon's own
   * class through `@css` (`closeButtonCss`).
   */
  @cached
  get closeButtonPositionCss() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutCloseButtonStyles);
    return [
      styles.euiFlyout__closeButton,
      this.closeButtonPosition === 'outside'
        ? styles.outsideSide[this.side]
        : undefined
    ];
  }

  @cached
  get closeButtonLookCss() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutCloseButtonStyles);
    return styles[this.closeButtonPosition];
  }

  @cached
  get closeButtonCss() {
    return [...this.closeButtonPositionCss, this.closeButtonLookCss];
  }

  @cached
  get descriptionClass() {
    return euiScreenReaderOnlyClass(getEuiThemeContext(this));
  }

  @cached
  get focusTrapOptions() {
    const options = this.args.focusTrapOptions ?? {
      allowOutsideClick: true,
      clickOutsideDeactivates: !this.ownFocus,
      escapeDeactivates: false,
      // upstream's focus lock tolerates flyouts without tabbable content
      fallbackFocus: () => this.element as HTMLElement
    };
    const returnFocus = this.args.focusTrapProps?.returnFocus;

    if (returnFocus === false) {
      return { ...options, returnFocusOnDeactivate: false };
    }
    if (typeof returnFocus === 'function') {
      return {
        ...options,
        setReturnFocus: (previous: HTMLElement | SVGElement) =>
          returnFocus(previous) === false ? false : previous
      };
    }
    return options;
  }

  /**
   * Extra focus trap containers: `focusTrapProps.shards` and, for a
   * side-by-side child, its main flyout (one modal unit with the child).
   */
  get focusTrapShards(): HTMLElement[] | undefined {
    const shards = [...(this.args.focusTrapProps?.shards ?? [])];
    if (this.isSideBySideChild) {
      shards.push(
        ...Array.from(
          document.querySelectorAll<HTMLElement>(
            `[${PROPERTY_LEVEL}="${LEVEL_MAIN}"]`
          )
        )
      );
    }
    return shards.length ? shards : undefined;
  }

  get description() {
    return this.hasOverlayMask
      ? this.euiI18n.lookupToken(
          'euiFlyout.screenReaderModalDialog',
          'You are in a modal dialog. Press Escape or tap/click outside the dialog on the shadowed overlay to close.'
        )
      : this.euiI18n.lookupToken(
          'euiFlyout.screenReaderNoOverlayMaskDialog',
          'You are in a modal dialog. To close the dialog, press Escape.'
        );
  }

  get closeLabel() {
    return (
      this.args.closeButtonAriaLabel ??
      this.args.closeAriaLabel ??
      this.euiI18n.lookupToken(
        'euiFlyoutCloseButton.ariaLabel',
        'Close this dialog'
      )
    );
  }

  /** Clicks outside close only without a mask and with `@outsideClickCloses`. */
  get outsideClickDisabled() {
    return (
      this.isPushed ||
      this.hasOverlayMask ||
      this.args.outsideClickCloses !== true
    );
  }

  /**
   * Escape closes a standard flyout, a managed one without a child, or the
   * child; not a main flyout while it has a child, nor a managed flyout of
   * a backgrounded session (hidden; an Ember deviation, see the handoff).
   */
  get shouldCloseOnEscape(): boolean {
    if (!this.level) return true;
    if (!this.isActiveManagedFlyout) return false;
    if (!this.currentSession?.childFlyoutId) return true;
    return this.isChildFlyout;
  }

  // Closing

  /**
   * Upstream `handleClose`. A managed flyout updates the manager first
   * (closing its children, or its whole history group for a main flyout),
   * then calls `@onClose`.
   */
  handleClose = (event?: Event, reason?: EuiFlyoutCloseReason) => {
    const meta = reason ? { reason } : undefined;

    if (this.level) {
      this.wasRegistered = false;
      this.closeOwnFlyouts(this.level);
      this.args.onClose?.(event ?? new MouseEvent('click'), meta);
      return;
    }

    this.args.onClose?.(event, meta);
  };

  /** EuiFlyoutContext: what `EuiFlyoutMenu` calls by default. */
  close = (event?: Event, meta?: EuiFlyoutCloseMeta) => {
    this.handleClose(event, meta?.reason);
  };

  closeFromMenu = (event: MouseEvent) => {
    this.handleClose(event, 'close-button');
  };

  /**
   * A main flyout closes its history group, unless a newer session
   * backgrounded it (then only its own session goes); a child closes itself.
   */
  private closeOwnFlyouts(level: EuiFlyoutLevel, flyoutId = this.flyoutId) {
    const manager = this.manager;
    if (level !== LEVEL_MAIN) {
      manager.closeFlyout(flyoutId);
      return;
    }
    const { sessions } = manager.getState();
    const ownSession = sessions.find(
      (session) => session.mainFlyoutId === flyoutId
    );
    const isBackgroundedMain =
      ownSession != null && ownSession !== sessions[sessions.length - 1];
    if (isBackgroundedMain) manager.closeFlyout(flyoutId);
    else manager.closeAllFlyouts();
  }

  onMaskClick = (event?: Event) => {
    if (this.args.outsideClickCloses !== false)
      this.handleClose(event, 'outside-click');
  };

  onOutsideClick = (event: Event) => {
    this.handleClose(event, 'outside-click');
  };

  onKeyDown = (event: KeyboardEvent) => {
    if (!this.isPushed && event.key === 'Escape' && this.shouldCloseOnEscape) {
      event.preventDefault();
      this.handleClose(event, 'escape');
    }
  };

  onCloseButtonClick = (event: MouseEvent) => {
    this.handleClose(event, 'close-button');
    this.args.closeButtonProps?.onClick?.(event);
  };

  onWindowResize = () => {
    this.windowWidth = window.innerWidth;
  };

  // Manager lifecycle (upstream EuiManagedFlyout effects)

  /**
   * Registers the flyout with the manager while rendered: managed flyouts
   * with their title, level and size; standard ones for z-index stacking.
   */
  registration = valueModifier(
    (
      element: Element,
      [flyoutId, level, size, minWidth, historyKey, iconType, menuTitle]: [
        string,
        EuiFlyoutLevel | null,
        number | string,
        number | undefined,
        symbol | undefined,
        IconType | undefined,
        string | undefined
      ]
    ) => {
      const manager = this.manager;

      if (!level) {
        afterRender(() => manager.addUnmanagedFlyout(flyoutId));
        return () => afterRender(() => manager.closeUnmanagedFlyout(flyoutId));
      }

      let title = menuTitle || element.getAttribute('aria-label') || '';
      if (level === LEVEL_MAIN && !title) {
        const defaultTitle = this.euiI18n.lookupToken(
          'euiFlyoutManaged.defaultTitle',
          'Unknown Flyout'
        );
        console.warn(
          `Managed flyout "${flyoutId}" requires a title, which can be provided through 'flyoutMenuProps.title' or 'aria-label'. Using default title: "${defaultTitle}"`
        );
        title = defaultTitle;
      }

      afterRender(() => {
        manager.addFlyout(
          flyoutId,
          title,
          level,
          String(size),
          level === LEVEL_MAIN ? historyKey : undefined,
          iconType,
          typeof minWidth === 'number' ? minWidth : undefined
        );
        if (manager.peekIsRegistered(flyoutId)) this.wasRegistered = true;
      });

      return () => {
        const onClose = this.args.onClose;
        const wasRegistered = this.wasRegistered;
        this.wasRegistered = false;

        afterRender(() => {
          if (manager.peekIsRegistered(flyoutId)) {
            // unrendered (or its arguments changed) while registered
            this.closeOwnFlyouts(level, flyoutId);
          } else if (wasRegistered) {
            // removed from the manager while rendered: report why
            onClose?.(
              new MouseEvent('navigation'),
              manager.consumeCloseMeta(flyoutId) ?? {
                reason: 'navigation-cascade'
              }
            );
          }
        });
      };
    }
  );

  /**
   * A managed flyout the manager removed while it is still rendered (Back,
   * history navigation, its main flyout closing) calls `@onClose`.
   */
  watchRegistration = valueModifier(
    (_element: Element, [isRegistered]: [boolean]) => {
      if (!this.level) return;
      if (isRegistered) {
        this.wasRegistered = true;
        return;
      }
      if (!this.wasRegistered) return;

      this.wasRegistered = false;
      const flyoutId = this.flyoutId;
      afterRender(() => {
        if (this.isDestroying || this.isDestroyed) return;
        this.args.onClose?.(
          new MouseEvent('navigation'),
          this.manager.consumeCloseMeta(flyoutId) ?? {
            reason: 'navigation-cascade'
          }
        );
      });
    }
  );

  /** `@onActive` when this flyout becomes the current session's main or child. */
  watchActive = valueModifier(
    (_element: Element, [session]: [FlyoutSession | null]) => {
      if (!this.args.onActive || !session || !this.level) return;
      const mainChanged =
        this.level === LEVEL_MAIN && session.mainFlyoutId === this.flyoutId;
      const childChanged =
        this.level === LEVEL_CHILD && session.childFlyoutId === this.flyoutId;
      if (mainChanged || childChanged) {
        afterRender(() => {
          if (!this.isDestroying && !this.isDestroyed) this.args.onActive?.();
        });
      }
    }
  );

  /** Activity stage transitions (upstream `useFlyoutActivityStage`, no animation). */
  syncStage = valueModifier(
    (
      _element: Element,
      [stage, isActive, hasChild, layoutMode, level]: [
        EuiFlyoutActivityStage | undefined,
        boolean | undefined,
        boolean | undefined,
        EuiFlyoutLayoutMode | undefined,
        EuiFlyoutLevel | null
      ]
    ) => {
      if (!stage || !level) return;
      const next = getStageTransition(
        {
          stage,
          isActive: Boolean(isActive),
          hasChild: Boolean(hasChild),
          layoutMode: layoutMode ?? LAYOUT_MODE_SIDE_BY_SIDE
        },
        level,
        false
      );
      if (!next) return;
      const flyoutId = this.flyoutId;
      afterRender(() => {
        if (this.manager.peekIsRegistered(flyoutId))
          this.manager.setActivityStage(flyoutId, next);
      });
    }
  );

  onAnimationEnd = () => {
    const stage = this.activity?.stage;
    if (!stage) return;
    const next = getNextStage(stage);
    if (next && next !== stage) {
      this.manager.setActivityStage(this.flyoutId, next);
    }
  };

  /** The active managed flyout's width, for the child offset and layout mode. */
  observeManagedWidth = valueModifier(
    (element: Element, [isActive]: [boolean]) => {
      if (!isActive || typeof ResizeObserver === 'undefined') return;
      const observer = new ResizeObserver(([entry]) => {
        const box = entry?.borderBoxSize?.[0];
        const width = box
          ? box.inlineSize
          : element.getBoundingClientRect().width;
        // next frame, like upstream's `useResizeObserver` (no observer loop)
        nextFrame(() => {
          if (this.isDestroying || this.isDestroyed || !width) return;
          if (getFlyout(this.manager.getState(), this.flyoutId)?.width === width)
            return;
          this.manager.setFlyoutWidth(this.flyoutId, width);
        });
      });
      observer.observe(element);
      return () => observer.disconnect();
    }
  );

  /**
   * The active main flyout publishes its resized width as
   * `--euiFlyoutMainWidth`, so its child follows the drag without a lag.
   */
  publishMainWidth = valueModifier(
    (_element: Element, [enabled, size]: [boolean | undefined, unknown]) => {
      if (!enabled || typeof size !== 'string' || !size.endsWith('%')) return;
      const { style } = document.documentElement;
      style.setProperty('--euiFlyoutMainWidth', size);
      return () => {
        if (style.getPropertyValue('--euiFlyoutMainWidth') === size) {
          style.removeProperty('--euiFlyoutMainWidth');
        }
      };
    }
  );

  /** Push padding of a managed flyout is reported to the manager. */
  onManagedPushOffset = (side: 'left' | 'right', width: number) => {
    const manager = this.manager;
    afterRender(() => {
      if (manager.getState().pushPadding?.[side] !== width)
        manager.setPushPadding(side, width);
    });
  };

  get pushPaddingWidth(): number | undefined {
    const siblingWidth = this.siblingFlyout?.width;
    return this.layoutMode === LAYOUT_MODE_STACKED &&
      this.isMainFlyout &&
      siblingWidth
      ? siblingWidth
      : this.width;
  }

  /** A managed flyout pushes only while its session is the active one. */
  get shouldPush(): boolean {
    return this.isPushed && (!this.level || this.isActiveManagedFlyout);
  }

  /** Measures the container (size, scroll, window resize) and reports it to the manager. */
  trackContainer = valueModifier(
    (_element: Element, [container]: [HTMLElement | null]) => {
      if (!container) return;
      const manager = this.manager;

      const update = () => {
        if (this.isDestroying || this.isDestroyed) return;
        const next = container.getBoundingClientRect();
        const previous = this.containerRect;
        if (
          !previous ||
          previous.top !== next.top ||
          previous.left !== next.left ||
          previous.width !== next.width ||
          previous.height !== next.height
        ) {
          this.containerRect = next;
        }
      };

      let release: (() => void) | undefined;
      afterRender(() => {
        update();
        release = manager.useContainer(container);
      });

      const observer =
        typeof ResizeObserver === 'undefined'
          ? undefined
          : new ResizeObserver(([entry]) => {
              const width = entry?.contentRect.width ?? container.clientWidth;
              nextFrame(() => {
                if (this.isDestroying || this.isDestroyed) return;
                if (width !== this.containerWidth) this.containerWidth = width;
                update();
              });
            });
      observer?.observe(container);
      window.addEventListener('scroll', update, { passive: true });
      window.addEventListener('resize', update, { passive: true });

      return () => {
        observer?.disconnect();
        window.removeEventListener('scroll', update);
        window.removeEventListener('resize', update);
        afterRender(() => release?.());
      };
    }
  );

  // Resizing (upstream `useEuiFlyoutResizable`)

  /**
   * Clamps to `@minWidth` (which wins) and the smaller of `@maxWidth` and 90%
   * of the reference width, less a side-by-side sibling (its `minWidth` for
   * a fill sibling).
   */
  private clampWidth(width: number): number {
    const maxWidth =
      typeof this.args.maxWidth === 'number' ? this.args.maxWidth : Infinity;
    const sibling = this.siblingFlyout;
    const siblingWidth =
      sibling?.size === 'fill' ? sibling.minWidth : this.siblingFlyoutWidth;
    const reference = this.referenceWidth;
    const maxResizeWidth = siblingWidth
      ? reference * 0.9 - siblingWidth
      : reference * 0.9;
    const upperBound = Math.min(maxWidth || Infinity, maxResizeWidth);

    return Math.max(this.args.minWidth ?? 0, Math.min(width, upperBound));
  }

  private setResizeWidth(width: number): void {
    if (width === this.resizeWidth) return;

    this.resizeWidth = width;
    if (this.callOnResize) this.args.onResize?.(width);
  }

  /** Measures the rendered flyout as the starting width. */
  private measure(element: Element): void {
    if (this.isDestroying || this.isDestroyed || this.resizeWidth) return;

    this.callOnResize = false;
    this.resizeWidth = this.clampWidth((element as HTMLElement).offsetWidth);
  }

  /**
   * Resets the width when the consumer's `@size` changes and rescales it
   * (keeping its share of the window) when the window resizes.
   */
  resizeSync = functionModifier(
    (
      element: Element,
      [resizable, size, referenceWidth]: [boolean, unknown, number]
    ) => {
      if (!resizable) return;

      schedule('afterRender', () => {
        if (this.isDestroying || this.isDestroyed) return;

        if (this.resizeSizeArg !== size) {
          this.resizeSizeArg = size;
          this.resizeReferenceWidth = referenceWidth;
          this.callOnResize = false;
          this.resizeWidth =
            typeof size === 'number' ? this.clampWidth(size) : 0;
          // measured once the named size is rendered
          next(() => this.measure(element));
        } else {
          const previous = this.resizeReferenceWidth;

          this.resizeReferenceWidth = referenceWidth;
          if (this.resizeWidth && previous > 0 && referenceWidth > 0) {
            this.setResizeWidth(
              this.clampWidth(this.resizeWidth * (referenceWidth / previous))
            );
          }
        }
      });
    }
  );

  /** `1` grows the flyout towards the page when the pointer moves right. */
  private get resizeDirection(): number {
    let direction = this.side === 'right' ? -1 : 1;

    if (
      this.element &&
      window.getComputedStyle(this.element).direction === 'rtl'
    ) {
      direction *= -1;
    }

    return direction;
  }

  private pointerX(event: MouseEvent | TouchEvent): number {
    return 'touches' in event
      ? (event.touches[0]?.clientX ?? event.changedTouches[0]?.clientX ?? 0)
      : event.clientX;
  }

  private onDrag = (event: MouseEvent | TouchEvent) => {
    const offset = this.pointerX(event) - this.dragStartX;

    this.setResizeWidth(
      this.clampWidth(this.dragStartWidth + offset * this.resizeDirection)
    );
  };

  private onDragEnd = () => {
    this.stopDragging();
    this.callOnResize = true;
    this.args.onResize?.(this.resizeWidth);
  };

  private stopDragging = () => {
    window.removeEventListener('mousemove', this.onDrag);
    window.removeEventListener('mouseup', this.onDragEnd);
    window.removeEventListener('touchmove', this.onDrag);
    window.removeEventListener('touchend', this.onDragEnd);
  };

  onResizeStart = (event: MouseEvent | TouchEvent) => {
    this.callOnResize = false;
    this.dragStartX = this.pointerX(event);
    this.dragStartWidth = this.element
      ? (this.element as HTMLElement).offsetWidth
      : 0;

    // on the window, in case the pointer leaves the handle
    window.addEventListener('mousemove', this.onDrag);
    window.addEventListener('mouseup', this.onDragEnd);
    window.addEventListener('touchmove', this.onDrag);
    window.addEventListener('touchend', this.onDragEnd);
  };

  onResizeKeyDown = (event: KeyboardEvent) => {
    if (event.key !== 'ArrowRight' && event.key !== 'ArrowLeft') return;

    // Safari + VoiceOver would navigate off the button otherwise
    event.preventDefault();

    const wasCalling = this.callOnResize;
    const previous = this.resizeWidth;
    const step = (event.key === 'ArrowRight' ? 1 : -1) * 10;

    this.callOnResize = true;
    this.setResizeWidth(
      this.clampWidth(this.resizeWidth + step * this.resizeDirection)
    );
    // the first key press reports even when already at a limit
    if (!wasCalling && this.resizeWidth === previous) {
      this.args.onResize?.(this.resizeWidth);
    }
  };

  setWidth = (width: number) => {
    if (!this.containerElement) {
      if (width !== this.width) this.width = width;
      return;
    }
    // padding the observed container in the same frame would loop its observer
    nextFrame(() => {
      if (!this.isDestroying && !this.isDestroyed && width !== this.width)
        this.width = width;
    });
  };

  <template>
    {{#each this.routes key="@identity" as |_route|}}
      {{#unless this.isOrphanChild}}
        {{#if this.validManagedSize}}
          {{(setBodyClass "euiBody--hasFlyout")}}
          {{#if this.hasOverlayMask}}
            <EuiOverlayMask
              class={{this.maskClass}}
              @headerZindexLocation={{this.headerZindexLocation}}
              @hasAnimation={{this.hasAnimation}}
              @onClick={{this.onMaskClick}}
              {{maskContainerRect this.containerRect}}
            />
          {{/if}}
          {{#let (element this.as) as |TheElement|}}
            {{#if this.isPushed}}
              <TheElement
                class={{this.classes}}
                role={{this.role}}
                id={{if this.level this.flyoutId}}
                data-managed-flyout={{if this.level "true"}}
                data-managed-flyout-layout-mode={{if this.level this.layoutMode}}
                data-managed-flyout-level={{this.level}}
                ...attributes
                {{style this.inlineStyle}}
{{this.registerElement}}
                {{this.resizeSync this.resizable @size this.referenceWidth}}
                {{focusTrap
          _createFocusTrap=focusTrapFactory
                  isActive=(if (eq @isFocusTrapActive false) false true)
                  shouldSelfFocus=(if (eq @shouldSelfFocus false) false true)
                  isPaused=this.isPushed
                  focusTrapOptions=this.focusTrapOptions
                  additionalElements=this.focusTrapShards
                }}
                {{outsideClickDetectorModifier
                  isDisabled=this.outsideClickDisabled
                  onOutsideClick=this.onOutsideClick
                }}
                {{dialogDescription this.descriptionId enabled=false}}
                {{observeWidth this.setWidth this.isPushed}}
                {{pushFlyoutPadding
                  id=this.id
                  side=this.side
                  width=this.pushPaddingWidth
                  isPushed=this.shouldPush
                  container=this.containerElement
                  onManagedOffset=(if this.level this.onManagedPushOffset)
                }}
                {{windowResize this.onWindowResize this.tracksWindowWidth}}
                {{windowKeydown this.onKeyDown}}
                {{this.registration
                  this.flyoutId
                  this.level
                  this.sizeArg
                  @minWidth
                  @historyKey
                  @flyoutMenuProps.iconType
                  @flyoutMenuProps.title
                }}
                {{this.watchRegistration this.isRegistered}}
                {{this.watchActive this.currentSession}}
                {{this.syncStage
                  this.activity.stage
                  this.activity.isActive
                  this.activity.hasChild
                  this.activity.layoutMode
                  this.level
                }}
                {{this.observeManagedWidth this.isActiveManagedFlyout}}
                {{this.publishMainWidth
                  (if this.isMainFlyout this.isActiveManagedFlyout)
                  this.size
                }}
                {{this.trackContainer this.containerElement}}
                {{labelledBy this.labelledById}}
                {{on "animationend" this.onAnimationEnd}}
              >
                {{#if this.shouldRenderMenu}}
                  <FlyoutMenu
                    @props={{this.menuProps}}
                    @titleId={{this.menuTitleId}}
                    @onClose={{this.closeFromMenu}}
                  />
                {{else if this.showCloseButton}}
                  <EuiButtonIcon
                    @display={{if
                      (eq this.closeButtonPosition "outside")
                      "fill"
                      "empty"
                    }}
                    @iconType="cross"
                    @color="text"
                    @css={{this.closeButtonCss}}
                    aria-label={{this.closeLabel}}
                    data-test-subj="euiFlyoutCloseButton"
                    class={{this.closeButtonClass}}
                    {{on "click" this.onCloseButtonClick}}
                  />
                {{/if}}
                {{#if this.resizable}}
                  <EuiFlyoutResizeButton
                    @type={{this.type}}
                    @side={{this.side}}
                    @ownFocus={{this.ownFocus}}
                    {{on "mousedown" this.onResizeStart}}
                    {{on "touchstart" this.onResizeStart}}
                    {{on "keydown" this.onResizeKeyDown}}
                  />
                {{/if}}
                <div
                  class={{this.contentClass}}
                  data-test-subj="euiFlyoutContent"
                >
                  {{yield}}
                </div>
              </TheElement>
            {{else}}
              <EuiPortal>
                <TheElement
                  class={{this.classes}}
                  role={{this.role}}
                  aria-modal={{this.ariaModal}}
                  tabindex="0"
                  data-autofocus="true"
                  id={{if this.level this.flyoutId}}
                  data-managed-flyout={{if this.level "true"}}
                  data-managed-flyout-layout-mode={{if
                    this.level
                    this.layoutMode
                  }}
                  data-managed-flyout-level={{this.level}}
                  ...attributes
                  {{style this.inlineStyle}}
{{this.registerElement}}
                  {{this.resizeSync this.resizable @size this.referenceWidth}}
                  {{focusTrap
          _createFocusTrap=focusTrapFactory
                    isActive=(if (eq @isFocusTrapActive false) false true)
                    shouldSelfFocus=(if (eq @shouldSelfFocus false) false true)
                    isPaused=this.isPushed
                    focusTrapOptions=this.focusTrapOptions
                    additionalElements=this.focusTrapShards
                  }}
                  {{outsideClickDetectorModifier
                    isDisabled=this.outsideClickDisabled
                    onOutsideClick=this.onOutsideClick
                  }}
                  {{dialogDescription this.descriptionId}}
                  {{windowResize this.onWindowResize this.tracksWindowWidth}}
                  {{windowKeydown this.onKeyDown}}
                  {{this.registration
                    this.flyoutId
                    this.level
                    this.sizeArg
                    @minWidth
                    @historyKey
                    @flyoutMenuProps.iconType
                    @flyoutMenuProps.title
                  }}
                  {{this.watchRegistration this.isRegistered}}
                  {{this.watchActive this.currentSession}}
                  {{this.syncStage
                    this.activity.stage
                    this.activity.isActive
                    this.activity.hasChild
                    this.activity.layoutMode
                    this.level
                  }}
                  {{this.observeManagedWidth this.isActiveManagedFlyout}}
                  {{this.publishMainWidth
                    (if this.isMainFlyout this.isActiveManagedFlyout)
                    this.size
                  }}
                  {{this.trackContainer this.containerElement}}
                  {{labelledBy this.labelledById}}
                  {{on "animationend" this.onAnimationEnd}}
                >
                  {{! upstream EuiScreenReaderOnly clones its child: a bare <p> }}
                  <p
                    id={{this.descriptionId}}
                    class={{this.descriptionClass}}
                  >{{this.description}}</p>
                  {{#if this.shouldRenderMenu}}
                    <FlyoutMenu
                      @props={{this.menuProps}}
                      @titleId={{this.menuTitleId}}
                      @onClose={{this.closeFromMenu}}
                    />
                  {{else if this.showCloseButton}}
                    <EuiButtonIcon
                      @display={{if
                        (eq this.closeButtonPosition "outside")
                        "fill"
                        "empty"
                      }}
                      @iconType="cross"
                      @color="text"
                      @css={{this.closeButtonCss}}
                      aria-label={{this.closeLabel}}
                      data-test-subj="euiFlyoutCloseButton"
                      class={{this.closeButtonClass}}
                      {{on "click" this.onCloseButtonClick}}
                    />
                  {{/if}}
                  {{#if this.resizable}}
                    <EuiFlyoutResizeButton
                      @type={{this.type}}
                      @side={{this.side}}
                      @ownFocus={{this.ownFocus}}
                      {{on "mousedown" this.onResizeStart}}
                      {{on "touchstart" this.onResizeStart}}
                      {{on "keydown" this.onResizeKeyDown}}
                    />
                  {{/if}}
                  <div
                    class={{this.contentClass}}
                    data-test-subj="euiFlyoutContent"
                  >
                    {{yield}}
                  </div>
                </TheElement>
              </EuiPortal>
            {{/if}}
          {{/let}}
        {{/if}}
      {{/unless}}
    {{/each}}
  </template>
}

/** `@flyoutMenuProps` spread onto EuiFlyoutMenu. */
const FlyoutMenu: TOC<{
  Args: {
    props: EuiFlyoutMenuProps | undefined;
    titleId: string | undefined;
    onClose: (event: MouseEvent) => void;
  };
}> = <template>
  <EuiFlyoutMenu
    @title={{@props.title}}
    @titleId={{@titleId}}
    @hideTitle={{@props.hideTitle}}
    @hideCloseButton={{@props.hideCloseButton}}
    @showBackButton={{@props.showBackButton}}
    @backButtonProps={{@props.backButtonProps}}
    @historyItems={{@props.historyItems}}
    @leadingActions={{@props.leadingActions}}
    @trailingActions={{@props.trailingActions}}
    @customActions={{@props.customActions}}
    @pagination={{@props.pagination}}
    @onClose={{@onClose}}
  />
</template>;

const UNSET = Symbol('unset');

function eq(a: unknown, b: unknown) {
  return a === b;
}

