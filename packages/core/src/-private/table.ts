import cssStyle from './css-style.ts';

export type TableAlignment = 'left' | 'right' | 'center';

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
  /** Alignment on small screens (a row cell). */
  align?: TableAlignment;
  /** Truncates the text on small screens (a row cell). */
  truncateText?: boolean;
}

/** A cell's width: numbers (or unitless strings) are px. */
export function widthStyle(width?: number | string) {
  if (width === undefined || width === null || width === '') return undefined;

  const value = typeof width === 'number' || !isNaN(Number(width)) ? `${width}px` : width;

  return cssStyle({ width: value });
}

export function alignClasses(align?: TableAlignment): string | undefined {
  if (align === 'right') return 'euiTableCellContent--alignRight';
  if (align === 'center') return 'euiTableCellContent--alignCenter';

  return undefined;
}
