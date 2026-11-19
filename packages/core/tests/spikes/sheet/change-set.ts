/**
 * EuiSheet spike (internal/spikes/sheet/DESIGN.md, section 5.2): pure types,
 * TSV parse/serialize and change-set builders. No Ember, no DOM.
 */

export type RecordId = string | number;

export interface EuiSheetField {
  id: string;
  label?: string;
  readOnly?: boolean;
  /** Spike knob, default false (R4). */
  isExpandable?: boolean;
  /** Default: `value == null ? '' : String(value)`. */
  format?: (value: unknown) => string;
  /** Default: the text itself. */
  parse?: (text: string) => unknown;
}

export interface CellPatch {
  recordId: RecordId;
  fieldId: string;
  from: unknown;
  to: unknown;
}

export interface RecordInsert {
  tempId: string;
  index: number;
  values: Record<string, unknown>;
}

export interface ChangeSet {
  source: 'edit' | 'paste' | 'clear';
  patches: CellPatch[];
  inserts: RecordInsert[];
}

export interface Pos {
  row: number;
  col: number;
}

/** Inclusive on all sides. */
export interface Range {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

export interface SheetContext<T> {
  records: readonly T[];
  /** Visible fields, display order. */
  fields: readonly EuiSheetField[];
  getRecordId: (record: T) => RecordId;
}

export function formatValue(field: EuiSheetField, value: unknown): string {
  if (field.format) return field.format(value);
  return value == null ? '' : String(value as string);
}

export function parseText(field: EuiSheetField, text: string): unknown {
  return field.parse ? field.parse(text) : text;
}

function valueOf(record: unknown, fieldId: string): unknown {
  return (record as Record<string, unknown>)[fieldId];
}

export function toRange(anchor: Pos, head: Pos): Range {
  return {
    top: Math.min(anchor.row, head.row),
    left: Math.min(anchor.col, head.col),
    bottom: Math.max(anchor.row, head.row),
    right: Math.max(anchor.col, head.col)
  };
}

/** Splits on `\r?\n` (one trailing empty line dropped), then on `\t`. No quoted cells. */
export function parseTsv(text: string): string[][] {
  const lines = text.split(/\r?\n/);
  if (lines.length > 1 && lines[lines.length - 1] === '') lines.pop();
  return lines.map((line) => line.split('\t'));
}

export function toTsv(matrix: readonly (readonly string[])[]): string {
  return matrix.map((row) => row.join('\t')).join('\n');
}

/** Formatted values of the range, clamped to existing rows and fields. */
export function rangeMatrix<T>(ctx: SheetContext<T>, range: Range): string[][] {
  const bottom = Math.min(range.bottom, ctx.records.length - 1);
  const right = Math.min(range.right, ctx.fields.length - 1);
  const matrix: string[][] = [];
  for (let row = Math.max(range.top, 0); row <= bottom; row++) {
    const record = ctx.records[row];
    const line: string[] = [];
    for (let col = Math.max(range.left, 0); col <= right; col++) {
      const field = ctx.fields[col]!;
      line.push(formatValue(field, valueOf(record, field.id)));
    }
    matrix.push(line);
  }
  return matrix;
}

/** One patch; `null` when the field is read-only or the parsed value equals the current one. */
export function commitPatch<T>(
  ctx: SheetContext<T>,
  pos: Pos,
  text: string
): ChangeSet | null {
  const record = ctx.records[pos.row];
  const field = ctx.fields[pos.col];
  if (record === undefined || !field || field.readOnly) return null;
  const from = valueOf(record, field.id);
  const to = parseText(field, text);
  if (Object.is(from, to)) return null;
  return {
    source: 'edit',
    patches: [
      { recordId: ctx.getRecordId(record), fieldId: field.id, from, to }
    ],
    inserts: []
  };
}

/** A patch `to: parse('')` per non-read-only cell whose value differs; `null` when empty. */
export function clearRange<T>(
  ctx: SheetContext<T>,
  range: Range
): ChangeSet | null {
  const patches: CellPatch[] = [];
  const bottom = Math.min(range.bottom, ctx.records.length - 1);
  const right = Math.min(range.right, ctx.fields.length - 1);
  for (let row = Math.max(range.top, 0); row <= bottom; row++) {
    const record = ctx.records[row]!;
    for (let col = Math.max(range.left, 0); col <= right; col++) {
      const field = ctx.fields[col]!;
      if (field.readOnly) continue;
      const from = valueOf(record, field.id);
      const to = parseText(field, '');
      if (Object.is(from, to)) continue;
      patches.push({
        recordId: ctx.getRecordId(record),
        fieldId: field.id,
        from,
        to
      });
    }
  }
  return patches.length ? { source: 'clear', patches, inserts: [] } : null;
}

/**
 * Cell `[i][j]` goes to `anchor + (i, j)`. Columns past the last field are
 * dropped, read-only fields skipped. Existing rows give patches (unchanged
 * values omitted); rows past the end give one insert each.
 */
export function pasteMatrix<T>(
  ctx: SheetContext<T>,
  anchor: Pos,
  matrix: readonly (readonly string[])[]
): ChangeSet | null {
  const patches: CellPatch[] = [];
  const inserts: RecordInsert[] = [];
  matrix.forEach((line, i) => {
    const row = anchor.row + i;
    const record = ctx.records[row];
    const values: Record<string, unknown> = {};
    let hasValues = false;
    line.forEach((text, j) => {
      const field = ctx.fields[anchor.col + j];
      if (!field || field.readOnly) return;
      const to = parseText(field, text);
      if (record !== undefined) {
        const from = valueOf(record, field.id);
        if (!Object.is(from, to)) {
          patches.push({
            recordId: ctx.getRecordId(record),
            fieldId: field.id,
            from,
            to
          });
        }
      } else {
        values[field.id] = to;
        hasValues = true;
      }
    });
    if (record === undefined && hasValues) {
      const k = inserts.length;
      inserts.push({
        tempId: `new-${k}`,
        index: ctx.records.length + k,
        values
      });
    }
  });
  if (!patches.length && !inserts.length) return null;
  return { source: 'paste', patches, inserts };
}
