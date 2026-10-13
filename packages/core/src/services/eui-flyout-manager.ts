/*
 * Ember port of @elastic/eui 123.1.0 `components/flyout/manager/store.ts`,
 * `provider.tsx` and the effects of `layout_mode.ts`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 *
 * Upstream keeps the manager state in a module-level store shared by every
 * React root. In Ember the owner-scoped service is that store: its `state`
 * is tracked, so every flyout getter reading it updates after a dispatch.
 */
import Service from '@ember/service';
import { getOwner } from '@ember/owner';
import { tracked } from '@glimmer/tracking';

import { nextFrame } from '../-private/next-frame.ts';
import {
  addFlyout as addFlyoutAction,
  addUnmanagedFlyout as addUnmanagedFlyoutAction,
  closeAllFlyouts as closeAllFlyoutsAction,
  closeFlyout as closeFlyoutAction,
  closeUnmanagedFlyout as closeUnmanagedFlyoutAction,
  goBack as goBackAction,
  goToFlyout as goToFlyoutAction,
  setActiveFlyout as setActiveFlyoutAction,
  setActivityStage as setActivityStageAction,
  setContainerElement as setContainerElementAction,
  setFlyoutWidth as setFlyoutWidthAction,
  setLayoutMode as setLayoutModeAction,
  setPagination as setPaginationAction,
  setPushPadding as setPushPaddingAction,
  setReferenceWidth as setReferenceWidthAction
} from '../utils/eui/flyout-manager/actions.ts';
import { LAYOUT_MODE_SIDE_BY_SIDE } from '../utils/eui/flyout-manager/const.ts';
import { computeHistoryItems } from '../utils/eui/flyout-manager/history.ts';
import { getDesiredLayoutMode } from '../utils/eui/flyout-manager/layout-mode.ts';
import {
  flyoutManagerReducer,
  initialState
} from '../utils/eui/flyout-manager/reducer.ts';
import {
  getCurrentSession,
  isFlyoutRegistered
} from '../utils/eui/flyout-manager/selectors.ts';

import type { EuiFlyoutMenuPagination } from '../components/eui-flyout-menu.gts';
import type { Action } from '../utils/eui/flyout-manager/actions.ts';
import type {
  EuiFlyoutActivityStage,
  EuiFlyoutCloseMeta,
  EuiFlyoutLayoutMode,
  EuiFlyoutLevel,
  EuiFlyoutManagerHistoryItem,
  EuiFlyoutManagerState,
  FlyoutSession,
  IconType
} from '../utils/eui/flyout-manager/types.ts';
import type EuiEmotionService from './eui-emotion.ts';

type Listener = () => void;

/** Events emitted by the flyout manager for external consumers. */
export type FlyoutManagerEvent = {
  type: 'CLOSE_SESSION';
  session: FlyoutSession;
};

type EventListener = (event: FlyoutManagerEvent) => void;

/** Borealis `breakpoint.s`, used when no theme service is registered. */
const DEFAULT_BREAKPOINT_S = 575;

/**
 * The flyout session manager (upstream `getFlyoutManagerStore()`): the state
 * and actions behind `EuiFlyout`'s `@session`. Flyouts use it internally;
 * apps can read its state, subscribe to `CLOSE_SESSION` events or call
 * `setPagination`, `closeAllFlyouts`, `goBack` and `goToFlyout`.
 */
export default class EuiFlyoutManagerService extends Service {
  /** The manager state; replaced (never mutated) on every change. */
  @tracked state: EuiFlyoutManagerState = initialState;

  /**
   * True when any managed flyout session is open. Only set when it changes,
   * so flyouts routing on it do not update on every dispatch.
   */
  @tracked hasActiveSession = false;

  /** History popover entries of the current session, most recent first. */
  @tracked historyItems: EuiFlyoutManagerHistoryItem[] = [];

  /** Untracked copy of `state`, for reads that must not subscribe. */
  private current: EuiFlyoutManagerState = initialState;
  private listeners = new Set<Listener>();
  private eventListeners = new Set<EventListener>();

  /**
   * One-shot close annotations keyed by flyout id: `goBack` stamps the
   * flyouts it removes so they report `navigation-back`.
   */
  private pendingCloseMeta = new Map<string, EuiFlyoutCloseMeta>();

  // Layout mode (upstream `useApplyFlyoutLayoutMode`)
  private windowWidth =
    typeof window !== 'undefined' ? window.innerWidth : Infinity;
  private containerWidth = 0;
  private resizeFrame = 0;
  private listeningToWindow = false;
  private observedContainer: HTMLElement | null = null;
  private containerObserver?: ResizeObserver;
  private applyingLayout = false;

  willDestroy(): void {
    super.willDestroy();
    this.stopWindowListener();
    this.observeContainer(null);
  }

  // Store API

  getState = (): EuiFlyoutManagerState => this.current;

  /** Calls `listener` after every state change; returns an unsubscribe. */
  subscribe = (listener: Listener): (() => void) => {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  };

  /** Calls `listener` with `CLOSE_SESSION` events; returns an unsubscribe. */
  subscribeToEvents = (listener: EventListener): (() => void) => {
    this.eventListeners.add(listener);
    return () => {
      this.eventListeners.delete(listener);
    };
  };

  dispatch = (action: Action): void => {
    const previousState = this.current;
    const nextState = flyoutManagerReducer(previousState, action);

    if (nextState === previousState) return;

    const previousSessions = previousState.sessions;
    this.current = nextState;
    this.state = nextState;

    const hasActiveSession = nextState.sessions.length > 0;
    if (hasActiveSession !== this.hasActiveSession) {
      this.hasActiveSession = hasActiveSession;
    }

    // Recompute history items eagerly if sessions changed
    if (nextState.sessions !== previousSessions) {
      this.historyItems = computeHistoryItems(nextState, this.dispatch);

      // Detect removed sessions and emit CLOSE_SESSION events
      const nextSessionIds = new Set(
        nextState.sessions.map((s) => s.mainFlyoutId)
      );
      previousSessions.forEach((session) => {
        if (!nextSessionIds.has(session.mainFlyoutId)) {
          this.eventListeners.forEach((listener) =>
            listener({ type: 'CLOSE_SESSION', session })
          );
        }
      });
    }

    // a layout update inside `applyLayout` is reported with the dispatch
    // that caused it (upstream applies it from the provider, separately)
    if (this.applyingLayout) return;
    this.applyLayout();
    this.listeners.forEach((l) => l());
  };

  addFlyout = (
    flyoutId: string,
    title: string,
    level?: EuiFlyoutLevel,
    size?: string,
    historyKey?: symbol,
    iconType?: IconType,
    minWidth?: number
  ): void =>
    this.dispatch(
      addFlyoutAction(
        flyoutId,
        title,
        level,
        size,
        historyKey,
        iconType,
        minWidth
      )
    );

  closeFlyout = (flyoutId: string): void =>
    this.dispatch(closeFlyoutAction(flyoutId));

  /** Closes every flyout of the current session's history group. */
  closeAllFlyouts = (): void => this.dispatch(closeAllFlyoutsAction());

  setActiveFlyout = (flyoutId: string | null): void =>
    this.dispatch(setActiveFlyoutAction(flyoutId));

  setFlyoutWidth = (flyoutId: string, width: number): void =>
    this.dispatch(setFlyoutWidthAction(flyoutId, width));

  /**
   * Sets (or clears) the menu pagination of a managed flyout; it takes
   * precedence over `flyoutMenuProps.pagination`.
   */
  setPagination = (
    flyoutId: string,
    pagination: EuiFlyoutMenuPagination | undefined
  ): void => this.dispatch(setPaginationAction(flyoutId, pagination));

  setPushPadding = (side: 'left' | 'right', width: number): void =>
    this.dispatch(setPushPaddingAction(side, width));

  setContainerElement = (element: HTMLElement | null): void =>
    this.dispatch(setContainerElementAction(element));

  setActivityStage = (
    flyoutId: string,
    activityStage: EuiFlyoutActivityStage
  ): void => this.dispatch(setActivityStageAction(flyoutId, activityStage));

  /** Back: pops the current child history, else the current session. */
  goBack = (): void => {
    // Stamp the flyouts goBack removes as `navigation-back` before
    // dispatching (vs. the default `navigation-cascade`).
    const action = goBackAction();
    const nextState = flyoutManagerReducer(this.current, action);
    const remaining = new Set(nextState.flyouts.map((f) => f.flyoutId));
    this.current.flyouts.forEach((f) => {
      if (!remaining.has(f.flyoutId)) {
        this.pendingCloseMeta.set(f.flyoutId, { reason: 'navigation-back' });
      }
    });
    this.dispatch(action);
  };

  goToFlyout = (flyoutId: string, level?: EuiFlyoutLevel): void =>
    this.dispatch(goToFlyoutAction(flyoutId, level));

  addUnmanagedFlyout = (flyoutId: string): void =>
    this.dispatch(addUnmanagedFlyoutAction(flyoutId));

  closeUnmanagedFlyout = (flyoutId: string): void =>
    this.dispatch(closeUnmanagedFlyoutAction(flyoutId));

  /** Reads and clears the close `meta` stamped for `flyoutId`. */
  consumeCloseMeta = (flyoutId: string): EuiFlyoutCloseMeta | undefined => {
    const meta = this.pendingCloseMeta.get(flyoutId);
    if (meta) {
      this.pendingCloseMeta.delete(flyoutId);
    }
    return meta;
  };

  // Tracked conveniences (upstream's selector hooks)


  /** The most recent session or `null`. */
  get currentSession(): FlyoutSession | null {
    return getCurrentSession(this.state);
  }

  /** `side-by-side` or `stacked`. */
  get layoutMode(): EuiFlyoutLayoutMode {
    return this.state.layoutMode ?? LAYOUT_MODE_SIDE_BY_SIDE;
  }

  /** Untracked registration check, for cleanup code. */
  peekIsRegistered(flyoutId: string): boolean {
    return isFlyoutRegistered(this.current, flyoutId);
  }

  // Layout mode

  private get breakpointS(): number {
    const emotion = getOwner(this)?.lookup('service:eui-emotion') as
      | EuiEmotionService
      | undefined;
    const value = (
      emotion?.context.upstream.euiTheme.breakpoint as
        | Record<string, number>
        | undefined
    )?.['s'];

    return typeof value === 'number' ? value : DEFAULT_BREAKPOINT_S;
  }

  private applyLayoutAndNotify(): void {
    const before = this.current;
    this.applyLayout();
    if (this.current !== before) this.listeners.forEach((l) => l());
  }

  /**
   * Uses `element` as the flyout container (upstream `setContainerElement`)
   * until the returned release is called. Several flyouts can share one
   * container; it is cleared when the last of them releases it.
   */
  useContainer(element: HTMLElement): () => void {
    this.containerUsers.set(element, (this.containerUsers.get(element) ?? 0) + 1);
    this.setContainerElement(element);

    let released = false;
    return () => {
      if (released) return;
      released = true;
      const users = (this.containerUsers.get(element) ?? 1) - 1;
      if (users > 0) {
        this.containerUsers.set(element, users);
        return;
      }
      this.containerUsers.delete(element);
      if (this.current.containerElement === element) {
        this.setContainerElement(null);
      }
    };
  }

  private containerUsers = new Map<HTMLElement, number>();

  /**
   * Upstream's layout effects: keeps the resize listeners in sync, switches
   * the layout mode and records the reference width while flyouts are open.
   */
  private applyLayout(): void {
    if (this.applyingLayout) return;
    this.applyingLayout = true;

    try {
      const state = this.current;
      const container = state.containerElement ?? null;
      const hasFlyouts = Boolean(getCurrentSession(state)?.mainFlyoutId);

      this.observeContainer(container);
      if (hasFlyouts && !container) this.startWindowListener();
      else this.stopWindowListener();

      const containerWidth = container
        ? this.containerWidth || container.clientWidth
        : 0;
      const referenceWidth = containerWidth || this.windowWidth;
      const desired = getDesiredLayoutMode(
        state,
        referenceWidth,
        this.breakpointS
      );

      if (desired && state.layoutMode !== desired) {
        this.dispatch(setLayoutModeAction(desired));
      }
      if (hasFlyouts && Number.isFinite(referenceWidth)) {
        this.dispatch(setReferenceWidthAction(referenceWidth));
      }
    } finally {
      this.applyingLayout = false;
    }
  }

  private onWindowResize = () => {
    if (this.resizeFrame) cancelAnimationFrame(this.resizeFrame);
    this.resizeFrame = requestAnimationFrame(() => {
      this.resizeFrame = 0;
      if (this.isDestroying || this.isDestroyed) return;
      this.windowWidth = window.innerWidth;
      this.applyLayoutAndNotify();
    });
  };

  private startWindowListener(): void {
    if (this.listeningToWindow || typeof window === 'undefined') return;
    this.listeningToWindow = true;
    this.windowWidth = window.innerWidth;
    window.addEventListener('resize', this.onWindowResize);
  }

  private stopWindowListener(): void {
    if (!this.listeningToWindow) return;
    this.listeningToWindow = false;
    if (this.resizeFrame) cancelAnimationFrame(this.resizeFrame);
    this.resizeFrame = 0;
    window.removeEventListener('resize', this.onWindowResize);
  }

  private observeContainer(container: HTMLElement | null): void {
    if (container === this.observedContainer) return;

    this.containerObserver?.disconnect();
    this.containerObserver = undefined;
    this.observedContainer = container;
    this.containerWidth = 0;

    if (!container || typeof ResizeObserver === 'undefined') return;

    this.containerObserver = new ResizeObserver(([entry]) => {
      const width = entry?.contentRect.width ?? container.clientWidth;
      // next frame, so the layout change cannot loop the observer
      nextFrame(() => {
        if (this.isDestroying || this.isDestroyed) return;
        if (width === this.containerWidth) return;
        this.containerWidth = width;
        this.applyLayoutAndNotify();
      });
    });
    this.containerObserver.observe(container);
  }
}

declare module '@ember/service' {
  interface Registry {
    'eui-flyout-manager': EuiFlyoutManagerService;
  }
}
