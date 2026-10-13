import { getContext } from 'ember-provide-consume-context';
import { modifier } from 'ember-modifier';

import cssStyle from './css-style.ts';

import type { CSSInterpolation, CSSObject } from '@emotion/css/create-instance';
import type { EuiBreakpointSize } from '../utils/breakpoint.ts';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';
import type { EuiTableNode } from './table-node.gts';

export type TableAlignment = 'left' | 'right' | 'center';

/**
 * Where a table collapses into cards (upstream `responsiveBreakpoint`): a
 * named theme breakpoint (below it the table is cards), `true` (always
 * cards) or `false` (never).
 */
export type TableResponsiveBreakpoint = EuiBreakpointSize | boolean;

/** Upstream `DEFAULT_TABLE_BREAKPOINT`. */
export const DEFAULT_TABLE_BREAKPOINT: EuiBreakpointSize = 'm';

/**
 * Truncation of a cell's text: `true` on one line, `{ lines }` clamped to
 * that many lines (upstream `truncateText`).
 */
export type TableTruncateText = boolean | { lines: number };

/** Options of a cell on small screens (the table becomes cards). */
export interface TableMobileOptions {
  /** Shows the cell on small screens. Defaults to `true`. */
  show?: boolean;
  /** Shows the cell only on small screens. */
  only?: boolean;
  /**
   * Label of the cell on small screens (a row cell): text, an `htmlSafe`
   * string or a component; `false` shows none.
   */
  header?: EuiTableNode | boolean;
  /** Bigger text on small screens (a row cell). */
  enlarge?: boolean;
  /** Alignment on small screens (a row cell). Defaults to `'left'`. */
  align?: TableAlignment;
  /** Truncates the text on small screens (a row cell): `true` or `{ lines }`. */
  truncateText?: TableTruncateText;
  /** Wraps the content in a text span on small screens (a row cell). */
  textOnly?: boolean;
  /** Width of the cell in the card, e.g. `'100%'` (a row cell). */
  width?: number | string;
  /** Min width of the cell in the card (a row cell). */
  minWidth?: number | string;
  /** Max width of the cell in the card (a row cell). */
  maxWidth?: number | string;
}

/**
 * What an EuiTable shares with its rows and cells (upstream
 * `EuiTableIsResponsiveContext` + `EuiTableVariantContext`).
 */
export interface EuiTableContext {
  /** The table currently renders as cards. */
  readonly isResponsive: boolean;
  /** The table has its plain background (`@hasBackground`). */
  readonly hasBackground: boolean;
  /**
   * The row of the sticky header (`@stickyHeader`, desktop layout only)
   * where header cells render their copies (upstream's column store).
   */
  readonly stickyHeaderRow?: HTMLTableRowElement;
  /** Keeps the sticky header copies in the order of the header cells. */
  registerStickyHeaderCell?(cell: StickyHeaderCellSync): () => void;
}

export const EUI_TABLE_CONTEXT = '@ember-eui/core/table' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_TABLE_CONTEXT]: EuiTableContext;
  }
}

/**
 * A header cell and its copy in the sticky header. Upstream registers the
 * column in the table's store and syncs the copy's width from a
 * `ResizeObserver` on the original cell.
 */
export class StickyHeaderCellSync {
  original?: HTMLElement;
  copy?: HTMLElement;
  /** Last content-box width of the original cell. */
  width?: number;

  applyWidth(): void {
    if (this.copy && this.width !== undefined)
      this.copy.style.width = `${this.width}px`;
  }
}

/**
 * On an original header cell: records the element and, while the sticky
 * header is shown, observes its width for the copy (upstream
 * `store.updateColumnWidth`).
 */
export const stickyHeaderOriginal = modifier(
  (
    element: HTMLElement,
    [sync, active]: [StickyHeaderCellSync, boolean]
  ) => {
    sync.original = element;
    if (!active || typeof ResizeObserver === 'undefined') return;
    const observer = new ResizeObserver((entries) => {
      const entry = entries[0];
      if (!entry) return;
      sync.width = entry.contentRect.width;
      sync.applyWidth();
    });
    observer.observe(element);
    return () => observer.disconnect();
  }
);

/**
 * On a header cell's copy in the sticky header: applies the original's
 * width and keeps the copies ordered like the originals. `style` is only
 * passed so a new inline style re-applies the synced width.
 */
export const stickyHeaderCopy = modifier(
  (
    element: HTMLElement,
    [sync, table]: [StickyHeaderCellSync, EuiTableContext, unknown?]
  ) => {
    sync.copy = element;
    if (sync.width === undefined && sync.original) {
      // upstream's initial width (`getBoundingClientRect`, called once)
      sync.width = sync.original.getBoundingClientRect().width;
    }
    sync.applyWidth();
    const unregister = table.registerStickyHeaderCell?.(sync);
    return () => {
      unregister?.();
      if (sync.copy === element) sync.copy = undefined;
    };
  }
);

/** Upstream context defaults outside a table. */
const DEFAULT_CONTEXT: EuiTableContext = {
  isResponsive: false,
  hasBackground: true
};

/** Read in a getter so changes of the parent table stay tracked. */
export function tableContext(component: object): EuiTableContext {
  return getContext(component, EUI_TABLE_CONTEXT) ?? DEFAULT_CONTEXT;
}

/**
 * Media query matching widths at or above the named theme breakpoint
 * (upstream `useIsWithinMinBreakpoint`), or `undefined` when the
 * breakpoint is a boolean or unknown to the theme.
 */
export function minBreakpointQuery(
  theme: EuiBorealisContext,
  breakpoint: TableResponsiveBreakpoint
): string | undefined {
  if (typeof breakpoint === 'boolean') return undefined;
  const value = (theme.euiTheme.breakpoint as Record<string, number>)[
    breakpoint
  ];
  return typeof value === 'number' ? `(min-width: ${value}px)` : undefined;
}

/**
 * Upstream `useIsEuiTableResponsive`: booleans are taken as is; otherwise
 * the table is responsive below the breakpoint. Unknown breakpoints are
 * responsive, as upstream. Without a window (FastBoot) it is not.
 */
export function isTableResponsive(
  breakpoint: TableResponsiveBreakpoint,
  query: string | undefined
): boolean {
  if (typeof breakpoint === 'boolean') return breakpoint;
  if (!query) return true;
  if (typeof window === 'undefined' || !window.matchMedia) return false;
  return !window.matchMedia(query).matches;
}

/**
 * Calls `callback` when `query` starts or stops matching. A media query
 * listener only fires when the breakpoint is crossed (cheaper than the
 * resize listener upstream's provider uses).
 */
export const onMediaQueryChange = modifier(
  (_element: Element, [query, callback]: [string | undefined, () => void]) => {
    if (!query || typeof window === 'undefined' || !window.matchMedia) return;
    const list = window.matchMedia(query);
    list.addEventListener('change', callback);
    return () => list.removeEventListener('change', callback);
  }
);

/** A cell's width styles: numbers (or unitless strings) are px. */
export function widthStyle(
  width?: number | string,
  minWidth?: number | string,
  maxWidth?: number | string
) {
  return cssStyle({
    width: px(width),
    minWidth: px(minWidth),
    maxWidth: px(maxWidth)
  });
}

function px(value?: number | string): string | undefined {
  if (value === undefined || value === null || value === '') return undefined;
  return typeof value === 'number' || !isNaN(Number(value))
    ? `${value}px`
    : value;
}

/**
 * Scoped stand-in for React's global table reset (`margin`, `padding`,
 * `border`, `vertical-align`) on cells, composed before upstream's styles.
 */
export const CELL_RESET: CSSObject = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  border: 'none',
  verticalAlign: 'baseline'
};

/** Scoped stand-in for React's global table reset on the `<table>`. */
export const TABLE_RESET: CSSObject = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  borderSpacing: 0
};

/** Box sizing for the elements inside cells. */
export const BOX_SIZING: CSSObject = { boxSizing: 'border-box' };

/** Scoped stand-in for React's global `button` reset. */
export function buttonReset({ euiTheme }: EuiBorealisContext): CSSObject {
  return {
    boxSizing: 'border-box',
    background: 'none',
    border: 'none',
    padding: 0,
    margin: 0,
    color: 'inherit',
    borderRadius: 0,
    fontSize: 'inherit',
    fontFamily: euiTheme.font.family,
    textAlign: 'inherit',
    cursor: 'pointer'
  };
}

type Slot = CSSInterpolation;
type CellContentStyles = {
  euiTableCellContent: Slot;
  left: Slot;
  right: Slot;
  center: Slot;
  truncateText: Slot;
  wrapText: Slot;
  hasActions: {
    actions: Slot;
    custom: Slot;
    desktop: Slot;
    mobile: Slot;
  };
};

/**
 * Upstream `EuiTableCellContent` styles: alignment, truncation (`true`) or
 * word breaking (`false`; `null` for neither), and action layouts.
 */
export function cellContentStyles(
  styles: CellContentStyles,
  {
    align = 'left',
    truncateText = false,
    hasActions,
    isResponsive
  }: {
    align?: TableAlignment;
    truncateText?: boolean | null;
    hasActions?: boolean | 'custom';
    isResponsive: boolean;
  }
): CSSInterpolation[] {
  return [
    styles.euiTableCellContent,
    styles[align] ?? undefined,
    truncateText === true ? styles.truncateText : undefined,
    truncateText === false ? styles.wrapText : undefined,
    ...(hasActions
      ? [
          styles.hasActions.actions,
          hasActions === 'custom' ? styles.hasActions.custom : undefined,
          isResponsive ? undefined : styles.hasActions.desktop,
          isResponsive && hasActions !== 'custom'
            ? styles.hasActions.mobile
            : undefined
        ]
      : [])
  ];
}
