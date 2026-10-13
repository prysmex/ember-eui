/*
 * Ported from @elastic/eui 123.1.0 `components/flyout/manager/selectors.ts`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 *
 * Upstream's selectors are React hooks reading the manager context. In Ember
 * they are plain functions of the manager state; the state is tracked on the
 * `eui-flyout-manager` service, so getters calling them stay reactive.
 */
import type {
  EuiFlyoutManagerState,
  EuiManagedFlyoutState,
  FlyoutSession,
  PushPaddingOffsets
} from './types.ts';

type State = EuiFlyoutManagerState | null | undefined;

/** The session a flyout belongs to (as main or current child), or `null`. */
export const getSession = (
  state: State,
  flyoutId?: string | null
): FlyoutSession | null => {
  if (!state) return null;

  return (
    state.sessions.find(
      (s) => s.mainFlyoutId === flyoutId || s.childFlyoutId === flyoutId
    ) || null
  );
};

/** The most recent flyout session or `null` if none. */
export const getCurrentSession = (state: State): FlyoutSession | null => {
  if (!state) return null;
  return state.sessions[state.sessions.length - 1] || null;
};

/** True when any managed flyout session is currently active. */
export const hasActiveSession = (state: State): boolean =>
  !!getCurrentSession(state);

/** True if the given `flyoutId` is the main or child flyout in the latest session. */
export const isFlyoutActive = (state: State, flyoutId: string): boolean => {
  const currentSession = getCurrentSession(state);
  return (
    currentSession?.mainFlyoutId === flyoutId ||
    currentSession?.childFlyoutId === flyoutId
  );
};

/** The registered state of a flyout, or `null`. */
export const getFlyout = (
  state: State,
  flyoutId?: string | null
): EuiManagedFlyoutState | null => {
  if (!state || !flyoutId) return null;
  return state.flyouts.find((f) => f.flyoutId === flyoutId) || null;
};

/** True if the flyout is registered with the manager. */
export const isFlyoutRegistered = (
  state: State,
  flyoutId?: string | null
): boolean => {
  if (!state || !flyoutId) return false;
  return state.flyouts.some((f) => f.flyoutId === flyoutId);
};

/** The registered state of the current session's main flyout, if present. */
export const getCurrentMainFlyout = (state: State) =>
  getFlyout(state, getCurrentSession(state)?.mainFlyoutId);

/** The registered state of the current session's child flyout, if present. */
export const getCurrentChildFlyout = (state: State) =>
  getFlyout(state, getCurrentSession(state)?.childFlyoutId);

/** The measured width (px) of the specified flyout, or `undefined` if unknown. */
export const getFlyoutWidth = (state: State, flyoutId?: string | null) =>
  getFlyout(state, flyoutId)?.width;

/** The store pagination override for a flyout, if set. */
export const getFlyoutPagination = (state: State, flyoutId?: string | null) =>
  getFlyout(state, flyoutId)?.pagination;

/** The configured minWidth (px) of the specified flyout, or `undefined` if not set. */
export const getFlyoutMinWidth = (state: State, flyoutId?: string | null) =>
  getFlyout(state, flyoutId)?.minWidth;

/** The configured size of the parent (main) flyout for a given child flyout ID. */
export const getParentFlyoutSize = (state: State, childFlyoutId: string) => {
  const session = getSession(state, childFlyoutId);
  return getFlyout(state, session?.mainFlyoutId)?.size;
};

/** True if the provided `flyoutId` is the main flyout and it currently has a child. */
export const hasChildFlyout = (state: State, flyoutId: string): boolean =>
  !!getSession(state, flyoutId)?.childFlyoutId;

/** The current push padding offsets from manager state. */
export const getPushPaddingOffsets = (state: State): PushPaddingOffsets => {
  if (!state) return { left: 0, right: 0 };
  return state.pushPadding ?? { left: 0, right: 0 };
};

/** True if there's any active push padding (left or right side). */
export const hasPushPadding = (state: State): boolean => {
  const pushPadding = getPushPaddingOffsets(state);
  return pushPadding.left > 0 || pushPadding.right > 0;
};
