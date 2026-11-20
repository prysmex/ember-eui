/**
 * Types the sheet's modules share (V03C-DESIGN.md 3.2): moved from
 * `components/eui-sheet.gts` as they were.
 */
import type {
  CellErrors,
  ChangeSet,
  EuiSheetField,
  PendingCell,
  Pos,
  RecordId,
  SheetAttachment
} from '../../core/index.ts';
import type { Rejection } from '../rejections.ts';
import type { EuiSheetFieldType, SheetEditorRect } from '../../types.ts';

/** One cell as the renderer shows it (PACKAGE-DESIGN.md 7.3). */
export interface CellView {
  record: unknown;
  field: EuiSheetField;
  type: EuiSheetFieldType;
  value: unknown;
  /** The rejected text, else type.format(value). */
  text: string;
  rejected: boolean;
  errors: string[];
  selected: boolean;
  readOnly: boolean;
  /** Waiting for `@onResolve` or an upload: no errors shown until it settles. */
  pending: boolean;
  /** `type.link(value)` when its scheme is one the sheet opens. */
  link: string | undefined;
  /** Files dragged over the cell will be dropped on it. */
  dropTarget: boolean;
}

/**
 * A cell waiting for `@onResolve` (text: what was typed or pasted, shown
 * meanwhile) or for an upload (text: null, the value stays shown).
 */
export interface PendingEntry {
  text: string | null;
  /** The call it waits for. */
  token: object;
  /** The cell to resolve; none for an upload. */
  cell?: PendingCell;
}

/** One `@onResolve` call or upload in flight. */
export interface PendingCall {
  kind: 'resolve' | 'upload';
  controller: AbortController;
  waiter: unknown;
  /** The history entry of the paste or edit that asked for it: the resolve is merged into it. */
  entry: HistoryEntry | null;
}

/**
 * One undo entry: the change set a user action emitted, and the rejections
 * it stored (with the value each cell had then), which undo clears and
 * redo puts back.
 */
export interface HistoryEntry {
  changeSet: ChangeSet;
  rejections: Rejection[];
}

/** A box relative to the sheet's wrapper, in the wrapper's CSS px. */
export interface WrapperBox {
  top: number;
  left: number;
  width: number;
  height: number;
}

/** A cell to focus once its record is rendered (V02-DESIGN.md 3.3). */
export interface PendingFocus {
  /** The record's id, as a string. */
  id: string;
  fieldId: string;
}

/** What this sheet emitted that the owner has not applied yet, as far as `@records` shows. */
export interface PendingOwn {
  deletes: Set<string>;
  inserts: number;
}

export interface Validation {
  errors: CellErrors;
  /** The record objects the run started with, by id. */
  records: Map<string, unknown>;
}

export type Touched = Array<{ id: RecordId; fieldId: string }>;

/** A focused data cell and its box, relative to the wrapper. */
export interface FocusedCell {
  pos: Pos;
  rect: SheetEditorRect;
  wrapperWidth: number;
  /** Viewport px between the cell's bottom and the window's bottom. */
  viewportBelow: number;
}

/** Where the frozen columns are: each one's `left`, by grid column index, and their right edge. */
export interface FrozenLayout {
  lefts: Map<number, number>;
  /** The grid column index of the last frozen column. */
  last: number;
  /** The frozen columns' right edge, from the grid's left edge, in CSS px. */
  right: number;
}

/** What a range covers (V02-DESIGN.md 5.4). */
export type RangeKind = 'cells' | 'rows' | 'columns';

/** The open row menu: the row it was opened on and where, in the wrapper. */
export interface MenuState {
  row: number;
  /** The data column it was opened on; null on a row number. */
  col: number | null;
  /** Its anchor, relative to the wrapper: the pointer (no size) or the cell. */
  anchor: WrapperBox;
  /** The records it acts on, fixed when it opened. */
  records: unknown[];
}

/** Where the expanded record was opened from, to focus it again on close. */
export interface ExpandedFrom {
  recordId: RecordId;
  /** null: the row-number cell. */
  fieldId: string | null;
}

export type UploadField = EuiSheetField & {
  upload?: (
    files: File[],
    context: { record: unknown; field: EuiSheetField; signal: AbortSignal }
  ) => Promise<SheetAttachment[]>;
  maxFiles?: number;
};
