/*
 * Ported from @elastic/eui 123.1.0 `components/flyout/manager/activity_stage.test.tsx`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 *
 * Upstream tests the `useFlyoutActivityStage` hook; its stage derivation,
 * effect transitions and `onAnimationEnd` are the pure functions here.
 */
import { describe, expect, it } from '../../helpers/jest-compat.ts';
import {
  getFlyoutActivity,
  getNextStage,
  getStageTransition
} from '#src/utils/eui/flyout-manager/activity-stage.ts';
import {
  LAYOUT_MODE_SIDE_BY_SIDE,
  LAYOUT_MODE_STACKED,
  LEVEL_CHILD,
  LEVEL_MAIN,
  STAGE_ACTIVE,
  STAGE_BACKGROUNDED,
  STAGE_BACKGROUNDING,
  STAGE_CLOSING,
  STAGE_INACTIVE,
  STAGE_OPENING,
  STAGE_RETURNING
} from '#src/utils/eui/flyout-manager/const.ts';
import { initialState } from '#src/utils/eui/flyout-manager/reducer.ts';

import type {
  EuiFlyoutActivityStage,
  EuiFlyoutLayoutMode,
  EuiFlyoutManagerState
} from '#src/utils/eui/flyout-manager/types.ts';

const state = ({
  stage,
  active = true,
  child = false,
  layoutMode = LAYOUT_MODE_SIDE_BY_SIDE
}: {
  stage?: EuiFlyoutActivityStage;
  active?: boolean;
  child?: boolean;
  layoutMode?: EuiFlyoutLayoutMode;
}): EuiFlyoutManagerState => ({
  ...initialState,
  layoutMode,
  sessions: [
    {
      mainFlyoutId: active ? 'flyout-1' : 'other-main',
      childFlyoutId: child ? 'child-1' : null,
      title: 'Session',
      zIndex: 0,
      childHistory: [],
      historyKey: Symbol()
    }
  ],
  flyouts: [
    { flyoutId: 'flyout-1', level: LEVEL_MAIN, activityStage: stage }
  ]
});

const transition = (
  options: Parameters<typeof state>[0],
  level: 'main' | 'child' = LEVEL_MAIN,
  shouldAnimate = false
) => getStageTransition(getFlyoutActivity(state(options), 'flyout-1'), level, shouldAnimate);

describe('Unit | flyout manager | activity stage', () => {
  describe('initial state', () => {
    it('returns the activity stage from state when available', () => {
      expect(getFlyoutActivity(state({ stage: STAGE_OPENING }), 'flyout-1').stage).toBe(STAGE_OPENING);
    });

    it('returns STAGE_ACTIVE when the flyout is active but has no stage in state', () => {
      expect(getFlyoutActivity(state({}), 'flyout-1').stage).toBe(STAGE_ACTIVE);
    });

    it('returns STAGE_INACTIVE when the flyout is not active and has no stage in state', () => {
      expect(getFlyoutActivity(state({ active: false }), 'flyout-1').stage).toBe(STAGE_INACTIVE);
    });

    it('handles a missing flyout and a null state', () => {
      expect(getFlyoutActivity(state({}), 'missing').stage).toBe(STAGE_INACTIVE);
      expect(getFlyoutActivity(null, 'flyout-1')).toEqual({
        stage: STAGE_INACTIVE,
        isActive: false,
        hasChild: false,
        layoutMode: LAYOUT_MODE_SIDE_BY_SIDE
      });
    });
  });

  describe('stage transitions based on activity', () => {
    it('ACTIVE to INACTIVE (or CLOSING when animating) when no longer active', () => {
      expect(transition({ stage: STAGE_ACTIVE, active: false })).toBe(STAGE_INACTIVE);
      expect(transition({ stage: STAGE_ACTIVE, active: false }, LEVEL_MAIN, true)).toBe(STAGE_CLOSING);
    });

    it('INACTIVE to ACTIVE (or RETURNING when animating) when active again', () => {
      expect(transition({ stage: STAGE_INACTIVE })).toBe(STAGE_ACTIVE);
      expect(transition({ stage: STAGE_INACTIVE }, LEVEL_MAIN, true)).toBe(STAGE_RETURNING);
    });
  });

  describe('main flyout backgrounding logic', () => {
    it('BACKGROUNDED (or BACKGROUNDING when animating) when the main has a child and the layout is stacked', () => {
      const stacked = { stage: STAGE_ACTIVE, child: true, layoutMode: LAYOUT_MODE_STACKED } as const;
      expect(transition(stacked)).toBe(STAGE_BACKGROUNDED);
      expect(transition(stacked, LEVEL_MAIN, true)).toBe(STAGE_BACKGROUNDING);
    });

    it('does not background side by side, without a child, or for child flyouts', () => {
      expect(transition({ stage: STAGE_ACTIVE, child: true })).toBe(null);
      expect(transition({ stage: STAGE_ACTIVE, layoutMode: LAYOUT_MODE_STACKED })).toBe(null);
      expect(
        transition({ stage: STAGE_ACTIVE, child: true, layoutMode: LAYOUT_MODE_STACKED }, LEVEL_CHILD)
      ).toBe(null);
    });
  });

  describe('main flyout returning logic', () => {
    it('BACKGROUNDED or BACKGROUNDING to ACTIVE when the child is gone', () => {
      expect(transition({ stage: STAGE_BACKGROUNDED, layoutMode: LAYOUT_MODE_STACKED })).toBe(STAGE_ACTIVE);
      expect(transition({ stage: STAGE_BACKGROUNDING, layoutMode: LAYOUT_MODE_STACKED })).toBe(STAGE_ACTIVE);
      expect(
        transition({ stage: STAGE_BACKGROUNDED, layoutMode: LAYOUT_MODE_STACKED }, LEVEL_MAIN, true)
      ).toBe(STAGE_RETURNING);
    });

    it('BACKGROUNDED to ACTIVE when the layout is side by side again', () => {
      expect(transition({ stage: STAGE_BACKGROUNDED, child: true })).toBe(STAGE_ACTIVE);
    });

    it('stays backgrounded while it still has a child and the layout is stacked', () => {
      expect(
        transition({ stage: STAGE_BACKGROUNDED, child: true, layoutMode: LAYOUT_MODE_STACKED })
      ).toBe(null);
    });
  });

  describe('onAnimationEnd transitions', () => {
    it('finalizes transitional stages', () => {
      expect(getNextStage(STAGE_OPENING)).toBe(STAGE_ACTIVE);
      expect(getNextStage(STAGE_RETURNING)).toBe(STAGE_ACTIVE);
      expect(getNextStage(STAGE_CLOSING)).toBe(STAGE_INACTIVE);
      expect(getNextStage(STAGE_BACKGROUNDING)).toBe(STAGE_BACKGROUNDED);
    });

    it('does not transition when the stage is already final', () => {
      expect(getNextStage(STAGE_ACTIVE)).toBe(null);
      expect(getNextStage(STAGE_INACTIVE)).toBe(null);
      expect(getNextStage(STAGE_BACKGROUNDED)).toBe(null);
    });
  });

  describe('edge cases', () => {
    it('makes no transition when the stage is already correct', () => {
      expect(transition({ stage: STAGE_ACTIVE })).toBe(null);
      expect(transition({ stage: STAGE_INACTIVE, active: false })).toBe(null);
      expect(transition({ stage: STAGE_OPENING })).toBe(null);
    });
  });
});
