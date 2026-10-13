/*
 * Ported from @elastic/eui 123.1.0 `components/flyout/manager/store.ts`
 * (`computeHistoryItems`).
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 */
import { goToFlyout as goToFlyoutAction } from './actions.ts';

import type { Action } from './actions.ts';
import type {
  EuiFlyoutManagerHistoryItem,
  EuiFlyoutManagerState
} from './types.ts';

/**
 * The history popover entries of the current session, most recent first:
 * its child history, then the previous sessions of the same history group
 * (each session's current child, its child history, or its main title).
 */
export const computeHistoryItems = (
  currentState: EuiFlyoutManagerState,
  dispatchFn: (action: Action) => void
): EuiFlyoutManagerHistoryItem[] => {
  const currentSessionIndex = currentState.sessions.length - 1;
  const currentSession =
    currentSessionIndex >= 0 ? currentState.sessions[currentSessionIndex] : null;

  if (!currentSession) {
    return [];
  }

  const previousSessions = currentState.sessions.slice(0, currentSessionIndex);
  // Only include sessions in the same history group (same historyKey reference)
  const previousSessionsInGroup = previousSessions.filter(
    (session) => session.historyKey === currentSession.historyKey
  );

  const childHistory = currentSession.childHistory ?? [];
  const childItems = [...childHistory].reverse().map((entry) => ({
    title: entry.title,
    iconType: entry.iconType,
    onClick: () => {
      dispatchFn(goToFlyoutAction(entry.flyoutId, 'child'));
    }
  }));

  // Previous sessions (same group): list each session's current child then its child history
  const previousSessionItems: EuiFlyoutManagerHistoryItem[] = [];
  for (let i = previousSessionsInGroup.length - 1; i >= 0; i--) {
    const session = previousSessionsInGroup[i]!;
    const mainTitle = session.title;
    const mainFlyoutId = session.mainFlyoutId;
    const history = session.childHistory ?? [];
    const hasChildren =
      (session.childFlyoutId != null && session.childTitle != null) ||
      history.length > 0;

    if (session.childFlyoutId && session.childTitle) {
      previousSessionItems.push({
        title: session.childTitle,
        iconType: session.childIconType,
        onClick: () => {
          dispatchFn(goToFlyoutAction(mainFlyoutId, 'main'));
        }
      });
    }
    for (let h = history.length - 1; h >= 0; h--) {
      const entry = history[h]!;
      previousSessionItems.push({
        title: entry.title,
        iconType: entry.iconType,
        onClick: () => {
          dispatchFn(goToFlyoutAction(mainFlyoutId, 'main'));
          dispatchFn(goToFlyoutAction(entry.flyoutId, 'child'));
        }
      });
    }
    if (!hasChildren) {
      previousSessionItems.push({
        title: mainTitle,
        iconType: session.iconType,
        onClick: () => {
          dispatchFn(goToFlyoutAction(mainFlyoutId, 'main'));
        }
      });
    }
  }

  return [...childItems, ...previousSessionItems];
};
