/**
 * Fit a column to its content (v0.4 01): the width a field needs to show
 * its header and its widest loaded cell without cutting them. The width
 * itself is pure (`fieldWidth`, with a `measure` passed in); measuring
 * text and finding a resizer's column are the DOM parts.
 */
import { resolveType, valueOf } from '../core/index.ts';

import type { EuiSheetField, SheetContext } from '../core/index.ts';

/** A fitted width is clamped to this range, in px. */
export const FIT_MIN_WIDTH = 80;
export const FIT_MAX_WIDTH = 480;
/** At most this many loaded records are measured. */
export const FIT_RECORDS = 2000;

/** A text's width in px, in one font. */
export type Measure = (text: string) => number;

/** The widths around a header's label and a cell's content, in px. */
export interface FitChrome {
  /** The header's padding, sort arrow and menu button. */
  header: number;
  /** A cell's horizontal padding. */
  cell: number;
  /** The opener button's room (select, date): 0 for a field without one. */
  opener: number;
}

/**
 * The width that shows `field`'s header label and the content of every
 * cell of the first `FIT_RECORDS` records of `ctx.records`, clamped to
 * `FIT_MIN_WIDTH`..`FIT_MAX_WIDTH`. A cell is its type's
 * `contentWidth(value, field, measure.cell, context)`, else its
 * `format(value)` measured as text.
 */
export function fieldWidth<T>(
  ctx: SheetContext<T>,
  field: EuiSheetField<T>,
  measure: { cell: Measure; header: Measure },
  chrome: FitChrome
): number {
  const type = resolveType(ctx.types, field);
  const header = measure.header(field.label ?? field.id) + chrome.header;
  let content = 0;
  const count = Math.min(ctx.records.length, FIT_RECORDS);
  for (let i = 0; i < count; i++) {
    const record = ctx.records[i]!;
    const value = valueOf(record, field.id);
    const context = { record, messages: ctx.messages };
    const width = type.contentWidth
      ? type.contentWidth(value, field, measure.cell, context)
      : measure.cell(type.format(value, field, context));
    if (width > content) content = width;
  }
  const cells = content + chrome.cell + chrome.opener;
  const width = Math.ceil(Math.max(header, cells));
  return Math.min(FIT_MAX_WIDTH, Math.max(FIT_MIN_WIDTH, width));
}

let canvas: HTMLCanvasElement | null = null;
/** The font last set on the canvas (its `font` reads back normalized). */
let canvasFont = '';

/** `measureText` in `font` (a CSS `font` value), on one canvas reused by every sheet. */
export function textMeasure(font: string): Measure {
  canvas ??= document.createElement('canvas');
  const context = canvas.getContext('2d');
  if (!context) return (text) => text.length * 8;
  return (text) => {
    // two measures (header, cell) share the canvas
    if (canvasFont !== font) {
      context.font = font;
      canvasFont = font;
    }
    return context.measureText(text).width;
  };
}

/** The column id of the header whose resize edge `target` is, or null. */
export function resizerColumnId(target: EventTarget | null): string | null {
  if (!(target instanceof Element)) return null;
  const resizer = target.closest('[data-test-subj=dataGridColumnResizer]');
  if (!resizer) return null;
  // inside the header cell, or (column drag on) its sibling
  const header =
    resizer.closest<HTMLElement>('[role=columnheader]') ??
    resizer.parentElement?.querySelector<HTMLElement>(
      ':scope > [role=columnheader]'
    );
  return header?.dataset['gridcellColumnId'] ?? null;
}
