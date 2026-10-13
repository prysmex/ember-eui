/*
 * Ported from @elastic/eui 123.1.0 `components/flyout/manager/activity_stage.ts`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 *
 * Upstream's `useFlyoutActivityStage` hook split into pure functions: the
 * stage a flyout has in the manager state, the transition its effect makes,
 * and the stage `onAnimationEnd` moves to. EuiFlyout applies them.
 */
import {
  LAYOUT_MODE_SIDE_BY_SIDE,
  LAYOUT_MODE_STACKED,
  LEVEL_MAIN,
  STAGE_ACTIVE,
  STAGE_BACKGROUNDED,
  STAGE_BACKGROUNDING,
  STAGE_CLOSING,
  STAGE_INACTIVE,
  STAGE_OPENING,
  STAGE_RETURNING
} from './const.ts';

import type {
  EuiFlyoutActivityStage,
  EuiFlyoutLayoutMode,
  EuiFlyoutLevel,
  EuiFlyoutManagerState
} from './types.ts';

/**
 * Returns the final stage after an animation completes.
 * OPENING/RETURNING -> ACTIVE; CLOSING -> INACTIVE; BACKGROUNDING -> BACKGROUNDED.
 */
export const getNextStage = (
  stage: EuiFlyoutActivityStage
): EuiFlyoutActivityStage | null => {
  switch (stage) {
    case STAGE_OPENING:
    case STAGE_RETURNING:
      return STAGE_ACTIVE;
    case STAGE_CLOSING:
      return STAGE_INACTIVE;
    case STAGE_BACKGROUNDING:
      return STAGE_BACKGROUNDED;
    default:
      return null;
  }
};

export interface EuiFlyoutActivity {
  /** The flyout's stage (stored, else ACTIVE/INACTIVE from `isActive`). */
  stage: EuiFlyoutActivityStage;
  /** Main or child of the latest session. */
  isActive: boolean;
  /** Its session has a child flyout. */
  hasChild: boolean;
  layoutMode: EuiFlyoutLayoutMode;
}

/** Derives the activity inputs of a flyout from the manager state. */
export const getFlyoutActivity = (
  state: EuiFlyoutManagerState | null | undefined,
  flyoutId: string
): EuiFlyoutActivity => {
  const sessions = state?.sessions;
  const currentSession = sessions
    ? (sessions[sessions.length - 1] ?? null)
    : null;
  const isActive =
    currentSession?.mainFlyoutId === flyoutId ||
    currentSession?.childFlyoutId === flyoutId;

  const session =
    state?.sessions.find(
      (s) => s.mainFlyoutId === flyoutId || s.childFlyoutId === flyoutId
    ) ?? null;
  const hasChild = !!session?.childFlyoutId;

  const layoutMode = state?.layoutMode ?? LAYOUT_MODE_SIDE_BY_SIDE;

  const stage: EuiFlyoutActivityStage =
    state?.flyouts.find((f) => f.flyoutId === flyoutId)?.activityStage ||
    (isActive ? STAGE_ACTIVE : STAGE_INACTIVE);

  return { stage, isActive, hasChild, layoutMode };
};

/**
 * 1. ACTIVE -> CLOSING (or INACTIVE when !shouldAnimate) when no longer the active flyout.
 * 2. INACTIVE -> RETURNING (or ACTIVE when !shouldAnimate) when it becomes active again.
 * 3. (Main only) ACTIVE + stacked + has child -> BACKGROUNDING (or BACKGROUNDED when !shouldAnimate).
 * 4. (Main only) BACKGROUNDED/BACKGROUNDING + (child gone OR side-by-side) -> RETURNING (or ACTIVE when !shouldAnimate).
 *
 * Returns the stage to transition to, or `null` for none.
 */
export const getStageTransition = (
  { stage: s, isActive, hasChild, layoutMode }: EuiFlyoutActivity,
  level: EuiFlyoutLevel,
  shouldAnimate = false
): EuiFlyoutActivityStage | null => {
  let next: EuiFlyoutActivityStage | null = null;

  if (s === STAGE_ACTIVE && !isActive) {
    next = shouldAnimate ? STAGE_CLOSING : STAGE_INACTIVE;
  } else if (s === STAGE_INACTIVE && isActive) {
    next = shouldAnimate ? STAGE_RETURNING : STAGE_ACTIVE;
  } else if (
    level === LEVEL_MAIN &&
    isActive &&
    s === STAGE_ACTIVE &&
    hasChild &&
    layoutMode === LAYOUT_MODE_STACKED
  ) {
    next = shouldAnimate ? STAGE_BACKGROUNDING : STAGE_BACKGROUNDED;
  } else if (
    level === LEVEL_MAIN &&
    (s === STAGE_BACKGROUNDED || s === STAGE_BACKGROUNDING) &&
    (!hasChild || layoutMode === LAYOUT_MODE_SIDE_BY_SIDE)
  ) {
    next = shouldAnimate ? STAGE_RETURNING : STAGE_ACTIVE;
  }

  return next && next !== s ? next : null;
};
