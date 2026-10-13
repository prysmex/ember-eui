/*
 * Ported from @elastic/eui 123.1.0 `components/flyout/manager/selectors.test.tsx`
 * (and the helpers of `manager/__mocks__`). Upstream renders the selector
 * hooks with a mocked context; here they are plain functions of the state.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 */
import { describe, expect, it } from '../../helpers/jest-compat.ts';
import { LEVEL_CHILD, LEVEL_MAIN } from '#src/utils/eui/flyout-manager/const.ts';
import { initialState } from '#src/utils/eui/flyout-manager/reducer.ts';
import {
  getCurrentChildFlyout,
  getCurrentMainFlyout,
  getCurrentSession,
  getFlyoutWidth,
  getParentFlyoutSize,
  getPushPaddingOffsets,
  hasActiveSession,
  hasChildFlyout,
  hasPushPadding,
  isFlyoutActive
} from '#src/utils/eui/flyout-manager/selectors.ts';

import type {
  EuiFlyoutManagerState,
  FlyoutSession
} from '#src/utils/eui/flyout-manager/types.ts';

const createTestState = (
  overrides: Partial<EuiFlyoutManagerState> = {}
): EuiFlyoutManagerState => ({ ...initialState, ...overrides });

const createTestSession = (
  mainFlyoutId: string,
  title: string,
  childFlyoutId: string | null = null
): FlyoutSession => ({
  mainFlyoutId,
  childFlyoutId,
  title,
  zIndex: 0,
  childHistory: [],
  historyKey: Symbol()
});

describe('Unit | flyout manager | selectors', () => {
  describe('getFlyoutWidth', () => {
    it('should return undefined when flyout is not found', () => {
      expect(getFlyoutWidth(createTestState(), 'non-existent-flyout')).toBeUndefined();
    });

    it('should return the width when flyout exists', () => {
      const state = createTestState({
        flyouts: [
          {
            flyoutId: 'test-flyout',
            level: LEVEL_MAIN,
            size: 'm',
            activityStage: 'active',
            width: 500
          }
        ]
      });
      expect(getFlyoutWidth(state, 'test-flyout')).toBe(500);
    });
  });

  describe('getParentFlyoutSize', () => {
    it('should return undefined when no parent flyout exists', () => {
      expect(getParentFlyoutSize(createTestState(), 'child-flyout')).toBeUndefined();
    });

    it('should return the size of the main flyout of a child', () => {
      const state = createTestState({
        sessions: [createTestSession('parent-flyout', 'Parent', 'child-flyout')],
        flyouts: [
          { flyoutId: 'parent-flyout', level: LEVEL_MAIN, size: 'l' },
          { flyoutId: 'child-flyout', level: LEVEL_CHILD, size: 's' }
        ]
      });
      expect(getParentFlyoutSize(state, 'child-flyout')).toBe('l');
    });
  });

  describe('hasChildFlyout', () => {
    it('should return false when no child flyout exists', () => {
      const state = createTestState({
        flyouts: [
          { flyoutId: 'parent-flyout', level: LEVEL_MAIN, size: 'm', activityStage: 'active' }
        ]
      });
      expect(hasChildFlyout(state, 'parent-flyout')).toBe(false);
    });

    it('should return true when child flyout exists', () => {
      const state = createTestState({
        sessions: [createTestSession('parent-flyout', 'Parent Flyout', 'child-flyout')],
        flyouts: [
          { flyoutId: 'parent-flyout', level: LEVEL_MAIN, size: 'm', activityStage: 'active' },
          { flyoutId: 'child-flyout', level: LEVEL_CHILD, size: 'm', activityStage: 'active' }
        ]
      });
      expect(hasChildFlyout(state, 'parent-flyout')).toBe(true);
    });
  });

  describe('sessions and push padding', () => {
    it('reads the current session and its flyouts', () => {
      const state = createTestState({
        sessions: [
          createTestSession('main-1', 'One'),
          createTestSession('main-2', 'Two', 'child-2')
        ],
        flyouts: [
          { flyoutId: 'main-1', level: LEVEL_MAIN },
          { flyoutId: 'main-2', level: LEVEL_MAIN },
          { flyoutId: 'child-2', level: LEVEL_CHILD }
        ]
      });
      expect(getCurrentSession(state)?.mainFlyoutId).toBe('main-2');
      expect(hasActiveSession(state)).toBe(true);
      expect(hasActiveSession(createTestState())).toBe(false);
      expect(isFlyoutActive(state, 'main-2')).toBe(true);
      expect(isFlyoutActive(state, 'child-2')).toBe(true);
      expect(isFlyoutActive(state, 'main-1')).toBe(false);
      expect(getCurrentMainFlyout(state)?.flyoutId).toBe('main-2');
      expect(getCurrentChildFlyout(state)?.flyoutId).toBe('child-2');
    });

    it('defaults push padding to zero', () => {
      expect(getPushPaddingOffsets(null)).toEqual({ left: 0, right: 0 });
      expect(hasPushPadding(createTestState())).toBe(false);
      expect(
        hasPushPadding(createTestState({ pushPadding: { left: 0, right: 320 } }))
      ).toBe(true);
    });
  });
});
