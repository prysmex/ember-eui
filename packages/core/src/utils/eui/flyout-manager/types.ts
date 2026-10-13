/*
 * Ported from @elastic/eui 123.1.0 `components/flyout/manager/types.ts` and
 * `components/flyout/types.ts`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 */
import type {
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
} from './const.ts';
import type { EuiFlyoutMenuPagination } from '../../../components/eui-flyout-menu.gts';
import type { EuiIconSignature } from '../../../components/eui-icon.gts';

export type IconType = EuiIconSignature['Args']['type'];

export type EuiFlyoutLayoutMode =
  | typeof LAYOUT_MODE_STACKED
  | typeof LAYOUT_MODE_SIDE_BY_SIDE;

export type EuiFlyoutLevel = typeof LEVEL_MAIN | typeof LEVEL_CHILD;

export type EuiFlyoutActivityStage =
  | typeof STAGE_OPENING
  | typeof STAGE_ACTIVE
  | typeof STAGE_INACTIVE
  | typeof STAGE_BACKGROUNDING
  | typeof STAGE_BACKGROUNDED
  | typeof STAGE_RETURNING
  | typeof STAGE_CLOSING;

export interface EuiManagedFlyoutState {
  flyoutId: string;
  level: EuiFlyoutLevel;
  width?: number;
  size?: string;
  minWidth?: number;
  activityStage?: EuiFlyoutActivityStage;
  pagination?: EuiFlyoutMenuPagination;
}

/** Entry for a child flyout in session history. */
export interface ChildHistoryEntry {
  flyoutId: string;
  title: string;
  iconType?: IconType;
}

export interface FlyoutSession {
  /** ID of the main flyout for this session */
  mainFlyoutId: string;
  /** ID of the child flyout for this session */
  childFlyoutId: string | null;
  /** Title of the main flyout in this session */
  title: string;
  /** Optional icon for this session when shown in history popover */
  iconType?: IconType;
  /** z-index value to be used by the flyout session */
  zIndex: number;
  /** Title of the current child flyout. */
  childTitle?: string;
  /** Icon of the current child flyout. */
  childIconType?: IconType;
  /** Stack of child flyouts we navigated away from. */
  childHistory: ChildHistoryEntry[];
  /** Key that scopes this session's history; same Symbol reference = same history group. */
  historyKey: symbol;
}

export interface PushPaddingOffsets {
  /** Push padding applied to the left side (in pixels) */
  left: number;
  /** Push padding applied to the right side (in pixels) */
  right: number;
}

export interface EuiFlyoutManagerState {
  sessions: FlyoutSession[];
  flyouts: EuiManagedFlyoutState[];
  layoutMode: EuiFlyoutLayoutMode;
  /** Active push padding offsets (updated by active push flyouts) */
  pushPadding?: PushPaddingOffsets;
  currentZIndex: number;
  unmanagedFlyouts: string[];
  /** The container element that flyouts are positioned relative to (if any). */
  containerElement?: HTMLElement | null;
  /** Reference width used for layout and resize clamping (container or viewport). */
  referenceWidth?: number;
}

/** An entry of the history popover, most recent first. */
export interface EuiFlyoutManagerHistoryItem {
  title: string;
  iconType?: IconType;
  onClick: () => void;
}

/**
 * Describes the source that triggered a flyout close, passed to `@onClose`
 * as the second argument (`meta.reason`).
 *
 * - `close-button`: the default/X close button (base flyout and managed menu)
 * - `escape`: the Escape key
 * - `outside-click`: a click on the overlay mask or outside the flyout
 * - `navigation-back`: a managed flyout closed because the user pressed Back
 * - `navigation-cascade`: a managed flyout closed because a parent navigated
 *   away or the main flyout closed
 */
export type EuiFlyoutCloseReason =
  | 'close-button'
  | 'escape'
  | 'outside-click'
  | 'navigation-back'
  | 'navigation-cascade';

/** The second argument of a flyout's `@onClose`. */
export interface EuiFlyoutCloseMeta {
  reason: EuiFlyoutCloseReason;
}
