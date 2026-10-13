/*
 * Ported from @elastic/eui 123.1.0 `components/flyout/manager/const.ts` and
 * the menu constants of `components/flyout/const.ts`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 */

/**
 * Allowed values for `session` prop to control the way the session is managed for a flyout.
 */
export const SESSION_START = 'start';
export const SESSION_INHERIT = 'inherit';
export const SESSION_NEVER = 'never';

const PREFIX = 'data-managed-flyout';

/** Data attribute applied to a managed flyout element. */
export const PROPERTY_FLYOUT = `${PREFIX}`;
/** Data attribute indicating whether the flyout is the `main` or `child` flyout. */
export const PROPERTY_LEVEL = `${PREFIX}-level`;
/** Data attribute representing how multiple flyouts are laid out. */
export const PROPERTY_LAYOUT_MODE = `${PREFIX}-layout-mode`;

/** Stacked layout mode where child flyouts overlay on top of the main flyout. */
export const LAYOUT_MODE_STACKED = 'stacked';
/** Side-by-side layout mode where child flyouts render adjacent to the main flyout. */
export const LAYOUT_MODE_SIDE_BY_SIDE = 'side-by-side';

/** The primary (parent) flyout in a session. */
export const LEVEL_MAIN = 'main';
/** The secondary (child) flyout spawned by the main flyout. */
export const LEVEL_CHILD = 'child';

/** Flyout is mounting and playing its opening animation. */
export const STAGE_OPENING = 'opening';
/** Flyout is fully visible and interactive. */
export const STAGE_ACTIVE = 'active';
/** Flyout is unmounted or not currently visible/interactable. */
export const STAGE_INACTIVE = 'inactive';
/** Main flyout is transitioning behind an active session flyout. */
export const STAGE_BACKGROUNDING = 'backgrounding';
/** Main flyout is backgrounded behind an active session flyout. */
export const STAGE_BACKGROUNDED = 'backgrounded';
/** Flyout is returning to the foreground from a backgrounded state. */
export const STAGE_RETURNING = 'returning';
/** Flyout is playing its closing animation. */
export const STAGE_CLOSING = 'closing';

/** Menu display mode: always render menu when flyoutMenuProps is provided. */
export const MENU_DISPLAY_ALWAYS = 'always' as const;
/** Menu display mode: only render menu when it has content. */
export const MENU_DISPLAY_AUTO = 'auto' as const;
/** Allowed flyout menu display modes. */
export const FLYOUT_MENU_DISPLAY_MODES = [
  MENU_DISPLAY_ALWAYS,
  MENU_DISPLAY_AUTO
] as const;
/** Type representing a supported flyout menu display mode. */
export type EuiFlyoutMenuDisplayMode =
  (typeof FLYOUT_MENU_DISPLAY_MODES)[number];
/** Default flyout menu display mode. */
export const DEFAULT_MENU_DISPLAY_MODE: EuiFlyoutMenuDisplayMode =
  MENU_DISPLAY_AUTO;

/**
 * Minimum number of history items required to render the flyout menu's history popover.
 */
export const MIN_HISTORY_ITEMS = 2;
