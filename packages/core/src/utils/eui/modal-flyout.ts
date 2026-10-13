/*
 * Ember glue for the modal and flyout family, following @elastic/eui 123.1.0
 * `components/modal/*` and `components/flyout/*`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 * Upstream factories are extracted into styles.generated.ts; this file only
 * holds what upstream does inside React components or hooks: the push
 * padding registry of `flyout.component.js`, `useEuiFlyoutZIndex`, and the
 * React-only inline style unit conversion.
 */
import { modifier } from 'ember-modifier';

import type { EuiBorealisContext } from './theme.ts';

type Side = 'left' | 'right';

interface Contribution {
  width: number;
  /** Managed flyouts also report the offset to the flyout manager. */
  managed: boolean;
}

interface SideState {
  base: string;
  contributions: Map<string, Contribution>;
}

/**
 * Upstream `euiPushPaddingRegistry`: every pushed flyout contributes its
 * width; the target (`document.body` or the flyout's `container`) gets the
 * widest contribution per side and its own inline padding back once the
 * last flyout on that side is gone.
 */
const registry = new WeakMap<HTMLElement, Record<Side, SideState>>();

function sideState(target: HTMLElement, side: Side): SideState {
  let state = registry.get(target);
  if (!state) {
    state = {
      left: { base: '', contributions: new Map() },
      right: { base: '', contributions: new Map() }
    };
    registry.set(target, state);
  }
  return state[side];
}

const styleKey = (side: Side) =>
  side === 'left' ? 'paddingInlineStart' : 'paddingInlineEnd';
const cssVar = (side: Side) =>
  side === 'left'
    ? '--euiPushFlyoutOffsetInlineStart'
    : '--euiPushFlyoutOffsetInlineEnd';

const maxContribution = (
  contributions: Map<string, Contribution>,
  filter: (contribution: Contribution) => boolean = () => true
) =>
  Math.max(
    0,
    ...Array.from(contributions.values(), (contribution) =>
      filter(contribution) ? contribution.width : 0
    )
  );

function apply(
  target: HTMLElement,
  side: Side,
  state: SideState,
  hasContainer: boolean,
  onManagedOffset?: (side: Side, width: number) => void
) {
  const pushing = state.contributions.size > 0;
  const total = maxContribution(state.contributions);
  target.style[styleKey(side)] = pushing ? `${total}px` : state.base;
  // Without a container the offset is also a global CSS variable.
  if (!hasContainer) {
    if (pushing)
      document.documentElement.style.setProperty(cssVar(side), `${total}px`);
    else document.documentElement.style.removeProperty(cssVar(side));
  }
  onManagedOffset?.(
    side,
    maxContribution(state.contributions, (c) => c.managed)
  );
}

/**
 * Pads `<body>` (or `container`) by the pushed flyout's width while it is
 * installed. Managed flyouts pass `onManagedOffset`, which receives the
 * widest managed contribution for the flyout manager.
 */
export const pushFlyoutPadding = modifier(
  (
    _element: Element,
    _positional: [],
    {
      id,
      side,
      width,
      isPushed,
      container,
      onManagedOffset
    }: {
      id: string;
      side: Side;
      width?: number;
      isPushed: boolean;
      container?: HTMLElement | null;
      onManagedOffset?: (side: Side, width: number) => void;
    }
  ) => {
    if (!isPushed || width === undefined) return;
    const target = container ?? document.body;
    const hasContainer = container != null;
    const state = sideState(target, side);
    if (state.contributions.size === 0)
      state.base = target.style[styleKey(side)];
    state.contributions.set(id, { width, managed: Boolean(onManagedOffset) });
    apply(target, side, state, hasContainer, onManagedOffset);
    return () => {
      state.contributions.delete(id);
      apply(target, side, state, hasContainer, onManagedOffset);
    };
  }
);

/** Calls `onWidth` with the element's border-box width (like `useResizeObserver`). */
export const observeWidth = modifier(
  (
    element: Element,
    [onWidth, enabled]: [(width: number) => void, boolean]
  ) => {
    if (!enabled || typeof ResizeObserver === 'undefined') return;
    const observer = new ResizeObserver(([entry]) => {
      const box = entry?.borderBoxSize?.[0];
      onWidth(box ? box.inlineSize : element.getBoundingClientRect().width);
    });
    observer.observe(element);
    return () => observer.disconnect();
  }
);

/**
 * Upstream `useEuiFlyoutZIndex`: `managedFlyoutIndex` is the flyout
 * manager's offset (the session's z-index for managed flyouts, the
 * manager's z-index when an unmanaged flyout opened); child flyouts sit one
 * level below their main flyout.
 */
export function flyoutZIndex(
  { euiTheme }: EuiBorealisContext,
  headerZindexLocation: 'above' | 'below',
  isPushed: boolean,
  managedFlyoutIndex = 0,
  isChildFlyout = false
) {
  const base =
    Number(
      !isPushed && headerZindexLocation === 'above'
        ? euiTheme.levels.mask
        : euiTheme.levels.flyout
    ) + managedFlyoutIndex;
  return { flyout: isChildFlyout ? base - 1 : base, mask: base - 2 };
}

/**
 * React writes unitless numbers in `style` as px (except unitless
 * properties such as `zIndex`); `ember-style-modifier` does not.
 */
export function reactInlineStyle(
  style: Record<string, unknown>
): Record<string, string | undefined> {
  const result: Record<string, string | undefined> = {};
  for (const [key, value] of Object.entries(style)) {
    if (value === undefined || value === null || value === false) continue;
    result[key] =
      typeof value === 'number' && key !== 'zIndex'
        ? `${value}px`
        : String(value as string);
  }
  return result;
}

/**
 * Upstream renders an SR-only description and joins its id with the
 * caller's `aria-describedby`; Ember cannot read `...attributes`, so this
 * merges on install. With `titleSelector`, a dialog without `aria-label` /
 * `aria-labelledby` is labelled by the first matching title (Ember
 * addition; upstream leaves this to the caller).
 */
export const dialogDescription = modifier<{
  Element: Element;
  Args: {
    Positional: [descriptionId: string];
    Named: { titleSelector?: string; enabled?: boolean };
  };
}>((element, [descriptionId], { titleSelector, enabled = true }) => {
  const caller = (element.getAttribute('aria-describedby') ?? '')
    .split(/\s+/)
    .filter((id) => id && id !== descriptionId);
  if (enabled)
    element.setAttribute(
      'aria-describedby',
      [descriptionId, ...caller].join(' ')
    );
  else if (caller.length)
    element.setAttribute('aria-describedby', caller.join(' '));
  else element.removeAttribute('aria-describedby');

  if (
    titleSelector &&
    !element.hasAttribute('aria-label') &&
    !element.hasAttribute('aria-labelledby')
  ) {
    const title = element.querySelector(titleSelector);
    if (title) {
      if (!title.id) title.id = `${descriptionId}-title`;
      element.setAttribute('aria-labelledby', title.id);
      return () => {
        if (element.getAttribute('aria-labelledby') === title.id)
          element.removeAttribute('aria-labelledby');
      };
    }
  }
  return undefined;
});
