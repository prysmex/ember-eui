import { getContext } from 'ember-provide-consume-context';
import { modifier } from 'ember-modifier';

import cssStyle from './css-style.ts';

import type { CSSInterpolation, CSSObject } from '@emotion/css/create-instance';
import type { EuiBreakpointSize } from '../utils/breakpoint.ts';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';

export type TableAlignment = 'left' | 'right' | 'center';

/**
 * Where a table collapses into cards (upstream `responsiveBreakpoint`): a
 * named theme breakpoint (below it the table is cards), `true` (always
 * cards) or `false` (never).
 */
export type TableResponsiveBreakpoint = EuiBreakpointSize | boolean;

/** Upstream `DEFAULT_TABLE_BREAKPOINT`. */
export const DEFAULT_TABLE_BREAKPOINT: EuiBreakpointSize = 'm';

/** Options of a cell on small screens (the table becomes cards). */
export interface TableMobileOptions {
  /** Shows the cell on small screens. Defaults to `true`. */
  show?: boolean;
  /** Shows the cell only on small screens. */
  only?: boolean;
  /** Label of the cell on small screens (a row cell). */
  header?: string;
  /** Bigger text on small screens (a row cell). */
  enlarge?: boolean;
  /** Alignment on small screens (a row cell). Defaults to `'left'`. */
  align?: TableAlignment;
  /** Truncates the text on small screens (a row cell). */
  truncateText?: boolean;
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
}

export const EUI_TABLE_CONTEXT = '@ember-eui/core/table' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_TABLE_CONTEXT]: EuiTableContext;
  }
}

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
